import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../widgets/photo_carousel.dart';
import '../widgets/interest_tags.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobController = TextEditingController();
  final _educationController = TextEditingController();

  String _selectedGender = 'autre';
  String? _selectedLookingFor;
  List<String> _photos = [];
  List<String> _interests = [];

  UserModel? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _currentProfile = ProfileService.getProfile();
    if (_currentProfile != null) {
      _nameController.text = _currentProfile!.name;
      _ageController.text = _currentProfile!.age.toString();
      _bioController.text = _currentProfile!.bio;
      _locationController.text = _currentProfile!.location ?? '';
      _jobController.text = _currentProfile!.job ?? '';
      _educationController.text = _currentProfile!.education ?? '';
      _selectedGender = _currentProfile!.gender;
      _selectedLookingFor = _currentProfile!.lookingFor;
      _photos = List<String>.from(_currentProfile!.photos);
      _interests = List<String>.from(_currentProfile!.interests);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _ageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nom et âge sont obligatoires')));
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 18 || age > 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Âge invalide (doit être entre 18 et 100)')));
      return;
    }

    final updatedProfile = UserModel(
      id: _currentProfile?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      age: age,
      bio: _bioController.text.trim(),
      photos: _photos,
      interests: _interests,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      gender: _selectedGender,
      lookingFor: _selectedLookingFor,
      job: _jobController.text.trim().isEmpty ? null : _jobController.text.trim(),
      education: _educationController.text.trim().isEmpty ? null : _educationController.text.trim(),
      verified: _currentProfile?.verified ?? false,
      lastSeen: _currentProfile?.lastSeen,
      isOnline: _currentProfile?.isOnline ?? false,
    );

    await ProfileService.saveProfile(updatedProfile);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour avec succès!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer le profil'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos
            PhotoCarousel(
              photos: _photos,
              onPhotoAdded: (photo) => setState(() => _photos.add(photo)),
              onPhotoRemoved: (photo) => setState(() => _photos.remove(photo)),
            ),

            const SizedBox(height: 24),

            // Informations de base
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Informations de base', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Âge *',
                        border: OutlineInputBorder(),
                        hintText: '18-100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'homme', child: Text('Homme')),
                        DropdownMenuItem(value: 'femme', child: Text('Femme')),
                        DropdownMenuItem(value: 'autre', child: Text('Autre')),
                      ],
                      onChanged: (value) => setState(() => _selectedGender = value!),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bio', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Parlez-vous...',
                        border: OutlineInputBorder(),
                        hintText: 'Décrivez-vous en quelques mots...',
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Intérêts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InterestTags(
                  selectedInterests: _interests,
                  onInterestAdded: (interest) => setState(() => _interests.add(interest)),
                  onInterestRemoved: (interest) => setState(() => _interests.remove(interest)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Informations supplémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations supplémentaires',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation',
                        border: OutlineInputBorder(),
                        hintText: 'Ville ou région',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _jobController,
                      decoration: const InputDecoration(
                        labelText: 'Profession',
                        border: OutlineInputBorder(),
                        hintText: 'Votre métier...',
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _educationController,
                      decoration: const InputDecoration(
                        labelText: 'Formation',
                        border: OutlineInputBorder(),
                        hintText: 'Diplôme, études...',
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedLookingFor,
                      decoration: const InputDecoration(
                        labelText: 'Recherche',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'homme', child: Text('Homme')),
                        DropdownMenuItem(value: 'femme', child: Text('Femme')),
                        DropdownMenuItem(value: 'autre', child: Text('Autre')),
                        DropdownMenuItem(value: 'tous', child: Text('Peu importe')),
                      ],
                      onChanged: (value) => setState(() => _selectedLookingFor = value),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Sauvegarder le profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
