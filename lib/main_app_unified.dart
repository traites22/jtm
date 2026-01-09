import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/unified_match_service.dart';
import 'services/auth_service.dart';
import 'screens/unified_swipe_screen.dart';
import 'screens/unified_chat_screen.dart';
import 'screens/unified_matches_screen.dart';
import 'screens/unified_registration_screen.dart';
import 'screens/unified_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser les services unifiés
  await UnifiedMatchService.initialize();

  runApp(const JTMApp());
}

class JTMApp extends StatelessWidget {
  const JTMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JTM - Juste Pour Moi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const UnifiedLoginScreen(),
        '/register': (context) => const UnifiedRegistrationScreen(),
        '/swipe': (context) => const UnifiedSwipeScreen(),
        '/matches': (context) => const UnifiedMatchesScreen(),
        '/chat': (context) => const UnifiedChatPlaceholder(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const UnifiedSwipeScreen(); // Utilisateur connecté
        } else {
          return const UnifiedLoginScreen(); // Utilisateur non connecté
        }
      },
    );
  }
}

// Placeholder pour l'écran de chat (recevra les arguments via route)
class UnifiedChatPlaceholder extends StatelessWidget {
  const UnifiedChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupérer les arguments passés à la route
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      return UnifiedChatScreen(
        matchId: args['matchId'] as String,
        userName: args['userName'] as String,
      );
    }

    // Si pas d'arguments, retourner à l'écran précédent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
    });

    return const Scaffold(body: Center(child: Text('Erreur: Paramètres de chat manquants')));
  }
}
