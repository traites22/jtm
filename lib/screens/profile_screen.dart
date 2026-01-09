import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/profile_service.dart';
import '../widgets/photo_carousel.dart';
import '../widgets/interest_tags.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profile = ProfileService.getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Aucun profil trouvé', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                  if (result != null) {
                    _loadProfile();
                  }
                },
                child: const Text('Créer mon profil'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile!.name),
        actions: [
          // Share profile button
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProfile),
          // Edit profile button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
              if (result != null) {
                _loadProfile();
              }
            },
          ),
          // More options
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_link',
                child: Row(
                  children: [Icon(Icons.link), SizedBox(width: 8), Text('Copier le lien')],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Paramètres du profil'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos carousel
            PhotoCarousel(
              photos: _profile!.photos,
              onPhotoAdded: (_) {},
              onPhotoRemoved: (_) {},
              isEditable: false,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced profile header with stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile!.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.cake,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_profile!.age} ans',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  if (_profile!.gender != 'autre') ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _profile!.gender,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            if (_profile!.verified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Vérifié',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Profile stats
                            Row(
                              children: [
                                _buildStatChip('${_profile!.interests.length}', 'Intérêts'),
                                const SizedBox(width: 8),
                                _buildStatChip('98%', 'Compatibilité'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bio
                  if (_profile!.bio.isNotEmpty) ...[
                    Text('Bio', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_profile!.bio),
                    const SizedBox(height: 16),
                  ],

                  // Localisation
                  if (_profile!.location != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(_profile!.location!, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Profession et formation
                  if (_profile!.job != null || _profile!.education != null) ...[
                    Text('Carrière', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_profile!.job != null) ...[
                      Row(
                        children: [
                          Icon(Icons.work, size: 20, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 8),
                          Text(_profile!.job!),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_profile!.education != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.school,
                            size: 20,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 8),
                          Text(_profile!.education!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Intérêts
                  if (_profile!.interests.isNotEmpty) ...[
                    Text('Intérêts', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    InterestTags(
                      selectedInterests: _profile!.interests,
                      onInterestAdded: (_) {},
                      onInterestRemoved: (_) {},
                      isEditable: false,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Recherche
                  if (_profile!.lookingFor != null) ...[
                    Text('Recherche', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(_profile!.lookingFor!),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Statut
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _profile!.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _profile!.isOnline
                            ? 'En ligne'
                            : _profile!.lastSeen != null
                            ? 'Dernière connexion: ${_formatDate(_profile!.lastSeen!)}'
                            : 'Hors ligne',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return "À l'instant";
    }
  }

  void _shareProfile() {
    // Implement profile sharing functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Lien du profil copié!')));
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_link':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lien du profil copié!')));
        break;
      case 'settings':
        // Navigate to profile settings
        break;
    }
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
