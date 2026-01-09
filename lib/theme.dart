import 'package:flutter/material.dart';

class FuturisticTheme {
  // Theme keys
  static const String cyberNeonKey = 'cyber_neon';
  static const String cyberpunkKey = 'cyberpunk';
  static const String minimalGlassKey = 'minimal_glass';

  // Base colors
  static const Color neonBlue = Color(0xFF00D1FF);
  static const Color neonPink = Color(0xFFFF3EB5);
  static const Color bgDark = Color(0xFF0B0E17);
  static const Color glass = Color.fromRGBO(255, 255, 255, 0.06);

  // Cyber Neon (default)
  static ThemeData cyberNeon() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: neonBlue,
      colorScheme: base.colorScheme.copyWith(
        primary: neonBlue,
        secondary: neonPink,
        surface: bgDark,
      ),
      textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // Cyberpunk dark variant
  static ThemeData cyberpunk() {
    final base = ThemeData.dark();
    final accent = Color(0xFF7C06FF);
    final deep = Color(0xFF03040A);
    return base.copyWith(
      scaffoldBackgroundColor: deep,
      primaryColor: accent,
      colorScheme: base.colorScheme.copyWith(primary: accent, secondary: neonPink, surface: deep),
      textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Minimal glass variant
  static ThemeData minimalGlass() {
    final base = ThemeData.light();
    final pastel = Color(0xFF7BDFF6);
    final bg = Color(0xFFF6F8FA);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      primaryColor: pastel,
      colorScheme: base.colorScheme.copyWith(
        primary: pastel,
        secondary: Color(0xFFB08FFF),
        surface: Colors.white,
      ),
      textTheme: base.textTheme.apply(bodyColor: Colors.black87, displayColor: Colors.black87),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pastel,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData getTheme(String key) {
    switch (key) {
      case cyberNeonKey:
        return cyberNeon();
      case cyberpunkKey:
        return cyberpunk();
      case minimalGlassKey:
        return minimalGlass();
      default:
        return cyberNeon();
    }
  }
}
