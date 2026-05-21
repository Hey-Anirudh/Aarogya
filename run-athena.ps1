param(
    [string[]]$AthenaArgs = @()
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$athenaVenvPython = Join-Path $root ".athena-venv\Scripts\python.exe"
$venvPython = Join-Path $root ".venv\Scripts\python.exe"

function Test-Python($Path) {
    if (-not $Path) { return $false }
    try {
        & $Path -c "import sys; print(sys.executable)" *> $null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

$python = $null
$pythonArgs = @()
if (Test-Python $athenaVenvPython) {
    $python = $athenaVenvPython
} elseif (Test-Python $venvPython) {
    $python = $venvPython
} else {
    $candidate = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (Test-Python $candidate) {
        $python = $candidate
    } else {
        $pyLauncher = (Get-Command py -ErrorAction SilentlyContinue).Source
        if ($pyLauncher) {
            try {
                & $pyLauncher -3 -c "import sys; print(sys.executable)" *> $null
                if ($LASTEXITCODE -eq 0) {
                    $python = $pyLauncher
                    $pythonArgs = @("-3")
                }
            } catch {
                $python = $null
                $pythonArgs = @()
            }
        }
    }
}

if (-not $python) {
    Write-Host "Athena could not find a working Python interpreter." -ForegroundColor Red
    Write-Host "Create a local venv and install dependencies:" -ForegroundColor Yellow
    Write-Host "  python -m venv .athena-venv"
    Write-Host "  .\.athena-venv\Scripts\python.exe -m pip install -r requirements.txt"
    exit 1
}

& $python @pythonArgs (Join-Path $root "athena.py") @AthenaArgs
exit $LASTEXITCODE
