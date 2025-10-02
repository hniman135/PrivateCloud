# Simple stress test script using curl
$url = "https://fastapi-app-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/"
$totalRequests = 10

$startTime = Get-Date
$results = @()

for ($i = 0; $i -lt $totalRequests; $i++) {
    $start = Get-Date
    try {
        $process = Start-Process -FilePath "curl.exe" -ArgumentList "-k", "-s", "-w", "%{http_code}", $url -NoNewWindow -Wait -RedirectStandardOutput "temp.txt"
        $response = Get-Content "temp.txt" -Raw
        Remove-Item "temp.txt" -ErrorAction SilentlyContinue
        $end = Get-Date
        $latency = ($end - $start).TotalMilliseconds
        Write-Host "Raw response: '$response'"
        $statusStr = $response[-3..-1] -join ""
        Write-Host "Status string: '$statusStr'"
        $status = [int]$statusStr
        Write-Host "Parsed status: $status, type: $($status.GetType())"
        $results += @{
            Status = $status
            Latency = $latency
            Success = ($status -eq 200)
        }
        Write-Host "Request $i : Status $status, Latency $latency ms"
    } catch {
        $end = Get-Date
        $latency = ($end - $start).TotalMilliseconds
        $results += @{
            Status = 0
            Latency = $latency
            Success = $false
        }
        Write-Host "Request $i : Error, Latency $latency ms"
    }
}

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

$successful = $results | Where-Object { $_.Success }
$failed = $results | Where-Object { -not $_.Success }

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

Write-Host "Simple Stress Test Results:"
Write-Host "==========================="
Write-Host "Total Requests: $totalRequests"
Write-Host "Total Time: $([math]::Round($totalTime, 2)) seconds"
Write-Host "Requests Per Second (RPS): $([math]::Round($rps, 2))"
Write-Host "Error Rate: $([math]::Round($errorRate, 2))%"
Write-Host "Latency p50: $([math]::Round($p50, 2)) ms"
Write-Host "Latency p95: $([math]::Round($p95, 2)) ms"
Write-Host "Latency p99: $([math]::Round($p99, 2)) ms"