import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/theme_service.dart';
import 'account_settings_screen.dart';
import 'security_settings_screen.dart';
import 'about_screen_simple.dart';
import 'profile_settings_screen.dart';

class SettingsScreenFunctional extends StatefulWidget {
  const SettingsScreenFunctional({super.key});

  @override
  State<SettingsScreenFunctional> createState() => _SettingsScreenFunctionalState();
}

class _SettingsScreenFunctionalState extends State<SettingsScreenFunctional> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = false;
  ThemeMode _selectedTheme = ThemeMode.system;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricAvailability();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsBox = Hive.box('settingsBox');
      setState(() {
        _biometricEnabled = settingsBox.get('biometricEnabled', defaultValue: false);
        _notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);
        _locationEnabled = settingsBox.get('locationEnabled', defaultValue: false);
        _selectedTheme = ThemeService.currentTheme;
      });
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      print('Biométrie disponible: $canCheckBiometrics');
      print('Appareil supporté: $isDeviceSupported');
      print('Biométries disponibles: $availableBiometrics');

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _biometricEnabled = false;
        });
        _saveSetting('biometricEnabled', false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cet appareil ne supporte pas l\'authentification biométrique'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (availableBiometrics.isEmpty) {
        setState(() {
          _biometricEnabled = false;
        });
        _saveSetting('biometricEnabled', false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune biométrie configurée sur cet appareil'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification biométrique: $e');
      setState(() {
        _biometricEnabled = false;
      });
      _saveSetting('biometricEnabled', false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final settingsBox = Hive.box('settingsBox');
      await settingsBox.put(key, value);
    } catch (e) {
      print('Erreur lors de la sauvegarde du paramètre: $e');
    }
  }

  Future<void> _toggleBiometric() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_biometricEnabled) {
        // Désactiver la biométrie
        setState(() {
          _biometricEnabled = false;
        });
        await _saveSetting('biometricEnabled', false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biométrie désactivée'), backgroundColor: Colors.orange),
          );
        }
      } else {
        // Activer la biométrie - tester d'abord
        try {
          final authenticated = await _localAuth.authenticate(
            localizedReason: 'Activez l\'authentification biométrique pour sécuriser votre compte',
            options: const AuthenticationOptions(useErrorDialogs: true, stickyAuth: true),
          );

          if (authenticated) {
            setState(() {
              _biometricEnabled = true;
            });
            await _saveSetting('biometricEnabled', true);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biométrie activée avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Échec de l\'authentification biométrique'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } on PlatformException catch (e) {
          String errorMessage = 'Erreur biométrique';
          switch (e.code) {
            case 'NotAvailable':
              errorMessage = 'La biométrie n\'est pas disponible sur cet appareil';
              break;
            case 'NotEnrolled':
              errorMessage =
                  'Aucune biométrie n\'est configurée. Veuillez d\'abord configurer votre empreinte ou visage dans les paramètres système.';
              break;
            case 'LockedOut':
              errorMessage = 'Trop de tentatives. Veuillez réessayer plus tard.';
              break;
            case 'PermanentlyLockedOut':
              errorMessage = 'Biométrie bloquée. Veuillez utiliser votre mot de passe.';
              break;
            case 'UserCanceled':
              errorMessage = 'Authentification annulée par l\'utilisateur';
              break;
            case 'SystemCancel':
              errorMessage = 'Authentification annulée par le système';
              break;
            default:
              errorMessage = 'Erreur: ${e.message}';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur inattendue: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeTheme(ThemeMode theme) async {
    setState(() {
      _selectedTheme = theme;
    });

    await ThemeService.setTheme(theme);
    await _saveSetting('theme', theme.index);

    // Forcer le rebuild de l'app
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thème changé: ${theme.name}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section Compte
          _buildSectionHeader('Compte'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              title: const Text('Profil'),
              subtitle: const Text('Modifier vos informations personnelles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
              title: const Text('Compte'),
              subtitle: const Text('Gestion du compte et sécurité'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AccountSettingsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
              title: const Text('Sécurité'),
              subtitle: const Text('Mot de passe et authentification'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => const SecuritySettingsScreen()));
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Section Apparence
          _buildSectionHeader('Apparence'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
              title: const Text('Thème'),
              subtitle: Text(_selectedTheme.name),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: _selectedTheme,
              onChanged: (value) => _changeTheme(value!),
              title: const Text('Clair'),
              secondary: Icon(Icons.light_mode, color: Theme.of(context).colorScheme.primary),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: _selectedTheme,
              onChanged: (value) => _changeTheme(value!),
              title: const Text('Sombre'),
              secondary: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: _selectedTheme,
              onChanged: (value) => _changeTheme(value!),
              title: const Text('Suivre le système'),
              secondary: Icon(
                Icons.settings_system_daydream,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Section Sécurité
          _buildSectionHeader('Sécurité'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
              title: const Text('Authentification biométrique'),
              subtitle: const Text('Utiliser votre empreinte ou visage pour vous connecter'),
              value: _biometricEnabled,
              onChanged: _isLoading ? null : (value) => _toggleBiometric(),
            ),
          ]),

          const SizedBox(height: 24),

          // Section Notifications
          _buildSectionHeader('Notifications'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
              title: const Text('Notifications push'),
              subtitle: const Text('Recevoir des alertes pour les nouveaux matches'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSetting('notificationsEnabled', value);
              },
            ),
            SwitchListTile(
              secondary: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              title: const Text('Notifications par email'),
              subtitle: const Text('Recevoir des résumés hebdomadaires'),
              value: false, // À implémenter
              onChanged: (value) {
                // À implémenter
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Section Confidentialité
          _buildSectionHeader('Confidentialité'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
              title: const Text('Localisation'),
              subtitle: const Text('Partager votre position pour des matches proches'),
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
                _saveSetting('locationEnabled', value);
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
              title: const Text('Visibilité du profil'),
              subtitle: const Text('Qui peut voir votre profil'),
              trailing: const Text('Tout le monde'),
              onTap: () {
                // Ouvrir les options de visibilité
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Section À propos
          _buildSectionHeader('À propos'),
          _buildSettingsCard([
            ListTile(
              leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              title: const Text('À propos de JTM'),
              subtitle: const Text('Découvrez l\'histoire et la mission'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => const AboutScreenSimple()));
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Bouton de déconnexion
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      try {
                        final profileBox = Hive.box('profileBox');
                        await profileBox.clear();

                        if (mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la déconnexion: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}
