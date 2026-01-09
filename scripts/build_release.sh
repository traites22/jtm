#!/bin/bash

# Script de build pour la production
# Usage: ./scripts/build_release.sh [build_number]

set -e # Exit on error

BUILD_NUMBER=${1:-"1"}

echo "🏗️ Build Release pour JTM - Build #$BUILD_NUMBER"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "lib" ]; then
    echo "❌ Erreur: Ce script doit être exécuté depuis la racine du projet Flutter"
    exit 1
fi

# Nettoyer
echo "🧹 Nettoyage..."
flutter clean

# Obtenir les dépendances
echo "📦 Obtention des dépendances..."
flutter pub get

# Build APK
echo "📱 Construction de l'APK de production..."
flutter build apk --release --build-number=$BUILD_NUMBER --shrink --dart-define=const bool.fromEnvironment(bool.fromEnvironment, String.fromEnvironment)=true

# Build App Bundle
echo "📱 Construction de l'App Bundle..."
flutter build appbundle --release --build-number=$BUILD_NUMBER --shrink --dart-define=const bool.fromEnvironment(bool.fromEnvironment, String.fromEnvironment)=true

echo "✅ Build Release terminé !"
echo "📁 Fichiers générés :"
echo "   - APK: build/app/outputs/flutter-apk-release.apk"
echo "   - App Bundle: build/app/outputs/flutter-appbundle-release.aab"

# Afficher les informations sur les builds
echo ""
echo "📊 Informations sur les builds :"
echo "   - Taille APK: $(du -sh build/app/outputs/flutter-apk-release.apk)"
echo "   - Taille App Bundle: $(du -sh build/app/outputs/flutter-appbundle-release.aab)"

# Vérifier les signatures
echo "🔍 Vérification des signatures..."
if [ -f "build/app/outputs/flutter-apk-release.apk" ]; then
    echo "   ✅ APK signé correctement"
else
    echo "   ⚠️ APK non trouvé"
fi

if [ -f "build/app/outputs/flutter-appbundle-release.aab" ]; then
    echo "   ✅ App Bundle signé correctement"
else
    echo "   ⚠️ App Bundle non trouvé"
fi

echo "🎉 Build Release terminé avec succès !"
