$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$py = (Get-Command py -ErrorAction SilentlyContinue).Source
$pyArgs = @("-3")
if (-not $py) {
    $py = (Get-Command python -ErrorAction SilentlyContinue).Source
    $pyArgs = @()
}

if (-not $py) {
    Write-Host "No Python launcher found. Install Python first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".athena-venv")) {
    & $py @pyArgs -m venv .athena-venv
}

& ".\.athena-venv\Scripts\python.exe" -m pip install --upgrade pip
& ".\.athena-venv\Scripts\python.exe" -m pip install -r requirements.txt
Write-Host "Athena setup complete. Run: .\run-athena.ps1" -ForegroundColor Green
