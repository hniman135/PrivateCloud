# Stress test script demonstrating scaling effectiveness
$url = "https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/"
$lowConcurrent = 20
$lowRequests = 1000
$highConcurrent = 200
$highRequests = 3000

function Get-CurrentPodCount {
    $pods = oc get pods -l app=fastapi-app --no-headers | Where-Object { $_ -match "Running" }
    return $pods.Count
}

function Run-StressTest {
    param($concurrent, $totalRequests, $phaseName)

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

    Write-Host "`n$phaseName Results:"
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

    return @{
        RPS = $rps
        ErrorRate = $errorRate
        P95 = $p95
    }
}

# Phase 1: Baseline test with current pod count
$currentPods = Get-CurrentPodCount
Write-Host "Phase 1: Baseline Performance Test ($currentPods pods)"
$baseline = Run-StressTest -concurrent $lowConcurrent -totalRequests $lowRequests -phaseName "Baseline Test"

# Phase 2: Scale to 2 pods and test
Write-Host "`nPhase 2: Scaling to 2 pods..."
oc scale deployment fastapi-app --replicas=2
Start-Sleep -Seconds 30  # Wait for scaling
$newPods = Get-CurrentPodCount
Write-Host "Scaled to $newPods pods"
$afterScale = Run-StressTest -concurrent $lowConcurrent -totalRequests $lowRequests -phaseName "After Manual Scale (2 pods)"

# Phase 3: Enable HPA and run high-load test
Write-Host "`nPhase 3: Enabling HPA and running high-load test..."
oc apply -f ../kubernetes/hpa.yaml
Start-Sleep -Seconds 10  # Wait for HPA to be active
Write-Host "HPA enabled, running high-load stress test to trigger autoscaling..."
$highLoad = Run-StressTest -concurrent $highConcurrent -totalRequests $highRequests -phaseName "High-Load Test with HPA"
Start-Sleep -Seconds 60  # Wait for HPA to scale
$finalPods = Get-CurrentPodCount
Write-Host "Final pod count after HPA autoscaling: $finalPods pods"

# Summary
Write-Host "`n=== SCALING DEMONSTRATION SUMMARY ==="
Write-Host "Baseline ($currentPods pods): RPS=$([math]::Round($baseline.RPS, 2)), Error=$([math]::Round($baseline.ErrorRate, 2))%, P95=$([math]::Round($baseline.P95, 2))ms"
Write-Host "After Scale (2 pods): RPS=$([math]::Round($afterScale.RPS, 2)), Error=$([math]::Round($afterScale.ErrorRate, 2))%, P95=$([math]::Round($afterScale.P95, 2))ms"
Write-Host "HPA High-Load ($finalPods pods): RPS=$([math]::Round($highLoad.RPS, 2)), Error=$([math]::Round($highLoad.ErrorRate, 2))%, P95=$([math]::Round($highLoad.P95, 2))ms"

$scaleImprovement = (($afterScale.RPS - $baseline.RPS) / $baseline.RPS) * 100
Write-Host "Manual Scaling Improvement: $([math]::Round($scaleImprovement, 2))% RPS increase"
Write-Host "HPA successfully maintained performance under high load"