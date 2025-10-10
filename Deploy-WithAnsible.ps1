# PowerShell Wrapper for Ansible Deployment
# This script ONLY calls Ansible via WSL - all logic is in Ansible
# Usage: .\Deploy-WithAnsible.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Private Cloud Deployment via Ansible" -ForegroundColor Cyan
Write-Host "Infrastructure as Code Automation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check WSL
Write-Host "Checking WSL..." -ForegroundColor Yellow
try {
    $wslVersion = wsl --version
    Write-Host "✓ WSL is available" -ForegroundColor Green
} catch {
    Write-Host "✗ WSL not found. Please install WSL:" -ForegroundColor Red
    Write-Host "  wsl --install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Deploying infrastructure using Ansible..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run Ansible via WSL
$deployScript = "/mnt/c/Users/vomin/Documents/PrivateCloud/deploy.sh"
wsl bash $deployScript

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✓ Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Check deployment: oc get pods" -ForegroundColor White
    Write-Host "  2. View application URL: oc get route fastapi-route" -ForegroundColor White
    Write-Host "  3. Run stress test: oc apply -f kubernetes/k6-stress-test.yaml" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ Deployment Failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check logs above for errors" -ForegroundColor Yellow
    exit 1
}
