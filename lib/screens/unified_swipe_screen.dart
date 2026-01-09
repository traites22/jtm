import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import '../services/unified_match_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/filter_model.dart';
import 'filter_screen.dart';
import 'profile_edit_screen.dart';
import 'profile_detail_screen.dart';

class UnifiedSwipeScreen extends StatefulWidget {
  const UnifiedSwipeScreen({super.key});

  @override
  State<UnifiedSwipeScreen> createState() => _UnifiedSwipeScreenState();
}

class _UnifiedSwipeScreenState extends State<UnifiedSwipeScreen> {
  int _index = 0;
  List<UserModel> _profiles = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _showHeart = false;
  bool _showX = false;
  FilterModel _currentFilters = const FilterModel();

  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger le profil utilisateur courant
      _currentUser = await AuthService.getCurrentUserProfile();

      // Charger les profils compatibles
      _profiles = await UnifiedMatchService.getFilteredProfiles(
        filters: _currentFilters,
        limit: 50,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onLike() async {
    if (_profiles.isEmpty || _index >= _profiles.length) return;

    final currentProfile = _profiles[_index];

    // Ajouter à l'historique pour undo
    _history.add({'action': 'like', 'id': currentProfile.id});

    // Animation heart
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _showHeart = false));

    // Effectuer le like avec notification
    final result = await UnifiedMatchService.likeUserWithNotification(
      targetUserId: currentProfile.id,
    );

    if (!mounted) return;

    if (result['success']) {
      if (result['isMatch']) {
        _history.last['match'] = true;
        _showMatchDialog(currentProfile, result['matchId']);
      }

      _showActionSnackBar('Like envoyé', _undoLast);
    } else {
      _showErrorSnackBar(result['error'] ?? 'Erreur lors du like');
    }

