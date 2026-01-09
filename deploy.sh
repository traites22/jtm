# 🚀 Script de Déploiement JTM - Production
# Instructions : chmod +x deploy.sh && ./deploy.sh

echo "🔥 Début du déploiement JTM en production..."

# Étape 1: Nettoyage
echo "🧹 Nettoyage du projet..."
flutter clean
flutter pub get

# Étape 2: Vérification de l'environnement
echo "🔍 Vérification de la configuration..."
if [ ! -f ".env" ]; then
    echo "❌ Erreur: Fichier .env introuvable"
    exit 1
fi

# Étape 3: Build Android
echo "📱 Build Android (Release)..."
flutter build apk --release --obfuscate --split-debug-info --shrink

if [ $? -ne 0 ]; then
    echo "❌ Erreur: Build Android échoué"
    exit 1
fi

# Étape 4: Build iOS (si disponible)
echo "🍎 Build iOS (Release)..."
if command -v ios-deploy > /dev/null 2>&1; then
    flutter build ios --release --obfuscate --shrink
    if [ $? -ne 0 ]; then
        echo "❌ Erreur: Build iOS échoué"
        exit 1
    fi
fi

# Étape 5: Tests rapides
echo "🧪 Tests d'intégration rapides..."
flutter test integration_test/navigation_test.dart --reporter=expanded
flutter test test/error_scenarios_test.dart --reporter=expanded

# Étape 6: Déploiement Firebase App Distribution
echo "📤 Déploiement sur Firebase App Distribution..."

# Déploiement Android
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "📱 Déploiement Android..."
    firebase appdistribution:distribute \
        --app build/app/outputs/flutter-apk/app-release.apk \
        --app-id 1:401147120494:android:6ab47f840302b796a10f7f \
        --release-notes "🚀 Version Production - Optimisations performances et monitoring complet" \
        --groups "testers"
else
    echo "⚠️ APK Android non trouvé"
fi

# Déploiement iOS
if command -v ios-deploy > /dev/null 2>&1 && [ -f "build/ios/Runner.app" ]; then
    echo "🍎 Déploiement iOS..."
    firebase appdistribution:distribute \
        --app build/ios/Runner.app \
        --app-id 1:401147120494:ios:xxxxxxxx \
        --release-notes "🚀 Version Production - Optimisations performances et monitoring complet" \
        --groups "testers"
else
    echo "⚠️ App iOS non trouvée"
fi

echo "✅ Déploiement terminé !"
echo "📊 Vérifiez la console Firebase pour le monitoring..."
echo "🔗 Lien de distribution sera disponible dans la console Firebase"
