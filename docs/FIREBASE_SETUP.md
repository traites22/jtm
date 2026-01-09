# Firebase Setup Guide

## 🔥 Configuration Firebase pour JTM

### **Projet Firebase**
- **Project ID**: `jtm-dev`
- **Services activés**: Authentication, Firestore, Storage, Hosting

### **Services Configurés**

#### **1. Authentication**
- ✅ **Email/Password** activé
- ✅ **Comptes anonymes** (optionnel)
- ✅ **Fournisseurs sociaux** (optionnel)

#### **2. Firestore Database**
- ✅ **Base de données** en mode production
- ✅ **Règles de sécurité** configurées
- ✅ **Collections** : users, matches, messages, connectionRequests, reports

#### **3. Cloud Storage**
- ✅ **Stockage d'images** activé
- ✅ **Règles de sécurité** configurées
- ✅ **Dossiers** : profile_images, chat_images, temp_uploads

#### **4. Firebase Hosting**
- ⏳ **À configurer** pour le déploiement web

### **Structure des Données**

#### **Users Collection**
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "username": "johndoe",
  "age": 25,
  "bio": "Passionné de voyages",
  "interests": ["voyages", "photographie", "musique"],
  "profileImageUrl": "https://storage.googleapis.com/...",
  "location": {
    "latitude": 48.8566,
    "longitude": 2.3522
  },
  "preferences": {
    "ageRange": {"min": 18, "max": 99},
    "maxDistance": 50,
    "showAge": true,
    "showDistance": true
  },
  "matches": ["user456", "user789"],
  "isProfileComplete": true,
  "visibility": "public",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

#### **Matches Collection**
```json
{
  "users": ["user123", "user456"],
  "status": "active",
  "createdAt": "2024-01-01T00:00:00Z",
  "lastMessage": "Salut !",
  "lastMessageTime": "2024-01-01T12:00:00Z"
}
```

#### **Messages Collection**
```json
{
  "senderId": "user123",
  "text": "Salut !",
  "timestamp": "2024-01-01T12:00:00Z",
  "type": "text",
  "imageUrl": null
}
```

### **Règles de Sécurité**

#### **Firestore Rules**
- ✅ **Users**: Accès complet pour l'utilisateur lui-même
- ✅ **Matches**: Accès pour les participants uniquement
- ✅ **Messages**: Accès pour les participants du match
- ✅ **Admin**: Accès restreint aux administrateurs

#### **Storage Rules**
- ✅ **Profile Images**: Accès complet pour l'utilisateur
- ✅ **Chat Images**: Accès pour les participants du match
- ✅ **Temp Uploads**: Accès temporaire pour l'utilisateur

### **Services Flutter**

#### **FirebaseService**
```dart
// Initialisation centralisée de Firebase
await FirebaseService.instance.initialize();
```

#### **AuthServiceFirebase**
```dart
// Authentification complète
await authService.registerWithEmailPassword(
  email: 'user@example.com',
  password: 'password123',
  username: 'johndoe',
  age: 25,
);
```

#### **DatabaseService**
```dart
// Opérations de base de données
await databaseService.createUserDocument(userData);
Stream<QuerySnapshot> matches = databaseService.getPotentialMatches(userId, preferences);
```

#### **StorageService**
```dart
// Upload d'images
String? imageUrl = await StorageService.uploadProfilePhoto(imageFile);
```

### **Utilisation Quotidienne**

#### **1. Initialisation**
```dart
// Dans main.dart
await FirebaseService.instance.initialize();
```

#### **2. Authentification**
```dart
// Écouter les changements d'état
AuthServiceFirebase.instance.authStateChanges.listen((user) {
  if (user != null) {
    // Utilisateur connecté
  } else {
    // Utilisateur déconnecté
  }
});
```

#### **3. Base de données**
```dart
// Obtenir les données utilisateur
Map<String, dynamic>? userData = await authService.getUserData(user.uid);

// Mettre à jour le profil
await authService.updateProfile(
  username: 'Nouveau nom',
  bio: 'Nouvelle bio',
);
```

### **Tests**

#### **Tests Unitaires**
```bash
flutter test test/unit/firebase_service_test.dart
```

#### **Tests d'Intégration**
```bash
flutter test integration_test/firebase_integration_test.dart
```

### **Déploiement**

#### **1. Déployer les règles Firestore**
```bash
firebase deploy --only firestore:rules
```

#### **2. Déployer les règles Storage**
```bash
firebase deploy --only storage
```

#### **3. Déployer l'application web**
```bash
firebase deploy --only hosting
```

### **Monitoring**

#### **Console Firebase**
- **Authentication**: https://console.firebase.google.com/project/jtm-dev/authentication
- **Firestore**: https://console.firebase.google.com/project/jtm-dev/firestore
- **Storage**: https://console.firebase.google.com/project/jtm-dev/storage
- **Hosting**: https://console.firebase.google.com/project/jtm-dev/hosting

### **Sécurité**

#### **Bonnes Pratiques**
- ✅ **Valider les données** côté client et serveur
- ✅ **Utiliser les règles de sécurité** Firestore
- ✅ **Nettoyer les uploads temporaires**
- ✅ **Limiter la taille des fichiers**
- ✅ **Utiliser des indexes** pour les requêtes complexes

### **Support**

#### **Problèmes Communs**
1. **Initialisation Firebase**: Vérifiez les options dans `firebase_options.dart`
2. **Permissions**: Assurez-vous que l'utilisateur est connecté
3. **Règles**: Testez les règles dans la console Firebase avant déploiement
4. **Stockage**: Vérifiez les quotas et la taille des fichiers

---

**🔥 Votre application JTM est maintenant entièrement intégrée avec Firebase !**
