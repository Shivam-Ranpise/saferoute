# SafeRoute Admin - One-click Web Build & Vercel Deploy Script

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  SafeRoute Web: Building & Deploying    " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Compile Flutter Web
Write-Host "`n[1/3] Compiling Flutter Web Release..." -ForegroundColor Yellow
Set-Location -Path "$PSScriptRoot\..\apps\saferoute_admin"
flutter build web --release

# 2. Sync to root public/
Write-Host "`n[2/3] Syncing build to public folder..." -ForegroundColor Yellow
Set-Location -Path "$PSScriptRoot\.."
if (Test-Path public) {
    Remove-Item -Recurse -Force public
}
Copy-Item -Recurse -Force apps\saferoute_admin\build\web public

# 3. Deploy to Vercel Production
Write-Host "`n[3/3] Deploying to Vercel Production..." -ForegroundColor Green
npx vercel public --prod --yes

Write-Host "`n Deployment Complete! Live at: https://saferoute-admin-self.vercel.app" -ForegroundColor Cyan
