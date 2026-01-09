import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobController = TextEditingController();

  String _selectedGender = 'Homme';
  String _lookingFor = 'Femme';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final profileBox = Hive.box('profileBox');
      final currentUser = profileBox.get('currentUser');

      if (currentUser != null) {
        setState(() {
          _nameController.text = currentUser['name'] ?? '';
          _emailController.text = currentUser['email'] ?? '';
          _bioController.text = currentUser['bio'] ?? '';
          _ageController.text = currentUser['age']?.toString() ?? '';
          _locationController.text = currentUser['location'] ?? '';
          _jobController.text = currentUser['job'] ?? '';
          _selectedGender = currentUser['gender'] ?? 'Homme';
          _lookingFor = currentUser['lookingFor'] ?? 'Femme';
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (_isLoading) return;

    // Validation des champs
    if (_nameController.text.trim().isEmpty) {
      _showError('Veuillez entrer votre nom');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Veuillez entrer votre email');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showError('Veuillez entrer un email valide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileBox = Hive.box('profileBox');
      var currentUser = profileBox.get('currentUser');

      print('Données utilisateur actuelles: $currentUser');

      if (currentUser == null) {
        _showError('Aucun utilisateur trouvé. Veuillez vous reconnecter.');
        setState(() => _isLoading = false);
        return;
      }

      // Convertir en Map si nécessaire
      if (currentUser is! Map) {
        currentUser = Map<String, dynamic>.from(currentUser);
      }

      // S'assurer que l'ID est un String
      String userId;
      if (currentUser['id'] is String) {
        userId = currentUser['id'];
      } else if (currentUser['id'] is int) {
        userId = currentUser['id'].toString();
      } else {
        userId = currentUser['id']?.toString() ?? '';
      }

      // Mettre à jour les données
      currentUser['id'] = userId; // S'assurer que l'ID reste un String
      currentUser['name'] = _nameController.text.trim();
      currentUser['email'] = _emailController.text.trim();
      currentUser['bio'] = _bioController.text.trim();
      currentUser['age'] = int.tryParse(_ageController.text) ?? currentUser['age'];
      currentUser['location'] = _locationController.text.trim();
      currentUser['job'] = _jobController.text.trim();
      currentUser['gender'] = _selectedGender;
      currentUser['lookingFor'] = _lookingFor;

      print('Données mises à jour: $currentUser');
      print('ID utilisateur final: $userId (${userId.runtimeType})');

      // Sauvegarder dans profileBox
      await profileBox.put('currentUser', currentUser);
      print('Sauvegardé dans profileBox');

      // Mettre à jour dans usersBox avec clé String
      final usersBox = Hive.box('usersBox');
      await usersBox.put(userId, currentUser);
      print('Sauvegardé dans usersBox avec clé String: $userId');

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur détaillée lors de la sauvegarde: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final profileBox = Hive.box('profileBox');
        final currentUser = profileBox.get('currentUser');

        if (currentUser != null) {
          // S'assurer que l'ID est un String pour la suppression
          String userId;
          if (currentUser['id'] is String) {
            userId = currentUser['id'];
          } else if (currentUser['id'] is int) {
            userId = currentUser['id'].toString();
          } else {
            userId = currentUser['id']?.toString() ?? '';
          }

          // Supprimer de usersBox avec clé String
          final usersBox = Hive.box('usersBox');
          await usersBox.delete(userId);
          print('Supprimé de usersBox avec clé: $userId');

          // Supprimer les boîtes personnelles avec noms valides
          await Hive.deleteBoxFromDisk('profile_$userId');
          await Hive.deleteBoxFromDisk('likes_$userId');
          await Hive.deleteBoxFromDisk('matches_$userId');
          print('Boîtes personnelles supprimées pour: $userId');

          // Nettoyer profileBox
          await profileBox.clear();

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profil du compte'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo de profil
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fonctionnalité photo bientôt disponible')),
                      );
                    },
                    child: Text(
                      'Ajouter une photo',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Informations personnelles
            _buildSectionHeader('Informations personnelles'),
            _buildSettingsCard([
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Âge',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Préférences
            _buildSectionHeader('Préférences'),
            _buildSettingsCard([
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Je suis',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Homme', 'Femme', 'Autre'].map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _lookingFor,
                decoration: InputDecoration(
                  labelText: 'Je cherche',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Homme', 'Femme', 'Les deux'].map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() => _lookingFor = value!),
              ),
            ]),

            const SizedBox(height: 24),

            // Détails
            _buildSectionHeader('Détails'),
            _buildSettingsCard([
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Décrivez-vous...',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Localisation',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jobController,
                decoration: InputDecoration(
                  labelText: 'Profession',
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sauvegarder'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Supprimer le compte'),
                  ),
                ),
              ],
            ),

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
