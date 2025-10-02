# Stress test script using curl with concurrent requests
$url = "https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/"
$concurrent = 20
$totalRequests = 1000

$jobs = @()
$startTime = Get-Date

for ($i = 0; $i -lt $concurrent; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url, $requests)
        $results = @()
        for ($j = 0; $j -lt $requests; $j++) {
            $start = Get-Date
            try {
                $tempFile = "temp_$($PID)_$j.txt"
                $process = Start-Process -FilePath "curl.exe" -ArgumentList "-k", "-s", "-w", "%{http_code}", $url -NoNewWindow -Wait -RedirectStandardOutput $tempFile
                $response = Get-Content $tempFile -Raw -ErrorAction SilentlyContinue
                Remove-Item $tempFile -ErrorAction SilentlyContinue
                $end = Get-Date
                $latency = ($end - $start).TotalMilliseconds
                $statusStr = $response[-3..-1] -join ""
                $status = [int]$statusStr
                $results += @{
                    Status = $status
                    Latency = $latency
                    Success = ($status -eq 200)
                }
            } catch {
                $end = Get-Date
                $latency = ($end - $start).TotalMilliseconds
                $results += @{
                    Status = 0
                    Latency = $latency
                    Success = $false
                }
            }
        }
        return $results
    } -ArgumentList $url, ($totalRequests / $concurrent)
}

$allResults = @()
foreach ($job in $jobs) {
    $allResults += Receive-Job -Job $job -Wait
}

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

$successful = $allResults | Where-Object { $_.Success }
$failed = $allResults | Where-Object { -not $_.Success }

$rps = $totalRequests / $totalTime
$errorRate = ($failed.Count / $totalRequests) * 100

if ($successful.Count -gt 0) {
    $latencies = $successful | ForEach-Object { $_.Latency } | Sort-Object
    $p50 = $latencies[[int]($latencies.Count * 0.5)]
    $p95 = $latencies[[int]($latencies.Count * 0.95)]
    $p99 = $latencies[[int]($latencies.Count * 0.99)]
} else {
    $p50 = $p95 = $p99 = 0
}

Write-Host "Concurrent Stress Test Results (2 pods):"
Write-Host "======================================"
Write-Host "Total Requests: $totalRequests"
Write-Host "Concurrent Connections: $concurrent"
Write-Host "Total Time: $([math]::Round($totalTime, 2)) seconds"
Write-Host "Requests Per Second (RPS): $([math]::Round($rps, 2))"
Write-Host "Error Rate: $([math]::Round($errorRate, 2))%"
Write-Host "Latency p50: $([math]::Round($p50, 2)) ms"
Write-Host "Latency p95: $([math]::Round($p95, 2)) ms"
Write-Host "Latency p99: $([math]::Round($p99, 2)) ms"
if ($p95 -gt 0) {
    Write-Host "RPS/Latency Ratio (p95): $([math]::Round($rps / $p95, 4))"
} else {
    Write-Host "RPS/Latency Ratio (p95): N/A"
}