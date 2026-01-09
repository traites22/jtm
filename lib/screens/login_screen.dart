import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final isAvailable = await BiometricService.isBiometricAvailable();
    setState(() {
      _useBiometric = isAvailable;
    });
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() => _isLoading = true);

    try {
      final result = await BiometricService.authenticate(
        localizedReason: 'Authentification requise pour JTM',
      );

      if (result == true) {
        final storedUser = await _storage.read(key: 'user');
        if (storedUser != null && mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'authentification biométrique'),
            backgroundColor: Colors.red,
          ),
        );
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

  Future<void> _goToRegistration() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistrationScreenNew()),
    );
  }
    try {
      final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canCheck) {
        if (!mounted) return;

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

            // Verification buttons
            if (_userController.text.isNotEmpty || _pinController.text.isNotEmpty) ...[
              TextButton(
                onPressed: _isLoading ? null : _goToRegistration,
                child: const Text('S\'inscrire'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: _isLoading ? null : _goToRegistration,
                child: const Text('Renvoyer'),
              ),
            ] else ...[
              Text(
                'Entrez d\'abord email ou téléphone pour vous inscrire',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
}
