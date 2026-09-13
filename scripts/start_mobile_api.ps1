param(
    [string]$HostAddress = "0.0.0.0",
    [int]$Port = 8000
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $projectRoot "backend"
$dataDir = Join-Path $projectRoot "data"
$python = Join-Path $projectRoot ".venv\Scripts\python.exe"
$sourceDatabase = Join-Path $dataDir "xsmb.db"
$apiDatabase = Join-Path $dataDir "api-mobile.db"

if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    throw "Python environment not found at $python"
}
if (-not (Test-Path -LiteralPath $dataDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
}

$databaseUrlPath = [IO.Path]::GetFullPath($apiDatabase).Replace("\", "/")
$env:DATABASE_URL = "sqlite+pysqlite:///$databaseUrlPath"

$secretBytes = New-Object byte[] 32
$random = [Security.Cryptography.RandomNumberGenerator]::Create()
$random.GetBytes($secretBytes)
$random.Dispose()
$env:JWT_SECRET = [Convert]::ToBase64String($secretBytes)

if (-not (Test-Path -LiteralPath $apiDatabase -PathType Leaf)) {
    if (-not (Test-Path -LiteralPath $sourceDatabase -PathType Leaf)) {
        throw "Source database not found at $sourceDatabase"
    }
    & $python (Join-Path $PSScriptRoot "migrate_sqlite_to_postgres.py") $sourceDatabase
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create the mobile API database"
    }
}

Write-Host "Mobile API: http://localhost:$Port/api/v1"
Write-Host "Phone on the same Wi-Fi: use http://<PC-LAN-IP>:$Port/api/v1"
& $python -m uvicorn xsmb_manager.api.main:app --app-dir $backendDir --host $HostAddress --port $Port
