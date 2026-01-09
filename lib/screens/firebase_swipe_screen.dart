import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_user_service.dart';
import '../services/firebase_chat_service.dart';
import 'profile_detail_screen.dart';

class FirebaseSwipeScreen extends StatefulWidget {
  const FirebaseSwipeScreen({super.key});

  @override
  State<FirebaseSwipeScreen> createState() => _FirebaseSwipeScreenState();
}

class _FirebaseSwipeScreenState extends State<FirebaseSwipeScreen> {
  int _index = 0;
  List<UserModel> _profiles = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _showHeart = false;
  bool _showX = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'utilisateur courant
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUser = await FirebaseUserService.getUserById(user.uid);
      }

      if (_currentUser != null) {
        // Charger les profils compatibles depuis Firebase
        _profiles = await FirebaseUserService.getCompatibleProfiles(
          currentUserId: _currentUser!.id,
          preferences: _currentUser!.preferences,
        );
      }
    } catch (e) {
      print('Erreur chargement données: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _onLike() async {
    if (_profiles.isEmpty || _index >= _profiles.length) return;

    final currentProfile = _profiles[_index];

    // show heart animation
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _showHeart = false));

    if (_currentUser != null) {
      final matched = await FirebaseUserService.addLike(_currentUser!.id, currentProfile.id);

      if (matched) {
        // C'est un match !
        _showMatchDialog(currentProfile);
      }
    }

    setState(() {
      _index = (_index + 1) % _profiles.length;
    });
  }

  void _showMatchDialog(UserModel matchedUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("C'est un match avec ${matchedUser.name}! 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vous pouvez maintenant discuter avec ${matchedUser.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: 'Salut ! Ravi(e) de match 😄'),
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Message...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Plus tard')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Ouvrir le chat
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FirebaseChatScreen(
                    matchId: '${_currentUser!.id}_${matchedUser.id}',
                    matchName: matchedUser.name,
                  ),
                ),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _onNope() {
    if (_profiles.isEmpty || _index >= _profiles.length) return;

    // show nope animation
    setState(() => _showX = true);
    Future.delayed(const Duration(milliseconds: 400), () => setState(() => _showX = false));

    setState(() {
      _index = (_index + 1) % _profiles.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Découvrir')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Découvrir')),
        body: const Center(child: Text('Veuillez vous connecter pour voir les profils')),
      );
    }

    if (_profiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Découvrir'),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucun profil disponible pour le moment'),
              SizedBox(height: 8),
              Text('Réessayez plus tard'),
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
          StreamBuilder<int>(
            stream: FirebaseChatService.getUnreadCount(_currentUser!.id),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
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
                ).push(MaterialPageRoute(builder: (_) => const FirebaseMatchesScreen())),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                    // Profile card
                    GestureDetector(
                      onTap: () {
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
                      },
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: currentProfile.photos.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(currentProfile.photos.first),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: currentProfile.photos.isEmpty
                              ? const Icon(Icons.person, size: 100, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    // Profile info overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentProfile.name}, ${currentProfile.age}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (currentProfile.bio.isNotEmpty)
                              Text(
                                currentProfile.bio,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Heart animation
                    if (_showHeart)
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 1.0 + (value * 0.5),
                            child: Icon(
                              Icons.favorite,
                              size: 120,
                              color: Colors.pink.withOpacity(value),
                            ),
                          );
                        },
                      ),
                    // X animation
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
                              child: Icon(
                                Icons.close,
                                size: 120,
                                color: Colors.red.withOpacity(value),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'nope',
                    onPressed: _onNope,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: 'like',
                    onPressed: _onLike,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(Icons.favorite, color: Colors.white),
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

// Écran des matches Firebase
class FirebaseMatchesScreen extends StatefulWidget {
  const FirebaseMatchesScreen({super.key});

  @override
  State<FirebaseMatchesScreen> createState() => _FirebaseMatchesScreenState();
}

class _FirebaseMatchesScreenState extends State<FirebaseMatchesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Veuillez vous connecter')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseChatService.getUserChats(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucun match pour le moment'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(chatData['id'] ?? 'Match'),
                subtitle: Text(chatData['lastMessage'] ?? 'Matché'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          FirebaseChatScreen(matchId: chatData['id'], matchName: chatData['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Écran de chat Firebase
class FirebaseChatScreen extends StatefulWidget {
  final String matchId;
  final String matchName;

  const FirebaseChatScreen({super.key, required this.matchId, required this.matchName});

  @override
  State<FirebaseChatScreen> createState() => _FirebaseChatScreenState();
}

class _FirebaseChatScreenState extends State<FirebaseChatScreen> {
  final _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Veuillez vous connecter')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.matchName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseChatService.getChatMessages(widget.matchId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aucun message'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          messageData['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (_messageController.text.isNotEmpty && user != null) {
                      await FirebaseChatService.sendMessage(
                        matchId: widget.matchId,
                        senderId: user!.uid,
                        text: _messageController.text,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
