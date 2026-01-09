import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _pinEnabled = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final settingsBox = Hive.box('settingsBox');

      setState(() {
        _biometricEnabled = settingsBox.get('biometricEnabled', defaultValue: false);
        _twoFactorEnabled = settingsBox.get('twoFactorEnabled', defaultValue: false);
        _pinEnabled = settingsBox.get('pinEnabled', defaultValue: false);
      });
    } catch (e) {
      print('Erreur lors du chargement des paramètres de sécurité: $e');
    }
  }

  Future<void> _saveSecuritySetting(String key, dynamic value) async {
    try {
      final settingsBox = Hive.box('settingsBox');
      await settingsBox.put(key, value);
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileBox = Hive.box('profileBox');
      final currentUser = Map<String, dynamic>.from(profileBox.get('currentUser') ?? {});

      // Vérifier le mot de passe actuel (simplifié pour le prototype)
      if (currentUser['password'] == _currentPasswordController.text) {
        currentUser['password'] = _newPasswordController.text;
        await profileBox.put('currentUser', currentUser);

        // Mettre à jour dans usersBox
        final usersBox = Hive.box('usersBox');
        await usersBox.put(currentUser['id'], currentUser);

        _clearPasswordFields();
        _showSuccess('Mot de passe changé avec succès');
      } else {
        _showError('Mot de passe actuel incorrect');
      }
    } catch (e) {
      _showError('Erreur lors du changement de mot de passe: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_biometricEnabled) {
        // Désactiver
        setState(() => _biometricEnabled = false);
        await _saveSecuritySetting('biometricEnabled', false);
        _showSuccess('Biométrie désactivée');
      } else {
        // Activer - tester d'abord
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Activez l\'authentification biométrique',
          options: const AuthenticationOptions(useErrorDialogs: true, stickyAuth: true),
        );

        if (authenticated) {
          setState(() => _biometricEnabled = true);
          await _saveSecuritySetting('biometricEnabled', true);
          _showSuccess('Biométrie activée avec succès');
        } else {
          _showError('Échec de l\'authentification biométrique');
        }
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupPin() async {
    if (_pinController.text.length != 4) {
      _showError('Le PIN doit contenir exactement 4 chiffres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _secureStorage.write(key: 'user_pin', value: _pinController.text);
      setState(() {
        _pinEnabled = true;
      });
      await _saveSecuritySetting('pinEnabled', true);
      _pinController.clear();
      _showSuccess('PIN configuré avec succès');
    } catch (e) {
      _showError('Erreur lors de la configuration du PIN: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTwoFactor() async {
    setState(() => _twoFactorEnabled = !_twoFactorEnabled);
    await _saveSecuritySetting('twoFactorEnabled', _twoFactorEnabled);

    _showSuccess(
      _twoFactorEnabled
          ? 'Authentification à deux facteurs activée'
          : 'Authentification à deux facteurs désactivée',
    );
  }

  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Sécurité'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Changement de mot de passe
            _buildSectionHeader('Mot de passe'),
            _buildSettingsCard([
              TextFormField(
                controller: _currentPasswordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Changer le mot de passe'),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Méthodes d'authentification
            _buildSectionHeader('Méthodes d\'authentification'),
            _buildSettingsCard([
              SwitchListTile(
                secondary: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
                title: const Text('Authentification biométrique'),
                subtitle: const Text('Utiliser votre empreinte ou visage'),
                value: _biometricEnabled,
                onChanged: _isLoading ? null : (value) => _toggleBiometric(),
              ),
              const Divider(),
              SwitchListTile(
                secondary: Icon(Icons.pin, color: Theme.of(context).colorScheme.primary),
                title: const Text('Code PIN'),
                subtitle: Text(
                  _pinEnabled ? 'PIN configuré' : 'Configurer un code PIN à 4 chiffres',
                ),
                value: _pinEnabled,
                onChanged: (value) {
                  if (!value) {
                    setState(() => _pinEnabled = false);
                    _saveSecuritySetting('pinEnabled', false);
                    _secureStorage.delete(key: 'user_pin');
                  }
                },
              ),
              if (!_pinEnabled) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nouveau code PIN (4 chiffres)',
                    prefixIcon: const Icon(Icons.pin),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setupPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Configurer le PIN'),
                  ),
                ),
              ],
              const Divider(),
              SwitchListTile(
                secondary: Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                title: const Text('Authentification à deux facteurs'),
                subtitle: const Text('Ajouter une couche de sécurité supplémentaire'),
                value: _twoFactorEnabled,
                onChanged: (value) => _toggleTwoFactor(),
              ),
            ]),

            const SizedBox(height: 24),

            // Session active
            _buildSectionHeader('Session'),
            _buildSettingsCard([
              ListTile(
                leading: Icon(Icons.devices, color: Theme.of(context).colorScheme.primary),
                title: const Text('Appareils connectés'),
                subtitle: const Text('1 appareil actif'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showError('Fonctionnalité bientôt disponible');
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                title: const Text('Historique des connexions'),
                subtitle: const Text('Voir les activités récentes'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showError('Fonctionnalité bientôt disponible');
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Actions de sécurité
            _buildSectionHeader('Actions de sécurité'),
            _buildSettingsCard([
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange),
                title: const Text('Déconnecter tous les appareils'),
                subtitle: const Text('Forcer la déconnexion sur tous les appareils'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnecter tous les appareils'),
                      content: const Text(
                        'Êtes-vous sûr de vouloir déconnecter tous les appareils ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Déconnecter'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    _showSuccess('Tous les appareils seront déconnectés');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Réinitialiser la sécurité'),
                subtitle: const Text('Réinitialiser tous les paramètres de sécurité'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Réinitialiser la sécurité'),
                      content: const Text(
                        'Cette action réinitialisera tous vos paramètres de sécurité. Vous devrez les reconfigurer.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Réinitialiser'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      final settingsBox = Hive.box('settingsBox');
                      await settingsBox.clear();
                      await _secureStorage.deleteAll();

                      setState(() {
                        _biometricEnabled = false;
                        _twoFactorEnabled = false;
                        _pinEnabled = false;
                      });

                      _showSuccess('Paramètres de sécurité réinitialisés');
                    } catch (e) {
                      _showError('Erreur lors de la réinitialisation: $e');
                    }
                  }
                },
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}
