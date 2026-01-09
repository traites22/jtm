# JTM

Ceci est le projet Flutter *JTM* créé pour démarrer le développement.

## Prérequis
- Flutter SDK installé et accessible depuis le PATH
- Android SDK + Command-line tools installés (licences acceptées)
- Java / JDK installé (fourni par Android Studio ou OpenJDK)
- Visual Studio (optionnel pour build Windows)
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