# 🔓 Déblocage rapide PowerShell pour JTM

Write-Host "🔓 Déblocage PowerShell en cours..." -ForegroundColor Cyan

# Débloquer temporairement pour le déploiement
Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Host "✅ PowerShell débloqué pour cette session" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Maintenant installez Firebase Tools :" -ForegroundColor Yellow
Write-Host "npm install -g firebase-tools" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Puis exécutez : .\deploy.ps1" -ForegroundColor Cyan
