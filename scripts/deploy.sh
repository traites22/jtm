#!/bin/bash

# Script de déploiement pour l'application JTM
# Usage: ./scripts/deploy.sh [environment] [build_number]

set -e  # Exit on error

# Configuration
PROJECT_NAME="jtm"
ENVIRONMENT=${1:-"production"}
BUILD_NUMBER=${2:-"1"}
VERSION="1.0.0"
BUNDLE_ID="com.jtm.app"

echo "🚀 Déploiement de $PROJECT_NAME - Environnement: $ENVIRONMENT"
echo "📦 Version: $VERSION+$BUILD_NUMBER"
echo "📱 Bundle ID: $BUNDLE_ID"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "lib" ]; then
    echo "❌ Erreur: Ce script doit être exécuté depuis la racine du projet Flutter"
    exit 1
fi

# Nettoyer les builds précédents
echo "🧹 Nettoyage des builds précédents..."
flutter clean

# Obtenir les dépendances
echo "📦 Obtention des dépendances..."
flutter pub get

# Analyse le code
echo "🔍 Analyse du code..."
flutter analyze

# Construction de l'application selon l'environnement
if [ "$ENVIRONMENT" = "production" ]; then
    echo "🏭️ Construction pour la production..."
    flutter build apk --release --build-number=$BUILD_NUMBER --shrink
    echo "📱 Construction de l'IPA pour iOS..."
    flutter build ipa --release --build-number=$BUILD_NUMBER
elif [ "$ENVIRONMENT" = "staging" ]; then
    echo "🧪 Construction pour la staging..."
    flutter build apk --release --build-number=$BUILD_NUMBER --dart-define=const.bool.fromEnvironment(bool.fromEnvironment, String.fromEnvironment)=true
    flutter build ipa --release --build-number=$BUILD_NUMBER --dart-define=const.bool.fromEnvironment(bool.fromEnvironment, String.fromEnvironment)=true
else
    echo "🔧 Construction pour le développement..."
    flutter build apk --debug
    flutter build ipa --debug
fi

echo "✅ Construction terminée avec succès!"

# Tests
echo "🧪 Exécution des tests..."
flutter test

# Tests d'intégration
echo "🔍 Tests d'intégration..."
flutter test integration/

# Vérification de la build
echo "🔍 Vérification de la build..."
flutter doctor -v

echo "🎉 Déploiement terminé !"
echo "📱 Les fichiers build sont disponibles dans build/app/outputs/"
echo "📊 Utilisez 'flutter install' pour tester l'application sur votre appareil"
