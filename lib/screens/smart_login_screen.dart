import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'smart_registration_screen.dart';
import 'home_screen.dart';

class SmartRegistrationService {
  static Future<LoginResult> loginUser({required String email, required String password}) async {
    try {
      if (email.trim().isEmpty || password.isEmpty) {
        return LoginResult.failure('Veuillez remplir tous les champs');
      }

      // Simulate successful login for demo
      final user = UserModel(
        id: 'demo_user',
        email: email,
        name: 'Demo User',
        age: 25,
        gender: 'autre',
        phoneNumber: null,
        photos: const [],
        bio: '',
        interests: const [],
        location: null,
        preferences: const {},
        isVerified: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      return LoginResult.success(user, 'Connexion réussie !');
    } catch (e) {
      return LoginResult.failure('Erreur: ${e.toString()}');
    }
  }

  static Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
  }) async {
    try {
      if (email.trim().isEmpty || password.isEmpty || name.trim().isEmpty) {
        return RegistrationResult.failure('Veuillez remplir tous les champs obligatoires');
      }

      if (age < 18 || age > 120) {
        return RegistrationResult.failure('Age invalide');
      }

      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(email)) {
        return RegistrationResult.failure('Email invalide');
      }

      final user = UserModel(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        photos: const [],
        bio: '',
        interests: const [],
        location: null,
        preferences: const {},
        isVerified: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      return RegistrationResult.success(user, 'Inscription réussie !');
    } catch (e) {
      return RegistrationResult.failure('Erreur: ${e.toString()}');
    }
  }
}

class RegistrationResult {
  final bool success;
  final UserModel? user;
  final String message;

  RegistrationResult.success(this.user, this.message) : success = true;
  RegistrationResult.failure(this.message) : success = false, user = null;
}

class LoginResult {
  final bool success;
  final UserModel? user;
  final String message;

  LoginResult.success(this.user, this.message) : success = true;
  LoginResult.failure(this.message) : success = false, user = null;
}

class SmartLoginScreen extends StatefulWidget {
  const SmartLoginScreen({super.key});

  @override
  State<SmartLoginScreen> createState() => _SmartLoginScreenState();
}

class _SmartLoginScreenState extends State<SmartLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JTM - Connexion Firebase'),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 30),

            // Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login button
            SizedBox(
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
                    : const Text('Se connecter', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),

            // Register button
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushReplacement(MaterialPageRoute(builder: (_) => SmartRegistrationScreen()));
              },
              child: Text(
                'Pas de compte ? Créez-en ici',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await SmartRegistrationService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Colors.green));
          // Redirection vers la page principale après connexion réussie
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message), backgroundColor: Colors.red));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
