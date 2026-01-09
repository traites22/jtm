#!/bin/bash

# Script de test complet pour l'application JTM
set -e # Exit on error

echo "🧪 Tests complets pour JTM"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "lib" ]; then
    echo "❌ Erreur: Ce script doit être exécuté depuis la racine du projet Flutter"
    exit 1
fi

# Nettoyer les tests précédents
echo "🧹 Nettoyage des tests précédents..."
flutter clean

# Obtenir les dépendances
echo "📦 Obtention des dépendances..."
flutter pub get

# Analyse du code
echo "🔍 Analyse du code..."
flutter analyze

# Tests unitaires
echo "🧪 Tests unitaires..."
flutter test --coverage

# Tests d'intégration
echo "🔍 Tests d'intégration..."
flutter test integration/

# Golden tests
echo "📸 Tests golden..."
flutter test --update-gold-gold

# Tests de performance
echo "⚡ Tests de performance..."
flutter test --performance

echo "✅ Tests terminés !"

# Rapport de couverture
echo "📊 Génération du rapport de couverture..."
genhtml coverage

echo "🎉 Tests terminés avec succès !"
