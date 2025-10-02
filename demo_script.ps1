# Demo Script for Private Cloud FastAPI Project
# Run this script to execute the full demo automatically

Write-Host "=== Private Cloud FastAPI Demo Script ===" -ForegroundColor Green
Write-Host "Starting demo in 5 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Function to run command and show output
function Run-Command {
    param([string]$description, [string]$command)
    Write-Host "`n--- $description ---" -ForegroundColor Cyan
    Write-Host "Command: $command" -ForegroundColor Gray
    try {
        Invoke-Expression $command
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "Press Enter to continue..."
}

# Pre-demo checks
Run-Command "Check current pods" "oc get pods"
Run-Command "Check services and routes" "oc get svc,route"
Run-Command "Check HPA status" "oc get hpa"
Run-Command "Test main endpoint" "curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/"

# Scaling demo
Write-Host "`n=== SCALING DEMO ===" -ForegroundColor Magenta
Run-Command "Scale down to 1 pod" "oc scale deployment fastapi-app --replicas=1"
Run-Command "Check pods after scaling down" "oc get pods -l app=fastapi-app"
Run-Command "Test endpoint with 1 pod" "curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/"
Run-Command "Scale back to 2 pods" "oc scale deployment fastapi-app --replicas=2"
Run-Command "Check pods after scaling up" "oc get pods -l app=fastapi-app"

# Stress test
Write-Host "`n=== STRESS TEST DEMO ===" -ForegroundColor Magenta
Write-Host "Starting stress test... This will take about 2 minutes." -ForegroundColor Yellow
Run-Command "Run stress test" ".\scripts\final_stress_test.ps1"

# Health checks
Write-Host "`n=== HEALTH CHECKS DEMO ===" -ForegroundColor Magenta
Run-Command "Test liveness probe" "curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/live"
Run-Command "Test readiness probe" "curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/ready"
Run-Command "Test startup probe" "curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/startup"

# Logs
Run-Command "Check application logs" "oc logs -l app=fastapi-app --tail=10"

Write-Host "`n=== DEMO COMPLETED ===" -ForegroundColor Green
Write-Host "Thank you for watching the Private Cloud FastAPI demo!" -ForegroundColor Green
Read-Host "Press Enter to exit..."