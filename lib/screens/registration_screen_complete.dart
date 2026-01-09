import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home_screen.dart';

class RegistrationScreenComplete extends StatefulWidget {
  const RegistrationScreenComplete({super.key});

  @override
  State<RegistrationScreenComplete> createState() => _RegistrationScreenCompleteState();
}

class _RegistrationScreenCompleteState extends State<RegistrationScreenComplete> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();

  bool _isLoading = false;
  String _selectedGender = 'Homme';
  String _lookingFor = 'Femme';
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Créer le profil utilisateur
      final userProfile = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'gender': _selectedGender,
        'lookingFor': _lookingFor,
        'bio': _bioController.text.trim(),
        'interests': _interestsController.text.trim().split(',').map((s) => s.trim()).toList(),
        'notifications': _notificationsEnabled,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'isVerified': false,
        'likes': 0,
        'matches': 0,
        'photos': [],
        'location': 'Non spécifiée',
        'job': 'Non spécifié',
      };

      // Sauvegarder dans Hive
      final usersBox = Hive.box('usersBox');
      await usersBox.put(userProfile['id'], userProfile);

      // Sauvegarder comme utilisateur actuel
      final profileBox = Hive.box('profileBox');
      await profileBox.put('currentUser', userProfile);

      // Initialiser les données utilisateur
      await Hive.openBox('profile_${userProfile['id']}');
      await Hive.openBox('likes_${userProfile['id']}');
      await Hive.openBox('matches_${userProfile['id']}');

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inscription réussie ! Bienvenue sur JTM ❤️'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Naviguer vers l'écran principal
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'inscription: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'JTM',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Créez votre profil de rencontre',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Veuillez entrer votre nom (min 2 caractères)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Âge
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Âge',
                    prefixIcon: const Icon(Icons.cake),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre âge';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 18 || age > 100) {
                      return 'Âge invalide (18-100 ans)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Genre
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Je suis',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  items: ['Homme', 'Femme', 'Autre'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGender = value!);
                  },
                ),

                const SizedBox(height: 16),

                // Recherche
                DropdownButtonFormField<String>(
                  value: _lookingFor,
                  decoration: InputDecoration(
                    labelText: 'Je cherche',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  items: ['Homme', 'Femme', 'Les deux'].map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _lookingFor = value!);
                  },
                ),

                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Bio (description)',
                    prefixIcon: const Icon(Icons.edit),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    hintText: 'Décrivez-vous en quelques mots...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Veuillez entrer une description (min 10 caractères)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Intérêts
                TextFormField(
                  controller: _interestsController,
                  decoration: InputDecoration(
                    labelText: 'Centres d\'intérêt',
                    prefixIcon: const Icon(Icons.star),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    hintText: 'Ex: Musique, Sport, Cinéma, Voyage...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer au moins un centre d\'intérêt';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Notifications
                SwitchListTile(
                  title: const Text('Activer les notifications'),
                  subtitle: const Text('Recevez des alertes pour nouveaux matches et messages'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(height: 32),

                // Bouton d'inscription
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'S\'inscrire',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Lien de connexion
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Déjà un compte ? Se connecter',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
