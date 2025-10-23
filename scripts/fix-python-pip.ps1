# Python pip Fix Script
# Repairs corrupted pip installation without full Python reinstall
# Run this script in PowerShell as Administrator

Write-Host "=== Python pip Repair Script ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check current Python version
Write-Host "Step 1: Checking Python installation..." -ForegroundColor Yellow
python --version
$pythonPath = (Get-Command python).Source
Write-Host "Python location: $pythonPath" -ForegroundColor Green
Write-Host ""

# Step 2: Backup current pip installation
Write-Host "Step 2: Backing up pip installation..." -ForegroundColor Yellow
$pipPath = "$env:APPDATA\Python\Python313\site-packages\pip"
if (Test-Path $pipPath) {
    $backupPath = "$env:APPDATA\Python\Python313\site-packages\pip.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -Path $pipPath -Destination $backupPath -Recurse -Force
    Write-Host "Backup created: $backupPath" -ForegroundColor Green
}
Write-Host ""

# Step 3: Remove corrupted pip
Write-Host "Step 3: Removing corrupted pip installation..." -ForegroundColor Yellow
if (Test-Path $pipPath) {
    Remove-Item -Path $pipPath -Recurse -Force
    Write-Host "Corrupted pip removed" -ForegroundColor Green
}
Write-Host ""

# Step 4: Download get-pip.py
Write-Host "Step 4: Downloading get-pip.py bootstrap script..." -ForegroundColor Yellow
$getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
$getPipPath = "$env:TEMP\get-pip.py"
Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath
Write-Host "Downloaded: $getPipPath" -ForegroundColor Green
Write-Host ""

# Step 5: Reinstall pip using get-pip.py
Write-Host "Step 5: Reinstalling pip..." -ForegroundColor Yellow
python $getPipPath --force-reinstall
Write-Host ""

# Step 6: Verify pip installation
Write-Host "Step 6: Verifying pip installation..." -ForegroundColor Yellow
python -m pip --version
Write-Host ""

# Step 7: Upgrade pip to latest version
Write-Host "Step 7: Upgrading pip to latest version..." -ForegroundColor Yellow
python -m pip install --upgrade pip
Write-Host ""

# Step 8: Install required packages
Write-Host "Step 8: Installing pre-commit and dependencies..." -ForegroundColor Yellow
python -m pip install pre-commit virtualenv distlib
Write-Host ""

# Step 9: Verify pre-commit
Write-Host "Step 9: Verifying pre-commit installation..." -ForegroundColor Yellow
pre-commit --version
Write-Host ""

# Step 10: Test pre-commit hooks
Write-Host "Step 10: Testing pre-commit hooks..." -ForegroundColor Yellow
Set-Location "C:\Users\zerov\IdeaProjects\cvma"
git commit --allow-empty -m "Test commit to verify pre-commit hooks"
Write-Host ""

Write-Host "=== Python pip Repair Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Test Python: python -c 'import socket; print(\"OK\")'" -ForegroundColor White
Write-Host "2. Test pip: pip --version" -ForegroundColor White
Write-Host "3. Test pre-commit: pre-commit run --all-files" -ForegroundColor White
Write-Host "4. Make a test commit without --no-verify" -ForegroundColor White
