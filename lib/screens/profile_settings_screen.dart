import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pure_firebase_auth_service.dart';
import '../models/user_model.dart';
import '../services/firebase_user_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _jobController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _interestsController = TextEditingController();

  String _selectedGender = 'homme';
  bool _isLoading = false;
  UserModel? _currentUser;
  List<String> _userPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

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

  Future<void> _loadUserProfile() async {
    try {
      final user = await PureFirebaseAuthService.getCurrentUserProfile();
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
          _userPhotos = user?.photos ?? [];
          _nameController.text = user?.name ?? '';
          _ageController.text = user?.age?.toString() ?? '';
          _selectedGender = user?.gender ?? 'homme';
          _cityController.text = user?.preferences?['city'] ?? '';
          _jobController.text = user?.preferences?['job'] ?? '';
          _descriptionController.text = user?.bio ?? '';
          _interestsController.text = user?.interests?.join(', ') ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement profil: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = UserModel(
        id: _currentUser?.id ?? '',
        email: _currentUser?.email ?? '',
        phoneNumber: _currentUser?.phoneNumber ?? '',
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        bio: _descriptionController.text.trim(),
        interests: _interestsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        location: _currentUser?.location,
        photos: _userPhotos,
        preferences: {'city': _cityController.text.trim(), 'job': _jobController.text.trim()},
        isVerified: _currentUser?.isVerified ?? false,
        createdAt: _currentUser?.createdAt ?? DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      final success = await FirebaseUserService.updateUser(updatedUser);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour du profil'),
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

  Future<void> _addPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Simuler l'upload - dans la vraie version, utilisez Firebase Storage
        setState(() {
          _userPhotos.add(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo ajoutée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ajout photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _userPhotos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[300],
        title: const Text(
          'Modifier mon profil',
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
              // Section photos
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Photos actuelles
                    if (_userPhotos.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _userPhotos.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.pink[200]!),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      _userPhotos[index],
                                      width: 98,
                                      height: 98,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.person, color: Colors.grey[400]),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Bouton ajouter photo
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addPhoto,
                        icon: Icon(Icons.add_photo_alternate, color: Colors.pink[600]),
                        label: Text('Ajouter une photo', style: TextStyle(color: Colors.pink[600])),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.pink[600]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Informations de base
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  children: [
                    Text(
                      'Informations de base',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person, color: Colors.pink[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Âge et Genre
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Âge',
                              prefixIcon: Icon(Icons.cake, color: Colors.pink[400]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Genre',
                              prefixIcon: Icon(Icons.wc, color: Colors.pink[400]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Ville
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: Icon(Icons.location_city, color: Colors.pink[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre ville';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Travail
                    TextFormField(
                      controller: _jobController,
                      decoration: InputDecoration(
                        labelText: 'Travail/Profession',
                        prefixIcon: Icon(Icons.work, color: Colors.pink[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer votre profession';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description et intérêts
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  children: [
                    Text(
                      'À propos de moi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[700],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décrivez-vous, vos passions, ce que vous recherchez...',
                        prefixIcon: Icon(Icons.description, color: Colors.pink[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez vous décrire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Centres d'intérêt
                    TextFormField(
                      controller: _interestsController,
                      decoration: InputDecoration(
                        labelText: 'Centres d\'intérêt',
                        hintText: 'Sport, Musique, Cinéma, Lecture...',
                        prefixIcon: Icon(Icons.interests, color: Colors.pink[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Bouton de sauvegarde
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
                  onPressed: _isLoading ? null : _updateProfile,
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
                            Text('Mise à jour...', style: TextStyle(color: Colors.white)),
                          ],
                        )
                      : const Text(
                          'Enregistrer les modifications',
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
