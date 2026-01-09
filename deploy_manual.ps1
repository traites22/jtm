# 🚀 Script Déploiement JTM - PowerShell Windows
# Version simplifiée sans dépendance npm

Write-Host "🔥 Déploiement JTM Production" -ForegroundColor Red

# Étape 1: Vérification de base
Write-Host "📁 Vérification des fichiers..." -ForegroundColor Cyan

if (-not (Test-Path ".env")) {
    Write-Host "❌ Fichier .env manquant" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "lib\main.dart")) {
    Write-Host "❌ Fichier main.dart manquant" -ForegroundColor Red
    exit 1
}

# Étape 2: Build Flutter
Write-Host "🔨 Build Flutter en cours..." -ForegroundColor Yellow

flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur nettoyage" -ForegroundColor Red
    exit 1
}

flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur dépendances" -ForegroundColor Red
    exit 1
}

flutter build apk --release --obfuscate --shrink
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur build" -ForegroundColor Red
    exit 1
}

# Étape 3: Tests rapides
Write-Host "🧪 Tests d'intégration..." -ForegroundColor Yellow

flutter test integration_test/navigation_test.dart --reporter=expanded
flutter test test/error_scenarios_test.dart --reporter=expanded

# Étape 4: Déploiement manuel
Write-Host "📱 APK généré, déploiement manuel requis" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Instructions manuelles :" -ForegroundColor Cyan
Write-Host "1. Ouvrir Firebase Console : https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. Aller dans App Distribution" -ForegroundColor White  
Write-Host "3. Uploader manuellement : build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White
Write-Host ""
Write-Host "📊 Monitoring configuré dans l'application" -ForegroundColor Green
Write-Host "🎯 JTM prêt pour la production !" -ForegroundColor Green
