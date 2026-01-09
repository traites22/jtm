import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import 'registration_screen_complete.dart';

class LoginScreenSimple extends StatefulWidget {
  const LoginScreenSimple({super.key});

  @override
  State<LoginScreenSimple> createState() => _LoginScreenSimpleState();
}

class _LoginScreenSimpleState extends State<LoginScreenSimple> {
  final _storage = const FlutterSecureStorage();
  final _userController = TextEditingController();
  final _pinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _useBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _useBiometric = canCheckBiometrics && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      print('Erreur vérification biométrie: $e');
      setState(() {
        _useBiometric = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() => _isLoading = true);

    try {
      bool authenticated = false;

      // Vérifier la disponibilité de la biométrie
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La biométrie n\'est pas disponible sur cet appareil'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Authentification biométrique
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentification requise pour JTM',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: false,
        ),
      );

      if (authenticated) {
        final storedUser = await _storage.read(key: 'user');
        if (storedUser != null && mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      print('Erreur biométrie: $e'); // Debug
      if (mounted) {
        String message = 'Échec de l\'authentification biométrique';
        if (e.toString().contains('NotEnrolled')) {
          message = 'Aucune biométrie n\'est configurée sur cet appareil';
        } else if (e.toString().contains('LockedOut')) {
          message = 'Trop de tentatives. Réessayez plus tard';
        } else if (e.toString().contains('NotAvailable')) {
          message = 'La biométrie n\'est pas disponible';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    final user = _userController.text.trim();
    final pin = _pinController.text.trim();
    final storedUser = await _storage.read(key: 'user');
    final storedPin = await _storage.read(key: 'pin');

    if (storedUser == null || storedPin == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun compte trouvé. Enregistrez-vous d\'abord.')),
      );
      return;
    }

    if (user == storedUser && pin == storedPin) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Identifiants incorrects')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JTM - Connexion'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 40),

            // Biometric authentication button
            if (_useBiometric)
              Container(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fingerprint, size: 24),
                            SizedBox(width: 12),
                            Text('Authentification biométrique'),
                          ],
                        ),
                ),
              ),
            if (_useBiometric) const SizedBox(height: 20),

            // Manual login form
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Code PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            // Login button
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Se connecter'),
              ),
            ),
            const SizedBox(height: 16),

            // Register button
            Container(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _goToRegistration,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Créer un compte'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'L\'authentification est locale pour ce prototype. Vous pouvez aussi utiliser la biométrie si disponible.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToRegistration() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegistrationScreenComplete()));
  }
}
