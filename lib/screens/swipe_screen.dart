import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/profile_card.dart';
import 'profile_edit_screen.dart';
import 'profile_detail_screen.dart';
import '../services/match_service.dart';
import '../services/messaging_service.dart';
import '../services/inbox_service.dart';
import '../services/filter_service.dart';
import '../services/profile_service.dart';
import '../services/demo_data_service.dart';
import '../models/user.dart';
import '../models/filter_model.dart';
import 'filter_screen.dart';
import 'inbox_screen.dart';
import 'announcements_screen.dart';
import 'chat_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  int _index = 0;
  final _likesBox = Hive.box('likesBox');

  List<UserModel> _allProfiles = [];
  List<UserModel> _filteredProfiles = [];
  FilterModel _currentFilters = const FilterModel();
  UserModel? _currentUser;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _history = [];
  bool _showHeart = false;
  bool _showX = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Charger les profils de démonstration
    _allProfiles = DemoDataService.getDemoProfiles();

    // Charger le profil utilisateur courant
    _currentUser = ProfileService.getProfile();

    // Charger les filtres
    _currentFilters = FilterService.getFilters();

    // Appliquer les filtres
    _applyFilters();

    // Seed a reciprocal like from Leo -> me to demonstrate matches
    if (_currentUser != null) {
      final leoLikes = List<String>.from(_likesBox.get('leo', defaultValue: []) as List);
      if (!leoLikes.contains(_currentUser!.id)) {
        leoLikes.add(_currentUser!.id);
        _likesBox.put('leo', leoLikes);
      }
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    setState(() {
      _filteredProfiles = FilterService.filterProfiles(_allProfiles, _currentFilters, _currentUser);
      _index = 0; // Reset index when filters change
    });
  }

  Future<void> _onLike() async {
    if (_filteredProfiles.isEmpty || _index >= _filteredProfiles.length) return;

    final me = _currentUser?.id ?? 'me';
    final currentProfile = _filteredProfiles[_index];

    // push history for undo
    _history.add({'action': 'like', 'id': currentProfile.id});

    // show heart animation
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _showHeart = false));

    final matched = await MatchService.likeUser(me: me, target: currentProfile.toMap());

    // guard against using context after async gap
    if (!mounted) return;

    if (matched) {
      // mark history entry as match to help undo
      _history.last['match'] = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("C'est un match avec ${currentProfile.name}!")));

      // Offer to send a message now or open the chat
      if (!mounted) return;
      final TextEditingController msgC = TextEditingController(text: 'Salut ! Ravi(e) de match 😄');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("C'est un match avec ${currentProfile.name}!"),
          content: TextField(
            controller: msgC,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Message...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        matchId: currentProfile.id,
                        matchName: currentProfile.name,
                        autofocus: true,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () async {
                final textToSend = msgC.text.trim();
                if (textToSend.isEmpty) return;
                // Allow creating a minimal match record here to avoid race conditions
                final ok = await MessagingService.sendMessage(
                  matchId: currentProfile.id,
                  sender: me,
                  text: textToSend,
                  createMatchIfMissing: true,
                );
                if (!mounted) return;
                if (ok) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Message envoyé')));
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Impossible d\'envoyer')));
                  }
                }
                Navigator.of(ctx).pop();
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        matchId: currentProfile.id,
                        matchName: currentProfile.name,
                        autofocus: true,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      );
    }

    setState(() {
      _index = (_index + 1) % _filteredProfiles.length;
    });

    // offer undo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Action effectuée'),
          action: SnackBarAction(label: 'Annuler', onPressed: _undoLast),
        ),
      );
    }
  }

  void _onNope() {
    if (_filteredProfiles.isEmpty || _index >= _filteredProfiles.length) return;

    final currentProfile = _filteredProfiles[_index];
    _history.add({'action': 'nope', 'id': currentProfile.id});

    // show nope animation (could be an X overlay)
    setState(() => _showX = true);
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _showX = false));

    setState(() {
      _index = (_index + 1) % _filteredProfiles.length;
    });

    // offer undo
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Action effectuée'),
          action: SnackBarAction(label: 'Annuler', onPressed: _undoLast),
        ),
      );
    }
  }

  void _undoLast() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    final action = last['action'] as String?;
    final id = last['id'] as String?;

    if (action == 'like' && id != null) {
      final likesBox = Hive.box('likesBox');
      final me = _currentUser?.id ?? 'me';
      final myLikes = List<String>.from(likesBox.get(me, defaultValue: []) as List);
      myLikes.remove(id);
      likesBox.put(me, myLikes);

      if (last['match'] == true) {
        final matchesBox = Hive.box('matchesBox');
        final messagesBox = Hive.box('messagesBox');
        matchesBox.delete(id);
        messagesBox.delete('match:$id');
      }
    }

    // revert index to previous card
    setState(() {
      _index = (_index - 1 + _filteredProfiles.length) % _filteredProfiles.length;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action annulée')));
    }
  }

  Future<void> _onSuperLike() async {
    if (_filteredProfiles.isEmpty || _index >= _filteredProfiles.length) return;

    final me = _currentUser?.id ?? 'me';
    final currentProfile = _filteredProfiles[_index];

    // Add to history
    _history.add({'action': 'superlike', 'id': currentProfile.id});

    // Show star animation
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 600), () => setState(() => _showHeart = false));

    // Super like logic (higher priority match)
    final matched = await MatchService.likeUser(
      me: me,
      target: currentProfile.toMap(),
      isSuperLike: true,
    );

    if (!mounted) return;

    if (matched) {
      _history.last['match'] = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Super match avec ${currentProfile.name}! ⭐")));
    }

    setState(() {
      _index = (_index + 1) % _filteredProfiles.length;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Super like envoyé! ⭐'),
          action: SnackBarAction(label: 'Annuler', onPressed: _undoLast),
        ),
      );
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
              onPressed: () {
                // Add haptic feedback
                // HapticFeedback.lightImpact();
                onPressed();
              },
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

  Future<void> _openFilters() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const FilterScreen()));

    if (result == true) {
      _loadData(); // Recharger les données avec les nouveaux filtres
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Découvrir')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredProfiles.isEmpty) {
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
                    Positioned(
                      right: -6,
                      top: -6,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text('!', style: const TextStyle(fontSize: 10, color: Colors.white)),
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

    final currentProfile = _filteredProfiles[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir'),
        actions: [
          ValueListenableBuilder(
            valueListenable: Hive.box('messagesBox').listenable(),
            builder: (context, Box box, _) {
              final unread = InboxService.getConversationsSync().fold<int>(
                0,
                (s, c) => s + (c['unreadCount'] as int),
              );
              return IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.mail_outline),
                    if (unread > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const InboxScreen())),
              );
            },
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list),
                if (_currentFilters.hasActiveFilters)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text('!', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            onPressed: _openFilters,
          ),
          IconButton(
            icon: const Icon(Icons.announcement_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
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
                    // Card stack effect
                    ...List.generate(3, (index) {
                      if (_index + index < _filteredProfiles.length) {
                        final profile = _filteredProfiles[_index + index];
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
                    // Enhanced heart animation
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
                                  child: Icon(Icons.favorite, size: 120, color: Colors.pink),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Enhanced X animation
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
                                  child: Icon(Icons.close, size: 120, color: Colors.red),
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
              // Enhanced action buttons with animations
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
                    isMini: false,
                  ),
                  _buildActionButton(
                    icon: Icons.star,
                    color: Colors.blue[600]!,
                    onPressed: _onSuperLike,
                    heroTag: 'superlike',
                    isMini: true,
                  ),
                  _buildActionButton(
                    icon: Icons.mail_outline,
                    color: Colors.purple[700]!,
                    onPressed: () async {
                      final me = _currentUser?.id ?? 'me';
                      final ok = await MessagingService.sendRequest(
                        from: me,
                        toId: currentProfile.id,
                        text: 'Salut, envie de discuter ?',
                      );

                      if (!mounted) return;

                      if (ok) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Demande envoyée')));
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Demande déjà envoyée')));
                        }
                      }
                    },
                    heroTag: 'request',
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
