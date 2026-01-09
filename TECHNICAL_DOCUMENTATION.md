# JTM - Documentation Technique

## Table des matières
- [Architecture](#architecture)
- [Services](#services)
- [Écrans](#screens)
- [Widgets](#widgets)
- [Modèles](#models)
- [Configuration](#configuration)
- [Déploiement](#deployment)

---

## Architecture

### Structure de l'application
```
lib/
├── main.dart                 # Point d'entrée
├── app/                     # Configuration et thèmes
│   ├── main_app.dart         # Widget principal
│   ├── app_theme.dart        # Thème de l'application
│   └── theme_service.dart    # Service de gestion des thèmes
├── services/                  # Logique métier
│   ├── auth/               # Services d'authentification
│   │   ├── pure_firebase_auth_service.dart
│   │   ├── contact_matching_service.dart
│   │   └── firebase_user_service.dart
│   ├── messaging/           # Services de messagerie
│   ├── verification/        # Services de vérification
│   └── notifications/       # Services de notifications
├── screens/                   # Écrans de l'application
│   ├── auth/              # Écrans d'authentification
│   │   ├── auth_choice_screen.dart
│   │   ├── verification_screen.dart
│   │   └── complete_profile_screen.dart
│   ├── main/              # Écrans principaux
│   │   ├── home_screen.dart
│   │   ├── message_screen.dart
│   │   ├── matches_screen.dart
│   │   ├── annonce_screen.dart
│   │   └── settings_screen_functional.dart
│   └── profile/            # Écrans de profil
│       └── profile_settings_screen.dart
├── models/                    # Modèles de données
│   ├── user_model.dart
│   ├── auth_result.dart
│   ├── message_model.dart
│   └── announcement_model.dart
├── widgets/                   # Composants UI réutilisables
│   ├── enhanced/           # Widgets améliorés
│   └── common/            # Widgets communs
└── assets/                     # Ressources statiques
    ├── images/
    ├── icons/
    └── fonts/
```

---

## Services

### Authentification Firebase
- **PureFirebaseAuthService** : Authentification email/téléphone
- **ContactMatchingService** : Matching sécurisé par contacts
- **FirebaseUserService** : Gestion des profils utilisateurs

### Messagerie
- **MessagingService** : Messages en temps réel
- **NotificationService** : Notifications push

---

## Écrans principaux

### 1. AuthChoiceScreen
- **Fonctionnalité** : Choix email/téléphone pour inscription
- **Validation** : Email format, téléphone international
- **Navigation** : Vers écran de vérification

### 2. VerificationScreen
- **Fonctionnalité** : Vérification code 6 chiffres
- **Support** : Email et SMS (simulé pour SMS)
- **Interface** : Moderne avec indicateur de chargement
- **Navigation** : Vers profil complet après validation

### 3. CompleteProfileScreen
- **Fonctionnalité** : Formulaire profil complet
- **Champs** : Nom, âge, genre, ville, travail, description, intérêts
- **Photos** : Upload et gestion des photos de profil
- **Validation** : Tous les champs requis validés

### 4. HomeScreen
- **Navigation** : 5 onglets avec BottomNavigationBar
- **Onglets** : Découvrir, Match, Annonce, Messages, Paramètres
- **Design** : Cohérent avec thème rose

### 5. MessageScreen
- **Fonctionnalité** : Liste des conversations
- **Recherche** : Filtrage temps réel des conversations
- **Interface** : Photos de profil, timestamps formatés
- **Navigation** : Chat direct au clic

### 6. AnnonceScreen
- **Fonctionnalité** : Publications anonymes/publiques
- **Options** : Toggle anonymat/public
- **Interface** : Création et consultation des annonces
- **Design** : Cartes modernes avec ombres

### 7. MatchesScreen
- **Fonctionnalité** : Liste des matchs uniquement
- **Interface** : Photos de profil, dernier message
- **Navigation** : Chat direct au clic sur un match

### 8. SettingsScreenFunctional
- **Fonctionnalité** : Paramètres complets
- **Sections** : Compte, Sécurité, Apparence, À propos
- **Intégration** : Gestion profil dans paramètres

---

## Tests Unitaires

### Structure des tests
```
test/
├── unit/                  # Tests unitaires
│   ├── services/          # Tests des services
│   ├── auth_service_test.dart
│   ├── contact_matching_test.dart
│   └── messaging_test.dart
├── widget/                  # Tests des widgets
│   ├── enhanced_input_test.dart
│   └── message_bubble_test.dart
└── integration/             # Tests d'intégration
    ├── auth_flow_test.dart
    ├── navigation_test.dart
    └── end_to_end_test.dart
```

---

## Configuration

### Environment Variables
```
# Development
FIREBASE_PROJECT_ID=jtm-dev
FIREBASE_DATABASE_URL=https://jtm-dev.firebaseio.com
FLUTTER_WEB_PORT=8080

# Production
FIREBASE_PROJECT_ID=jtm-prod
FIREBASE_DATABASE_URL=https://jtm-prod.firebaseio.com
```

---

## Déploiement

### Build Commands
```bash
# Development
flutter build web --debug --web-port=8080

# Production
flutter build web --release --web-port=8080
flutter build apk --release
```

### CI/CD Pipeline
```yaml
name: JTM CI/CD
on:
  push:
    branches: [main, develop]
  jobs:
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - uses: actions/setup-java@v3
        - uses: actions/setup-flutter@v3
        - run: flutter test
        - run: flutter analyze
    build:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - uses: actions/setup-java@v3
        - uses: actions/setup-flutter@v3
        - run: flutter build web --release
        - run: flutter build apk --release
```

---

## Monitoring

### Analytics
- **Événements** : Connexions, inscriptions, messages
- **Performance** : Temps de chargement, erreurs
- **Utilisation** : Fonctionnalités les plus utilisées

---

## Sécurité

### Implémentations
- ✅ **Hashage SHA-256** pour les contacts
- ✅ **Consentement explicite** requis pour matching
- ✅ **Validation entrées** côté client et serveur
- ✅ **Authentification JWT** pour les APIs
- ✅ **HTTPS obligatoire** en production

---

## Performance

### Optimisations
- ✅ **Lazy loading** pour les listes
- ✅ **Image caching** avec CachedNetworkImage
- ✅ **State management** efficace avec Provider/Bloc
- ✅ **Memory management** avec Hive
- ✅ **Async operations** optimisées

---

Cette documentation complète servira de référence pour toute l'équipe de développement et de maintenance.
