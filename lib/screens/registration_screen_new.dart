import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/verification_service_simple.dart';

class RegistrationScreenNew extends StatefulWidget {
  const RegistrationScreenNew({super.key});

  @override
  State<RegistrationScreenNew> createState() => _RegistrationScreenNewState();
}

class _RegistrationScreenNewState extends State<RegistrationScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.length < 10) {
                    return 'Veuillez entrer un numéro valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.length < 2) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Âge
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Âge',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.tryParse(value)! < 18 ||
                      int.tryParse(value)! > 120) {
                    return 'Veuillez entrer un âge valide (18-120 ans)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Boutons de vérification
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isEmailVerified ? null : _verifyEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Vérifier email'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isPhoneVerified ? null : _verifyPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Vérifier téléphone'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bouton d'inscription
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('S\'inscrire'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await VerificationService.sendVerificationCode(
        target: _emailController.text.trim(),
        type: VerificationType.email,
        email: _emailController.text.trim(),
      );

      if (success) {
        setState(() {
          _isEmailVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email vérifié avec succès !'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Code invalide'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la vérification: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyPhone() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await VerificationService.verifyCode(
        target: _phoneController.text.trim(),
        code: '654321', // Simulation d'un code valide
      );

      if (success) {
        setState(() {
          _isPhoneVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Téléphone vérifié avec succès !'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Code invalide'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la vérification: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simuler l'inscription (dans une vraie app, sauvegarder dans Hive)
      final userData = {
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'password': _passwordController.text,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isVerified': _isEmailVerified || _isPhoneVerified,
      };

      final profileBox = Hive.box('profileBox');
      await profileBox.put('user', userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inscription réussie !'), backgroundColor: Colors.green),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/profile');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'inscription: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
