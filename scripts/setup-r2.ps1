# ============================================================
# AUTO SETUP: R2 Budget Guard + GitHub Secrets
# Chạy script này 1 lần — tự động cấu hình mọi thứ.
# ============================================================
# Syntax:  powershell -ExecutionPolicy Bypass -File scripts\setup-r2.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$GH = "C:\Program Files\GitHub CLI\gh.exe"
$REPO = "Nhieuvu1802/xsmb-manager"

Write-Host "`n=== XSMB Manager — R2 Auto Setup ===" -ForegroundColor Cyan

# ── 1. Generate random secrets ──
function New-Secret([int]$Length = 48) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

$adminSecret = New-Secret 48
$cronSecret  = New-Secret 32

Write-Host "`n[1/4] Generated secrets" -ForegroundColor Green
Write-Host "  ADMIN_SECRET = $adminSecret"
Write-Host "  CRON_SECRET  = $cronSecret"

# ── 2. Push to GitHub ──
Write-Host "`n[2/4] Pushing to GitHub Secrets..." -ForegroundColor Green
& $GH secret set ADMIN_SECRET --repo $REPO --body $adminSecret
& $GH secret set CRON_SECRET  --repo $REPO --body $cronSecret
Write-Host "  Done!" -ForegroundColor Green

# ── 3. Create R2 bucket ──
Write-Host "`n[3/4] Creating R2 bucket 'xsmb-data'..." -ForegroundColor Green
try {
    npx wrangler r2 bucket create xsmb-data 2>&1
    Write-Host "  Bucket created!" -ForegroundColor Green
} catch {
    Write-Host "  Bucket may already exist (OK) or R2 not enabled yet." -ForegroundColor Yellow
}

# ── 4. Deploy Worker ──
Write-Host "`n[4/4] Deploying Worker..." -ForegroundColor Green
npx wrangler deploy 2>&1

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Secrets saved to GitHub — next push to main will auto-deploy with R2." -ForegroundColor White
Write-Host "Circuit breaker: POST /v1/r2/circuit-breaker" -ForegroundColor White
Write-Host "  Header: Authorization: Bearer $adminSecret" -ForegroundColor DarkGray
