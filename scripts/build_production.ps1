# SafeRoute Production Build & Verification Script (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SafeRoute Production Build Pipeline     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$RootPath = (Get-Item $PSScriptRoot).Parent.FullName

# 1. Test & Analyze saferoute_core
Write-Host "`n[1/3] Verifying saferoute_core..." -ForegroundColor Yellow
Set-Location "$RootPath\packages\saferoute_core"
flutter pub get
flutter test
flutter analyze

# 2. Test & Analyze saferoute_app
Write-Host "`n[2/3] Verifying saferoute_app (Mobile)..." -ForegroundColor Yellow
Set-Location "$RootPath\apps\saferoute_app"
flutter pub get
flutter test
flutter analyze

# 3. Test & Analyze saferoute_admin
Write-Host "`n[3/3] Verifying saferoute_admin (Web)..." -ForegroundColor Yellow
Set-Location "$RootPath\apps\saferoute_admin"
flutter pub get
flutter test
flutter analyze

Set-Location $RootPath
Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "  SafeRoute Monorepo: ALL BUILDS VERIFIED " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
