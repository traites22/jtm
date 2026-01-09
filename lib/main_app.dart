import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/theme_service.dart';
import '../theme/app_theme.dart';
import 'screens/pure_firebase_login_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _listenToThemeChanges();
  }

  void _loadTheme() async {
    await ThemeService.init();
    setState(() {
      _themeMode = ThemeService.currentTheme;
    });
  }

  void _listenToThemeChanges() {
    // Écouter les changements de thème
    Hive.box('themeBox').watch(key: 'selectedTheme').listen((event) {
      if (event.value != null) {
        setState(() {
          _themeMode = ThemeMode.values[event.value];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JTM',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: const PureFirebaseLoginScreen(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
