import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pure_firebase_auth_service.dart';
import '../models/auth_result.dart';
import '../models/user_model.dart';
import '../services/firebase_user_service.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String identifier;
  final bool isEmail;
  final String userId;

  const CompleteProfileScreen({
    super.key,
    required this.identifier,
    required this.isEmail,
    required this.userId,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _jobController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _interestsController = TextEditingController();

  String _selectedGender = 'homme';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _jobController.dispose();
    _descriptionController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Créer le profil complet dans Firestore
      final userModel = UserModel(
        id: widget.userId,
        email: widget.isEmail ? widget.identifier : '',
        phoneNumber: widget.isEmail ? '' : widget.identifier,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        bio: _descriptionController.text.trim(),
        interests: _interestsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        location: null, // Sera ajouté plus tard avec géolocalisation
        photos: const [], // Sera ajouté plus tard avec upload
        preferences: {'city': _cityController.text.trim(), 'job': _jobController.text.trim()},
        isVerified: true, // Vérifié par email/SMS
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      final userCreated = await FirebaseUserService.createUser(userModel);

      if (userCreated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil créé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigation vers l'écran principal
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création du profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[300],
        title: const Text(
          'Compléter votre profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Titre
              Text(
                'Dites-nous en plus sur vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[700],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Ces informations aideront les autres à vous connaître',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // Nom
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Votre nom complet',
                    prefixIcon: Icon(Icons.person, color: Colors.pink[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre nom';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Âge et Genre sur la même ligne
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Âge',
                          hintText: '25',
                          prefixIcon: Icon(Icons.cake, color: Colors.pink[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Âge requis';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age < 18 || age > 100) {
                            return 'Âge entre 18 et 100';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Genre',
                          prefixIcon: Icon(Icons.wc, color: Colors.pink[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'homme', child: Text('Homme')),
                          DropdownMenuItem(value: 'femme', child: Text('Femme')),
                          DropdownMenuItem(value: 'autre', child: Text('Autre')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedGender = value!);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ville
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'Ville',
                    hintText: 'Paris',
                    prefixIcon: Icon(Icons.location_city, color: Colors.pink[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre ville';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Travail
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _jobController,
                  decoration: InputDecoration(
                    labelText: 'Travail/Profession',
                    hintText: 'Développeur, Étudiant, etc.',
                    prefixIcon: Icon(Icons.work, color: Colors.pink[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre profession';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Description complète
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Décrivez-vous, vos passions, ce que vous recherchez...',
                    prefixIcon: Icon(Icons.description, color: Colors.pink[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez vous décrire';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Centres d'intérêt
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _interestsController,
                  decoration: InputDecoration(
                    labelText: 'Centres d\'intérêt (optionnel)',
                    hintText: 'Sport, Musique, Cinéma, Lecture...',
                    prefixIcon: Icon(Icons.interests, color: Colors.pink[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Bouton de finalisation
              Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.pink[400]!, Colors.pink[600]!]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Création du profil...', style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Text(
                          'Terminer l\'inscription',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
