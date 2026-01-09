import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'app_theme.dart';

class ThemeService {
  static const String _themeBox = 'themeBox';
  static const String _themeKey = 'selectedTheme';

  static ThemeMode _currentTheme = ThemeMode.light;

  // Initialiser le service
  static Future<void> init() async {
    try {
      final box = Hive.box(_themeBox);
      final savedTheme = box.get(_themeKey);

      if (savedTheme != null) {
        _currentTheme = ThemeMode.values[savedTheme];
      }
    } catch (e) {
      // Utiliser le thème par défaut en cas d'erreur
      _currentTheme = ThemeMode.light;
    }
  }

  // Obtenir le thème actuel
  static ThemeMode get currentTheme => _currentTheme;

  // Changer le thème
  static Future<void> setTheme(ThemeMode theme) async {
    _currentTheme = theme;

    try {
      final box = Hive.box(_themeBox);
      await box.put(_themeKey, theme.index);
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  // Basculer entre les thèmes
  static Future<void> toggleTheme() async {
    final newTheme = _currentTheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newTheme);
  }

  // Vérifier si le thème sombre est actif
  static bool get isDarkMode => _currentTheme == ThemeMode.dark;

  // Obtenir le thème approprié
  static ThemeData getTheme(BuildContext context) {
    return _currentTheme == ThemeMode.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  // Obtenir le thème de la barre de statut
  static SystemUiOverlayStyle getStatusBarTheme() {
    if (_currentTheme == ThemeMode.dark) {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      );
    } else {
      return const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );
    }
  }

  // Obtenir les couleurs selon le thème
  static Color getBackgroundColor(BuildContext context) {
    return _currentTheme == ThemeMode.dark ? const Color(0xFF121212) : AppColors.background;
  }

  static Color getSurfaceColor(BuildContext context) {
    return _currentTheme == ThemeMode.dark ? const Color(0xFF1E1E1E) : AppColors.surface;
  }

  static Color getCardColor(BuildContext context) {
    return _currentTheme == ThemeMode.dark ? const Color(0xFF2A2A2A) : AppColors.cardBackground;
  }

  static Color getTextColor(BuildContext context) {
    return _currentTheme == ThemeMode.dark ? const Color(0xFFE0E0E0) : AppColors.onBackground;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return _currentTheme == ThemeMode.dark
        ? const Color(0xFFE0E0E0).withValues(alpha: 0.6)
        : AppColors.onBackground.withValues(alpha: 0.6);
  }

  // Obtenir le gradient approprié
  static LinearGradient getBackgroundGradient() {
    if (_currentTheme == ThemeMode.dark) {
      return const LinearGradient(
        colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return AppColors.backgroundGradient;
    }
  }

  // Obtenir le thème des messages
  static Color getMessageSentColor() {
    return _currentTheme == ThemeMode.dark
        ? const Color(0xFFD81B60) // Rose plus foncé pour le mode sombre
        : AppColors.messageSent;
  }

  static Color getMessageReceivedColor() {
    return _currentTheme == ThemeMode.dark
        ? const Color(0xFF2A2A2A) // Gris foncé pour le mode sombre
        : AppColors.messageReceived;
  }

  static Color getMessageSentTextColor() {
    return _currentTheme == ThemeMode.dark ? const Color(0xFFFFFFFF) : AppColors.messageSentText;
  }

  static Color getMessageReceivedTextColor() {
    return _currentTheme == ThemeMode.dark
        ? const Color(0xFFE0E0E0)
        : AppColors.messageReceivedText;
  }
}

// Widget pour basculer le thème
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(ThemeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        ThemeService.toggleTheme();
        // Forcer le rebuild de l'application
        (context as Element).markNeedsBuild();
      },
      tooltip: ThemeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
    );
  }
}

// Widget pour le sélecteur de thème
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      icon: const Icon(Icons.palette_outlined),
      tooltip: 'Choisir le thème',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: ThemeService.currentTheme == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('Mode clair'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: ThemeService.currentTheme == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('Mode sombre'),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.settings_system_daydream,
                color: ThemeService.currentTheme == ThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('Suivre le système'),
            ],
          ),
        ),
      ],
      onSelected: (ThemeMode theme) {
        ThemeService.setTheme(theme);
      },
    );
  }
}

// Widget pour les paramètres de thème
class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apparence', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),

        // Sélecteur de thème
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thème de l\'application', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeOption(
                        title: 'Clair',
                        icon: Icons.light_mode,
                        theme: ThemeMode.light,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOption(
                        title: 'Sombre',
                        icon: Icons.dark_mode,
                        theme: ThemeMode.dark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Options de couleur
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Couleurs d\'accentuation', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ColorOption(
                      color: AppColors.primary,
                      isSelected: true,
                      onTap: () {
                        // Implémenter le changement de couleur d'accentuation
                      },
                    ),
                    const SizedBox(width: 8),
                    _ColorOption(
                      color: AppColors.secondary,
                      isSelected: false,
                      onTap: () {
                        // Implémenter le changement de couleur d'accentuation
                      },
                    ),
                    const SizedBox(width: 8),
                    _ColorOption(
                      color: AppColors.success,
                      isSelected: false,
                      onTap: () {
                        // Implémenter le changement de couleur d'accentuation
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeMode theme;

  const _ThemeOption({super.key, required this.title, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isSelected = ThemeService.currentTheme == theme;

    return GestureDetector(
      onTap: () => ThemeService.setTheme(theme),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
