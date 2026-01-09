# JTM — Guide de développement

## Prérequis
- Flutter SDK installé et dans le PATH
- Android SDK + command-line tools installés
- Java / JDK installé (fourni par Android Studio ou OpenJDK)
- VS Code (recommandé) + extensions **Dart** et **Flutter**

## Démarrer en local
1. Ouvrir le dossier `C:\JTM` dans VS Code
2. Récupérer les dépendances : `flutter pub get`
3. Lancer l'application : `flutter run` (choisir un device ou `-d windows`)
4. Pour analyser le code : `flutter analyze`

## Tests
- `flutter test`

## Build
- Android : `flutter build apk`
- iOS : `flutter build ios` (requires macOS + Xcode; see below for push setup)
- Windows : `flutter build windows` (nécessite Visual Studio avec "Desktop development with C++")

---

### iOS — Push notifications (APNs) & Firebase setup 🔔
1. In Firebase Console, add an **iOS app** and download `GoogleService-Info.plist` — add it to `ios/Runner/` (open `ios/Runner.xcworkspace` in Xcode, drag the file into Runner and check "Add to targets: Runner").
2. In Xcode: Target **Runner → Signing & Capabilities** → add **Push Notifications** and **Background Modes** → enable **Remote notifications**.
3. Create an APNs key on Apple Developer (Certificates, Identifiers & Profiles) → Keys → + → enable **Apple Push Notifications service (APNs)** → download the `.p8`. Note the **Key ID** and your **Team ID**.
4. In Firebase Console → Project Settings → Cloud Messaging → upload the APNs **.p8** key (enter **Key ID** and **Team ID**). This lets Firebase send notifications to iOS devices.
5. In the project, `ios/Runner/Runner.entitlements` contains `aps-environment` (default: `development`). Ensure your provisioning profile supports push notifications.
6. Build and run on a real iOS device via Xcode (or `flutter run` on macOS) to allow notification permissions and retrieve the FCM token (the app stores it in `settingsBox` when available).

---

### SwiftUI — Exemple d'initialisation Firebase (Swift)
Si vous utilisez une app SwiftUI native (ou souhaitez voir l'exemple SwiftUI), ajoutez ce code au point d'entrée :

```swift
import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Configure Firebase using GoogleService-Info.plist or generated options
    FirebaseApp.configure()
    return true
  }
}

@main
struct YourApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      NavigationView {
        ContentView()
      }
    }
  }
}
```

> Note: Dans ce projet Flutter, Firebase est déjà configuré dans `ios/Runner/AppDelegate.swift` (voir `FirebaseApp.configure()`), donc vous n'avez rien à ajouter pour l'instant si vous déployez depuis Flutter.

---
> Security note: do not share your `.p8` key publicly; upload it directly in the Firebase Console or provide it to a trusted maintainer.

---

If you want me to (pick one):
- A) Add the `.p8` to Firebase (you must provide the file),
- B) Walk you through the Firebase Console upload step by step, or
- C) Prepare a short test checklist to validate push notifications on a device.

If you need CI support for iOS builds or automated tests, tell me and I'll add GitHub Actions steps.

---

Si vous avez besoin que je configure une CI (GitHub Actions) ou ajoute des scripts supplémentaires, dites-le et je m'en occupe.