    setState(() => _index = (_index + 1) % _profiles.length);
  }

  Future<void> _onSuperLike() async {
    if (_profiles.isEmpty || _index >= _profiles.length) return;

    final currentProfile = _profiles[_index];

    _history.add({'action': 'superlike', 'id': currentProfile.id});

    // Animation étoile
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 600), () => setState(() => _showHeart = false));

    final result = await UnifiedMatchService.likeUserWithNotification(
      targetUserId: currentProfile.id,
      isSuperLike: true,
    );

    if (!mounted) return;

    if (result['success']) {
      if (result['isMatch']) {
        _history.last['match'] = true;
        _showMatchDialog(currentProfile, result['matchId']);
      }

      _showActionSnackBar('Super like envoyé! ⭐', _undoLast);
    } else {
      _showErrorSnackBar(result['error'] ?? 'Erreur lors du super like');
    }

    setState(() => _index = (_index + 1) % _profiles.length);
  }

  void _onNope() {
    if (_profiles.isEmpty || _index >= _profiles.length) return;

    final currentProfile = _profiles[_index];
    _history.add({'action': 'nope', 'id': currentProfile.id});

    // Animation X
    setState(() => _showX = true);
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _showX = false));

    setState(() => _index = (_index + 1) % _profiles.length);
    _showActionSnackBar('Passé', _undoLast);
  }

  void _undoLast() {
    if (_history.isEmpty) return;

    final last = _history.removeLast();
    final action = last['action'] as String?;
    final id = last['id'] as String?;

    if (action != null && id != null) {
      // Revenir à la carte précédente
      setState(() => _index = (_index - 1 + _profiles.length) % _profiles.length);
      _showActionSnackBar('Action annulée', null);
    }
  }

  void _showMatchDialog(UserModel matchedUser, String matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("C'est un match avec ${matchedUser.name}!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: matchedUser.photos.isNotEmpty
                  ? NetworkImage(matchedUser.photos.first)
                  : null,
              child: matchedUser.photos.isEmpty ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 16),
            Text('Vous pouvez maintenant discuter avec ${matchedUser.name}!'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Plus tard')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToChat(matchId, matchedUser.name);
            },
            child: const Text('Discuter'),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(String matchId, String userName) {
    Navigator.of(context).pushNamed('/chat', arguments: {'matchId': matchId, 'userName': userName});
  }

  void _showActionSnackBar(String message, VoidCallback? action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action != null ? SnackBarAction(label: 'Annuler', onPressed: action) : null,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const FilterScreen()));

    if (result == true) {
      _loadData(); // Recharger avec les nouveaux filtres
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String heroTag,
    bool isMini = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
          child: Transform.scale(
            scale: scale,
            child: FloatingActionButton(
              heroTag: heroTag,
              onPressed: onPressed,
              backgroundColor: color,
              mini: isMini,
              elevation: 6,
              highlightElevation: 12,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(icon, color: Colors.white, key: ValueKey(icon)),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Découvrir')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Découvrir'),
          actions: [
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list),
                  if (_currentFilters.hasActiveFilters)
                    const Positioned(
                      right: -6,
                      top: -6,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text('!', style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              ),
              onPressed: _openFilters,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _currentFilters.hasActiveFilters
                    ? 'Aucun profil ne correspond à vos filtres'
                    : 'Aucun profil disponible',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_currentFilters.hasActiveFilters) ...[
                const SizedBox(height: 8),
                Text(
                  'Essayez d\'élargir vos critères de recherche',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _openFilters, child: const Text('Modifier les filtres')),
              ],
            ],
          ),
        ),
      );
    }

    final currentProfile = _profiles[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir'),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list),
                if (_currentFilters.hasActiveFilters)
                  const Positioned(
                    right: -6,
                    top: -6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text('!', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilters,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Effet de pile de cartes
                    ...List.generate(3, (index) {
                      if (_index + index < _profiles.length) {
                        final profile = _profiles[_index + index];
                        final offset = index * 4.0;
                        final scale = 1.0 - (index * 0.05);
                        return Positioned(
                          top: offset,
                          left: offset,
                          right: offset,
                          bottom: offset,
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: index == 0 ? 1.0 : 0.3 - (index * 0.1),
                              child: GestureDetector(
                                onTap: index == 0
                                    ? () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ProfileDetailScreen(
                                              id: currentProfile.id,
                                              name: currentProfile.name,
                                              intro: currentProfile.bio,
                                              photoPath: currentProfile.photos.isNotEmpty
                                                  ? currentProfile.photos.first
                                                  : 'assets/images/p1.jpg',
                                              age: currentProfile.age,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: ProfileCard(
                                  name: profile.name,
                                  age: profile.age,
                                  bio: profile.bio,
                                  photoPath: profile.photos.isNotEmpty
                                      ? profile.photos.first
                                      : 'assets/images/p1.jpg',
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }).reversed,

                    // Animation cœur
                    if (_showHeart)
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 1.0 + (value * 0.5),
                            child: Transform.rotate(
                              angle: value * 0.1,
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.withOpacity(0.3),
                                        blurRadius: 20 * value,
                                        spreadRadius: 10 * value,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.favorite, size: 120, color: Colors.pink),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Animation X
                    if (_showX)
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.bounceOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: (value * 0.3) * (value % 2 == 0 ? 1 : -1),
                            child: Transform.scale(
                              scale: 1.0 + (value * 0.2),
                              child: Opacity(
                                opacity: value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 15 * value,
                                        spreadRadius: 8 * value,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.close, size: 120, color: Colors.red),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.grey[800]!,
                    onPressed: _onNope,
                    heroTag: 'nope',
                  ),
                  _buildActionButton(
                    icon: Icons.undo,
                    color: Colors.orange[700]!,
                    onPressed: _undoLast,
                    heroTag: 'undo',
                  ),
                  _buildActionButton(
                    icon: Icons.star,
                    color: Colors.blue[600]!,
                    onPressed: _onSuperLike,
                    heroTag: 'superlike',
                    isMini: true,
                  ),
                  _buildActionButton(
                    icon: Icons.favorite,
                    color: Theme.of(context).colorScheme.secondary,
                    onPressed: _onLike,
                    heroTag: 'like',
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
