#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fetch best proxy from proxy-pool API and print/set it for 9Router.
.DESCRIPTION
    Queries proxy-pool (localhost:5000) for the highest-scored verified proxy,
    then outputs the proxy URL and optional env var commands.
.EXAMPLE
    .\proxy-pool-setup.ps1
    .\proxy-pool-setup.ps1 -MinScore 80 -ProtocolFilter socks5
#>
param(
    [string]$PoolUrl = "http://localhost:5000",
    [float]$MinScore = 50,
    [string]$ProtocolFilter = "http",
    [int]$Limit = 10
)
$ErrorActionPreference = "Stop"

Write-Host "`n[1/3] Checking proxy-pool at $PoolUrl ..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "$PoolUrl/health" -Method Get -TimeoutSec 10
    Write-Host "  Status: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Cannot reach proxy-pool. Start it first:" -ForegroundColor Red
    Write-Host "  docker compose -f compose.proxy-pool.yaml up -d proxy-pool" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[2/3] Fetching best proxy ..." -ForegroundColor Cyan
$params = @("limit=$Limit", "min_score=$MinScore", "anonymous=true")
if ($ProtocolFilter -in @("http", "socks5")) { $params += "source_protocol=$ProtocolFilter" }
$query = $params -join "&"
try {
    $result = Invoke-RestMethod -Uri "$PoolUrl/proxies?$query" -Method Get -TimeoutSec 15
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red; exit 1
}
if ($result.total -eq 0) {
    Write-Host "  No proxies found. Pool may still be initializing." -ForegroundColor Yellow; exit 1
}
$best = $result.items[0]
$ep = $best.endpoint; $pr = $best.source_protocol
$proxyUrl = if ($pr -in @("socks5","socks4")) { "socks5://$ep" } else { "http://$ep" }

Write-Host "  Best proxy:" -ForegroundColor Green
Write-Host "    $ep  ($pr)  score=$($best.quality.score)  latency=$($best.quality.avg_latency_ms)ms"

Write-Host "`n[3/3] 9Router configuration:" -ForegroundColor Cyan
Write-Host "`n  Docker Compose (automatic):" -ForegroundColor Yellow
Write-Host "  docker compose -f compose.proxy-pool.yaml up -d" -ForegroundColor Gray
Write-Host "`n  Manual env vars:" -ForegroundColor Yellow
Write-Host "    `$env:HTTP_PROXY  = `"$proxyUrl`"" -ForegroundColor White
Write-Host "    `$env:HTTPS_PROXY = `"$proxyUrl`"" -ForegroundColor White
Write-Host "    `$env:ALL_PROXY   = `"$proxyUrl`"" -ForegroundColor White
Write-Host "`n  .env file:" -ForegroundColor Yellow
Write-Host "    HTTP_PROXY=$proxyUrl" -ForegroundColor White
Write-Host "    HTTPS_PROXY=$proxyUrl" -ForegroundColor White
Write-Host "    ALL_PROXY=$proxyUrl" -ForegroundColor White
Write-Host "`nDone! Proxy: $proxyUrl" -ForegroundColor Green
