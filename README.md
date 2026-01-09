# JTM - Application de Rencontre Moderne

🔥 **Application de rencontre Flutter avec Firebase, authentification sociale, notifications push, localisation et plus !**

## 🚀 Fonctionnalités Complètes

### ✅ **Infrastructure de Niveau Entreprise**
- **Firebase Hosting** - Déploiement web avec HTTPS et CDN
- **CI/CD GitHub Actions** - Tests automatiques et déploiement continu
- **Protections de branche** - Qualité et sécurité du code
- **Monitoring avancé** - Performance et erreurs en temps réel

### 🔐 **Authentification Multi-fournisseurs**
- **Email/Password** - Authentification classique
- **Google Sign-In** - Connexion via compte Google
- **Facebook Login** - Connexion via compte Facebook
- **Account Linking** - Lier plusieurs providers
- **Biometric Auth** - Empreintes digitales et Face ID

### 📱 **Notifications en Temps Réel**
- **Push Notifications** - Firebase Cloud Messaging
- **Notifications locales** - Alertes dans l'application
- **Types de notifications** : Matchs, messages, vues de profil
- **Préférences utilisateur** - Contrôle total des notifications

### 🌍 **Services de Localisation**
- **GPS Tracking** - Géolocalisation précise
- **Geocoding** - Conversion adresse ↔ coordonnées
- **Recherche par distance** - Trouver des utilisateurs à proximité
- **Filtres de localisation** - Par distance et préférences

### ⚡ **Backend Serverless**
- **Cloud Functions** - Logique métier sans serveur
- **Firestore Database** - Base de données NoSQL sécurisée
- **Cloud Storage** - Stockage d'images optimisé
- **Règles de sécurité** - Protection des données utilisateur

### 🎯 **Fonctionnalités de Rencontre**
- **Swipe System** - Interface moderne de matching
- **Matching Algorithm** - Algorithmes intelligents de compatibilité
- **Chat en temps réel** - Messagerie instantanée
- **Profils détaillés** - Photos, intérêts, préférences
- **Filtres avancés** - Par âge, distance, intérêts

## 📋 Démarrage Rapide

### Prérequis
- **Flutter SDK** 3.38.5+
- **Node.js** 18+
- **Firebase CLI**
- **Android Studio** / **VS Code**

### Installation
```bash
# 1. Cloner le repository
git clone https://github.com/traites22/jtm.git
cd jtm

# 2. Installer les dépendances
flutter pub get

# 3. Configurer Firebase
firebase login
firebase use jtm-dev
- VS Code (recommandé) avec les extensions **Dart** et **Flutter**

## Démarrage rapide
1. Ouvrez le dossier du projet : `C:\JTM`
2. Récupérez les dépendances :
   - `flutter pub get`
3. Exécutez l'application :
   - `flutter run` (choisissez un appareil connecté)
   - Pour Windows : `flutter run -d windows`
4. Analyser le code : `flutter analyze`
5. Lancer les tests : `flutter test`

## Build
- Android APK : `flutter build apk`
- Windows (requiert Visual Studio) : `flutter build windows`

## Documentation de développement
Voir `DEVELOPMENT.md` pour un guide de développement plus complet et des commandes utiles.

---

![CI](https://github.com/<your-org>/<your-repo>/actions/workflows/flutter.yml/badge.svg)

**Notes plateforme**

- Android: Les permissions suivantes ont été ajoutées dans `android/app/src/main/AndroidManifest.xml` : `CAMERA`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `USE_BIOMETRIC`. Sur Android 13+, `READ_MEDIA_IMAGES` est requise pour lire images; l'application s'appuie sur le flux d'autorisation runtime fourni par `image_picker`.
- iOS: Les clés `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` et `NSFaceIDUsageDescription` sont présentes dans `ios/Runner/Info.plist`.

**Actions disponibles**

- Lancer l'application maintenant sur l'appareil Android connecté (ou émulateur) : `flutter run -d <device-id>`.
- Pousser CI (GitHub Actions) : le workflow `flutter.yml` est ajouté sous `.github/workflows` et exécutera `flutter analyze` + `flutter test`.

Dites-moi si vous voulez que je lance l'app maintenant sur l'appareil connecté ou que je pousse ces changements vers un remote et crée une PR.