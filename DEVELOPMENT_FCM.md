# Test FCM local

Ce fichier contient les instructions pour envoyer un push de test depuis votre machine.

Scripts fournis :

- `scripts/send_fcm_test.ps1` (PowerShell) — usage : `./send_fcm_test.ps1 -ServerKey '<SERVER_KEY>' -Token '<DEVICE_TOKEN>'` ou définissez `FCM_SERVER_KEY` et `FCM_TARGET_TOKEN`.
- `scripts/send_fcm_test.sh` (bash) — usage : `./send_fcm_test.sh <SERVER_KEY> <DEVICE_TOKEN>` ou définissez `FCM_SERVER_KEY` et `FCM_TARGET_TOKEN`.

Integration test :

- `integration_test/send_fcm_integration_test.dart` utilise `FCM_SERVER_KEY` et `FCM_TARGET_TOKEN` (variables d'environnement) pour envoyer un message data-only via l'API FCM legacy. Le test vérifie que le serveur accepte la requête (code 200/201). Pour valider la réception : gardez l'app en foreground/background sur un appareil et vérifiez `Paramètres → Dernière notification` ou `adb logcat`.

Sécurité : ne partagez pas la clé serveur (SERVER_KEY) dans le dépôt. Utilisez des variables d'environnement pour les tests ou configurez des secrets dans CI.

---

## GitHub Actions

1. Dans les réglages du dépôt (Settings → Secrets and variables → Actions → New repository secret), ajoutez :
   - `FCM_SERVER_KEY` (votre clé serveur legacy FCM)
   - `FCM_TARGET_TOKEN` (un token de test de device, ou laissez vide pour manuellement exécuter)

2. Le workflow `/.github/workflows/fcm-integration.yml` est déclenché sur `push`, `pull_request` et manuellement (`workflow_dispatch`). Il exécutera les tests d'analyse + unitaires, puis le test d'intégration FCM seulement si les secrets sont présents.

3. Pour exécuter manuellement depuis l'interface GitHub : Actions → "FCM Integration Tests" → Run workflow → (optionnel) fournir les variables d'environnement.

Notes :
- La clé server FCM est sensible ; stockez-la dans les secrets et ne la commitez jamais.
- Pour valider la **livraison** des notifications, gardez l'app ouverte sur un appareil et vérifiez `Paramètres → Dernière notification` ou `adb logcat`.
## E2E Android CI

Un workflow GitHub Actions `/.github/workflows/fcm-e2e-android.yml` est fourni pour :

1. Démarrer un **émulateur Android** (API 31, google_apis_playstore) dans Actions.
2. Exécuter le test d'intégration qui **envoie** le message FCM (host): `integration_test/send_fcm_integration_test.dart`.
3. Exécuter le test **device-side** `integration_test/verify_last_notification_test.dart` pour vérifier que la clef `last_notification` est écrite dans Hive (le workflow attend et lance le test sur l'émulateur connecté).

Le job est conditionné par la présence des secrets `FCM_SERVER_KEY` et `FCM_TARGET_TOKEN`. Si vous préférez cibler un appareil réel (avec token), mettez `FCM_TARGET_TOKEN` à un token de device réel ou configurez un runner disposant du device.

---

## Firebase Test Lab (Android) — optional (device-farm)

J’ai ajouté un workflow facultatif `/.github/workflows/firebase-test-lab.yml` qui exécute :

1. Authentification avec un **service account** GCP (secret `GCP_SA_KEY` contenant le JSON de la clé),
2. Build de l’APK (`flutter build apk --debug`),
3. Exécution d’un **Robo** test dans Firebase Test Lab contre l’APK, et possibilité d’envoyer le message FCM depuis le host avant la vérification.

Secrets requis pour activer ce job :
- `GCP_SA_KEY` : contenu JSON du service account (ajouté dans GitHub Secrets),
- `FTL_PROJECT_ID` : l’ID du projet GCP/Firebase où Test Lab est activé,
- optionnel : `FCM_SERVER_KEY` et `FCM_TARGET_TOKEN` si vous voulez que le job envoie le push avant la vérification.

Configuration rapide (Google Cloud):
1. Créez/choisissez un projet GCP et activez **Firebase Test Lab** et l’API `firebase.testlab`.
2. Créez un **service account** et attribuez-lui les rôles nécessaires (au minimum `roles/firebase.testlabAdmin` ou `Editor` pour tests), puis créez/telechargez une **clé JSON**.
3. Ajoutez la clé JSON dans les secrets du dépôt (`GCP_SA_KEY`) et ajoutez `FTL_PROJECT_ID`.

Notes :
- Les résultats (logs, captures) sont accessibles via la sortie `gcloud` et le Console Firebase Test Lab.
- Ce job est conçu pour Android uniquement (comme demandé). Si vous souhaitez, je peux l’adapter pour utiliser Firebase Test Lab instrumentation tests (si vous fournissez un APK de test instrumentation) ou intégrer Firebase Test Lab pour iOS.
