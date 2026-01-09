#!/bin/bash

# Script d'installation et de configuration pour le projet JTM
set -e # Exit on error

echo "🔧 Installation et configuration pour JTM"

# Vérifier si Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé. Installation en cours..."
    
    # Installation de Flutter
    if [[ "$OSTYPE" == "linux" ]]; then
        sudo snap install flutter --classic
    elif [[ "$OSTYPE" == "darwin" ]]; then
        if ! command -v brew &> /dev/null; then
            echo "🍺 Installation de Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install flutter
    elif [[ "$OSTYPE" == "msys" ]]; then
        echo "🪟 Installation de Flutter sur Windows..."
        choco install flutter
    else
        echo "❌ Système d'exploitation non supporté"
        exit 1
    fi
else
    echo "✅ Flutter est déjà installé"
fi

# Vérifier la version de Flutter
FLUTTER_VERSION=$(flutter --version | cut -d' ' ' -f 1)
echo "📱 Version Flutter: $FLUTTER_VERSION"

# Vérifier si les outils Android sont installés
if [[ "$OSTYPE" == "linux" ]] || [[ "$OSTYPE" == "darwin" ]]; then
    if command -v java -version &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | cut -d' ' ' -f 1 | cut -d' '.' -f 2)
        echo "✅ Java version: $JAVA_VERSION"
    else
        echo "❌ Java n'est pas installé"
        echo "Installation de Java requis pour le développement Android..."
        if [[ "$OSTYPE" == "linux" ]]; then
            sudo apt update
            sudo apt install openjdk-11-jdk
        elif [[ "$OSTYPE" == "darwin" ]]; then
            brew install openjdk@11
        fi
    fi
    
    # Vérifier Android Studio
    if command -v studio &> /dev/null; then
        echo "✅ Android Studio est installé"
    else
        echo "⚠️ Android Studio n'est pas installé"
        echo "Installation d'Android Studio recommandé pour le développement Android"
        if [[ "$OSTYPE" == "linux" ]]; then
            sudo snap install android-studio --classic
        elif [[ "$OSTYPE" == "darwin" ]]; then
            brew install --cask android-studio
        fi
    fi
fi

# Vérifier Xcode pour iOS
if [[ "$OSTYPE" == "darwin" ]]; then
    if command -v xcodebuild -version &> /dev/null; then
        echo "✅ Xcode est installé"
        echo "   Version: $(xcodebuild -version)"
    else
        echo "⚠️ Xcode n'est pas installé"
        echo "Installation de Xcode requis pour le développement iOS..."
        xcode-select --install
    fi
    
    # Vérifier CocoaPods
    if command -v pod --version &> /dev/null; then
        echo "✅ CocoaPods est installé"
        echo "   Version: $(pod --version)"
    else
        echo "⚠️ CocoaPods n'est pas installé"
        echo "Installation de CocoaPods requis pour le développement iOS..."
        sudo gem install cocoapods
    fi
fi

# Créer les répertoires nécessaires
echo "📁 Création des répertoires..."
mkdir -p scripts
mkdir -p assets/images
mkdir -p assets/icons
mkdir - assets/fonts
mkdir -p assets/animations
mkdir -p assets/config

# Rendre les scripts exécutables
echo "🔧 Configuration des scripts..."
chmod +x scripts/*.sh

# Vérifier les dépendances
echo "📦 Vérification des dépendances..."
flutter pub get

# Vérifier la configuration Flutter
echo "🔍 Vérification de la configuration Flutter..."
flutter doctor -v

# Configuration de l'environnement
echo "⚙️ Configuration de l'environnement..."

# Variables d'environnement pour le développement
export FLUTTER_ROOT="$PWD"
export PATH="$FLUTTER_ROOT/bin:$PATH"

echo "✅ Installation et configuration terminées !"
echo ""
echo "📋 Prochaines recommandées :"
echo "1. Ouvrir le projet dans votre IDE (VS Code, Android Studio, Xcode)"
echo "2. Exécuter 'flutter pub get' pour installer les dépendances"
echo "3. Utiliser 'flutter run' pour lancer l'application en mode développement"
echo "4. Utiliser 'scripts/test.sh' pour exécuter les tests"
echo "5. Utiliser 'scripts/deploy.sh' pour le déploiement en production"
echo ""
echo "🚀 Votre projet JTM est prêt pour le développement !"
