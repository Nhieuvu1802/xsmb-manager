#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start 9Router + Proxy Pool stack and auto-configure optimal models.
.DESCRIPTION
    Launches 9Router with proxy rotation, then auto-configures the optimal
    3-tier model combos for coding assistance (Claude Code, Cursor, Cline, etc.).
.EXAMPLE
    .\scripts\start-9router.ps1
    .\scripts\start-9router.ps1 -SkipModels
    .\scripts\start-9router.ps1 -VerifyOnly
#>
param(
    [switch]$SkipModels,     # Skip auto-configure (manual Dashboard setup)
    [switch]$VerifyOnly,     # Only verify, don't start
    [switch]$WithHeadroom,   # Include Headroom token-saver sidecar
)

$ErrorActionPreference = "Stop"
$compose = "compose.proxy-pool.yaml"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    9Router — Free AI Router & Token Saver                   ║" -ForegroundColor Cyan
Write-Host "║    Optimal Model Configuration for XSMB Manager             ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Validate ──
Write-Host "[1/5] Validating configuration..." -ForegroundColor Yellow

if (-not (Test-Path $compose)) {
    Write-Host "  ERROR: $compose not found in project root" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path ".env.proxy-pool")) {
    Write-Host "  ERROR: .env.proxy-pool not found" -ForegroundColor Red
    exit 1
}

# Check if secrets are still default
$envContent = Get-Content ".env.proxy-pool" -Raw
if ($envContent -match "JWT_SECRET=change-me") {
    Write-Host "  ⚠️  JWT_SECRET is still default! Generating random secret..." -ForegroundColor Yellow
    $newSecret = -join ((1..64) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
    $envContent = $envContent -replace "JWT_SECRET=change-me-to-a-long-random-secret", "JWT_SECRET=$newSecret"
    $newPassword = -join ((1..20) | ForEach-Object { [char](Get-Random -Minimum 33 -Maximum 126) })
    $envContent = $envContent -replace "INITIAL_PASSWORD=change-me", "INITIAL_PASSWORD=$newPassword"
    Set-Content ".env.proxy-pool" $envContent
    Write-Host "  ✅ Generated new JWT_SECRET and INITIAL_PASSWORD" -ForegroundColor Green
    Write-Host "  ⚠️  Save these credentials!" -ForegroundColor Yellow
    Write-Host "     Password: $newPassword" -ForegroundColor White
}

Write-Host "  ✅ Configuration validated" -ForegroundColor Green

# ── Step 2: Check Docker ──
Write-Host "[2/5] Checking Docker..." -ForegroundColor Yellow
try {
    docker info 2>&1 | Out-Null
    Write-Host "  ✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Docker is not running" -ForegroundColor Red
    exit 1
}

# ── Step 3: Start stack ──
Write-Host "[3/5] Starting 9Router + Proxy Pool stack..." -ForegroundColor Yellow

$services = @("9router", "proxy-pool", "proxy-rotate")
if ($WithHeadroom) {
    $services += "headroom"
}

docker compose -f $compose up -d --build @services
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Docker Compose failed" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Stack started" -ForegroundColor Green
Write-Host "     9Router:     http://localhost:20128" -ForegroundColor Gray
Write-Host "     Proxy Pool:  http://localhost:5000" -ForegroundColor Gray

# ── Step 4: Wait for 9Router ──
Write-Host "[4/5] Waiting for 9Router to be ready..." -ForegroundColor Yellow

$maxWait = 60
$waited = 0
while ($waited -lt $maxWait) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:20128/v1/models" -Method Get -TimeoutSec 5 -ErrorAction Stop
        Write-Host "  ✅ 9Router is ready (found models)" -ForegroundColor Green
        break
    } catch {
        Start-Sleep -Seconds 2
        $waited += 2
        Write-Host "  Waiting... ($waited s)" -ForegroundColor Gray -NoNewline
        Write-Host "`r" -NoNewline
    }
}

if ($waited -ge $maxWait) {
    Write-Host "  ⚠️  9Router may still be starting. Check: docker logs 9router" -ForegroundColor Yellow
}

# ── Step 5: Configure models ──
Write-Host "[5/5] Configuring optimal models..." -ForegroundColor Yellow

if ($SkipModels) {
    Write-Host "  ⏭️  Skipping (--SkipModels). Configure via Dashboard." -ForegroundColor Gray
} elseif ($VerifyOnly) {
    python scripts/setup-9router-models.py --action verify
} else {
    python scripts/setup-9router-models.py --action setup
}

# ── Summary ──
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ 9Router is running!" -ForegroundColor Green
Write-Host ""
Write-Host "  📊 Dashboard:  http://localhost:20128" -ForegroundColor White
Write-Host "  🔄 Proxy Pool: http://localhost:5000" -ForegroundColor White
Write-Host ""
Write-Host "  Point your tools:" -ForegroundColor Cyan
Write-Host "    Claude Code:  export ANTHROPIC_BASE_URL=http://localhost:20128/v1" -ForegroundColor White
Write-Host "    Cursor:       Settings → Models → API Base URL → http://localhost:20128/v1" -ForegroundColor White
Write-Host "    Cline:        Settings → API Base URL → http://localhost:20128/v1" -ForegroundColor White
Write-Host "    Codex:        export OPENAI_BASE_URL=http://localhost:20128/v1" -ForegroundColor White
Write-Host ""
Write-Host "  Combos: Claude Elite → Claude Fast → Gemini Pro → Codex Value → Copilot Hybrid" -ForegroundColor Gray
Write-Host "  Strategy: Subscription → Cheap ($0.20-0.60/1M) → FREE fallback" -ForegroundColor Gray
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
