# JTM Deployment Guide

## 🚀 Firebase Hosting Deployment

### Prerequisites

1. **Install Firebase CLI**
   ```bash
   # Install Node.js first
   # Then install Firebase CLI
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

### Web Deployment

#### 1. Build for Web
```bash
flutter build web --release
```

#### 2. Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

#### 3. Access Your App
Your app will be available at: `https://jtm-dev.web.app`

## 🔑 API Configuration Guide

### Google Sign-In Setup

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select project: `jtm-dev`

2. **Enable Google Sign-In API**
   - Go to "APIs & Services" > "Library"
   - Search for "Google Sign-In API"
   - Click "Enable"

3. **Create OAuth 2.0 Credentials**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Select "Web application"
   - Add authorized redirect URI: `https://jtm-dev.web.app`
   - Copy Client ID

4. **Update Environment Variables**
   Create `.env` file:
   ```env
   GOOGLE_CLIENT_ID=your_google_client_id_here
   ```

### Facebook Login Setup

1. **Create Facebook App**
   - Visit: https://developers.facebook.com/
   - Create new app: "JTM Dating App"
   - Select "Facebook Login" product

2. **Configure Facebook Login**
   - Add platform: "Web"
   - Site URL: `https://jtm-dev.web.app`
   - Valid OAuth Redirect URIs: `https://jtm-dev.web.app`
   - Copy App ID

3. **Update Environment Variables**
   ```env
   FACEBOOK_APP_ID=your_facebook_app_id_here
   ```

## 📱 Mobile Testing Guide

### Android Testing

#### 1. Build APK
```bash
flutter build apk --release
```

#### 2. Install on Device
```bash
# Connect device via USB
# Enable USB debugging
# Run:
flutter install
```

#### 3. Test Features
- ✅ Authentication (email, Google, Facebook)
- ✅ Profile creation and editing
- ✅ Location services
- ✅ Notifications
- ✅ Matching system
- ✅ Chat functionality

### iOS Testing

#### 1. Build iOS App
```bash
flutter build ios --release
```

#### 2. Install on Device
- Open Xcode project: `ios/Runner.xcworkspace`
- Select your device
- Click "Run"

## 📊 Performance Monitoring

### Firebase Performance Setup

1. **Enable Performance Monitoring**
   ```bash
   firebase deploy --only functions
   ```

2. **Monitor Key Metrics**
   - App startup time
   - Screen load time
   - Network request latency
   - Memory usage
   - CPU usage

### Flutter Performance Tools

1. **Flutter Inspector**
   ```bash
   flutter run --profile
   ```

2. **Performance Overlay**
   ```bash
   flutter run --profile --trace-startup
   ```

3. **Memory Profiling**
   ```bash
   flutter run --profile --trace-startup --profile-memory
   ```

## 🔧 Configuration Files

### Environment Variables (.env)
```env
ENVIRONMENT=development
GOOGLE_CLIENT_ID=your_google_client_id
FACEBOOK_APP_ID=your_facebook_app_id
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_APP_ID=1:401147120494:android:6ab47f840302b796a10f7f
FIREBASE_PROJECT_ID=jtm-dev
FIREBASE_STORAGE_BUCKET=jtm-dev.firebasestorage.app
```

### Firebase Configuration (firebase.json)
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{"source": "**", "destination": "/index.html"}],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{"key": "Cache-Control", "value": "max-age=31536000"}]
      },
      {
        "source": "**",
        "headers": [
          {"key": "X-Content-Type-Options", "value": "nosniff"},
          {"key": "X-Frame-Options", "value": "DENY"},
          {"key": "X-XSS-Protection", "value": "1; mode=block"}
        ]
      }
    ]
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions"
  }
}
```

## 🧪 Testing Checklist

### Before Deployment
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Performance tests pass
- [ ] Security audit complete
- [ ] Environment variables set
- [ ] API keys configured

### After Deployment
- [ ] Web app loads correctly
- [ ] Authentication works
- [ ] Firebase services connected
- [ ] Notifications working
- [ ] Performance monitoring active
- [ ] Error tracking enabled

## 📈 Analytics Setup

### Firebase Analytics
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// Initialize analytics
FirebaseAnalytics analytics = FirebaseAnalytics.instance;

// Log events
analytics.logEvent(
  name: 'user_registration',
  parameters: {
    'method': 'email',
    'age_group': '18-25',
  },
);
```

### Custom Events
- `user_registration` - User signs up
- `user_login` - User logs in
- `profile_created` - User completes profile
- `match_created` - New match formed
- `message_sent` - Message sent
- `profile_view` - Profile viewed

## 🔒 Security Checklist

### Authentication
- [ ] Email/password validation
- [ ] Social authentication secure
- [ ] Session management
- [ ] Token refresh working
- [ ] Rate limiting enabled

### Data Protection
- [ ] Firestore rules secure
- [ ] Storage rules secure
- [ ] Input validation
- [ ] SQL injection protection
- [ ] XSS protection

### Privacy Compliance
- [ ] GDPR consent
- [ ] Data deletion option
- [ ] Privacy policy accessible
- [ ] Cookie policy implemented
- [ ] User data export

## 🚀 CI/CD Integration

### GitHub Actions
```yaml
name: Deploy to Firebase Hosting
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.38.5'
    - run: flutter pub get
    - run: flutter build web --release
    - uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.FIREBASE_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        channelId: live
        projectId: jtm-dev
```

## 📱 Device Testing Matrix

### Android
- [ ] Android 8.0+ (API 26+)
- [ ] Different screen sizes
- [ ] Different network conditions
- [ ] Low-end devices
- [ ] High-end devices

### iOS
- [ ] iOS 13.0+
- [ ] iPhone and iPad
- [ ] Different screen sizes
- [ ] Different network conditions
- [ ] Low-end devices

### Web
- [ ] Chrome (latest)
- [ ] Safari (latest)
- [ ] Firefox (latest)
- [ ] Edge (latest)
- [ ] Mobile browsers

## 🔧 Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean build cache
flutter clean
flutter pub get
flutter build web --release
```

#### Firebase Connection Issues
```bash
# Check Firebase configuration
firebase projects:list
firebase use jtm-dev
```

#### Authentication Issues
```bash
# Check Firebase Auth settings
firebase auth:list
```

#### Performance Issues
```bash
# Check performance metrics
firebase performance:list
```

## 📞 Support

### Documentation
- [Firebase Hosting Guide](https://firebase.google.com/docs/hosting)
- [Flutter Web Deployment](https://flutter.dev/docs/deployment/web)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Google Sign-In](https://developers.google.com/identity/sign-in/web/)
- [Facebook Login](https://developers.facebook.com/docs/facebook-login/)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Firebase Community](https://firebase.google.com/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter-firebase)

---

## 🎉 Ready for Production!

Your JTM application is now fully configured and ready for production deployment with:
- ✅ Firebase Hosting
- ✅ Social Authentication
- ✅ Enhanced Notifications
- ✅ Location Services
- ✅ Cloud Functions
- ✅ Performance Monitoring
- ✅ Security Best Practices
