# 🚀 Script de Déploiement JTM - Production (PowerShell)
# Compatible Windows PowerShell

Write-Host "🔥 Début du déploiement JTM en production..."

# Étape 1: Nettoyage
Write-Host "🧹 Nettoyage du projet..."
flutter clean
flutter pub get

# Étape 2: Vérification de l'environnement
Write-Host "🔍 Vérification de la configuration..."
if (-not (Test-Path ".env")) {
    Write-Host "❌ Erreur: Fichier .env introuvable" -ForegroundColor Red
    exit 1
}

# Étape 3: Build Android
Write-Host "📱 Build Android (Release)..."
flutter build apk --release --obfuscate --split-debug-info --shrink

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur: Build Android échoué" -ForegroundColor Red
    exit 1
}

# Étape 4: Build iOS (si disponible)
Write-Host "🍎 Build iOS (Release)..."
if (Get-Command ios-deploy -ErrorAction SilentlyContinue) {
    flutter build ios --release --obfuscate --shrink
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erreur: Build iOS échoué" -ForegroundColor Red
        exit 1
    }
}

# Étape 5: Tests rapides
Write-Host "🧪 Tests d'intégration rapides..."
flutter test integration_test/navigation_test.dart --reporter=expanded
flutter test test/error_scenarios_test.dart --reporter=expanded

# Étape 6: Déploiement Firebase App Distribution
Write-Host "📤 Déploiement sur Firebase App Distribution..."

# Déploiement Android
if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
    Write-Host "📱 Déploiement Android..."
    firebase appdistribution:distribute `
        --app build/app/outputs/flutter-apk/app-release.apk `
        --app-id 1:401147120494:android:6ab47f840302b796a10f7f `
        --release-notes "🚀 Version Production - Optimisations performances et monitoring complet" `
        --groups "testers"
} else {
    Write-Host "⚠️ APK Android non trouvé" -ForegroundColor Yellow
}

# Déploiement iOS
if (Get-Command ios-deploy -ErrorAction SilentlyContinue -and (Test-Path "build/ios/Runner.app")) {
    Write-Host "🍎 Déploiement iOS..."
    firebase appdistribution:distribute `
        --app build/ios/Runner.app `
        --app-id 1:401147120494:ios:xxxxxxxx `
        --release-notes "🚀 Version Production - Optimisations performances et monitoring complet" `
        --groups "testers"
} else {
    Write-Host "⚠️ App iOS non trouvée" -ForegroundColor Yellow
}

Write-Host "✅ Déploiement terminé !" -ForegroundColor Green
Write-Host "📊 Vérifiez la console Firebase pour le monitoring..." -ForegroundColor Cyan
Write-Host "🔗 Lien de distribution sera disponible dans la console Firebase" -ForegroundColor Cyan
