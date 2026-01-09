import 'package:flutter/material.dart';
import '../services/pure_firebase_auth_service.dart';
import '../models/user_model.dart';
import '../services/firebase_user_service.dart';

class Annonce {
  final String id;
  final String userId;
  final String content;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? userName;
  final String? userPhoto;

  Annonce({
    required this.id,
    required this.userId,
    required this.content,
    required this.isAnonymous,
    required this.createdAt,
    this.userName,
    this.userPhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'userName': userName,
      'userPhoto': userPhoto,
    };
  }

  factory Annonce.fromMap(Map<String, dynamic> map) {
    return Annonce(
      id: map['id'],
      userId: map['userId'],
      content: map['content'],
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      userName: map['userName'],
      userPhoto: map['userPhoto'],
    );
  }
}

class AnnonceScreen extends StatefulWidget {
  const AnnonceScreen({super.key});

  @override
  State<AnnonceScreen> createState() => _AnnonceScreenState();
}

class _AnnonceScreenState extends State<AnnonceScreen> {
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;
  List<Annonce> _annonces = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadAnnonces();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await PureFirebaseAuthService.getCurrentUserProfile();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _loadAnnonces() async {
    // Simuler le chargement des annonces depuis Firestore
    // Dans la vraie implémentation, vous utiliserez Firebase
    setState(() {
      _annonces = [
        Annonce(
          id: '1',
          userId: 'user1',
          content: 'Quelqu\'un est intéressé par une sortie cinéma ce week-end ?',
          isAnonymous: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Annonce(
          id: '2',
          userId: 'user2',
          content: 'Je cherche des personnes pour faire du sport ensemble le samedi matin',
          isAnonymous: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          userName: 'Marie',
        ),
      ];
    });
  }

  Future<void> _postAnnonce() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez écrire une annonce'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newAnnonce = Annonce(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: PureFirebaseAuthService.currentUser?.uid ?? '',
        content: _contentController.text.trim(),
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
        userName: _isAnonymous ? null : _currentUser?.name,
        userPhoto: _isAnonymous
            ? null
            : _currentUser?.photos.isNotEmpty == true
            ? _currentUser!.photos.first
            : null,
      );

      // Ajouter l'annonce localement (dans la vraie version, sauvegarder dans Firestore)
      setState(() {
        _annonces.insert(0, newAnnonce);
        _contentController.clear();
        _isAnonymous = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAnonymous ? 'Annonce publiée anonymement !' : 'Annonce publiée avec votre nom !',
            ),
            backgroundColor: Colors.green,
          ),
        );
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
      body: Column(
        children: [
          // Section pour créer une annonce
          Container(
            margin: const EdgeInsets.all(16),
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
                  'Publier une annonce',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[700],
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Qu\'avez-vous en tête ?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),

                // Option anonyme/publique
                Row(
                  children: [
                    Checkbox(
                      value: _isAnonymous,
                      onChanged: (value) {
                        setState(() => _isAnonymous = value ?? false);
                      },
                      activeColor: Colors.pink[400],
                    ),
                    Text('Publier anonymement', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 12),

                // Bouton de publication
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _postAnnonce,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Publier'),
                  ),
                ),
              ],
            ),
          ),

          // Séparateur
          Container(
            height: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Liste des annonces
          Expanded(
            child: _annonces.isEmpty
                ? Center(
                    child: Text(
                      'Aucune annonce pour le moment',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _annonces.length,
                    itemBuilder: (context, index) {
                      final annonce = _annonces[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                            // En-tête de l'annonce
                            Row(
                              children: [
                                // Photo de profil ou icône anonyme
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: annonce.isAnonymous
                                        ? Colors.grey[300]
                                        : Colors.pink[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: annonce.isAnonymous
                                      ? Icon(Icons.person_off, color: Colors.grey[600])
                                      : annonce.userPhoto != null
                                      ? ClipOval(
                                          child: Image.network(
                                            annonce.userPhoto!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Icon(Icons.person, color: Colors.pink[700]),
                                ),
                                const SizedBox(width: 12),

                                // Nom ou "Anonyme"
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        annonce.isAnonymous
                                            ? 'Anonyme'
                                            : annonce.userName ?? 'Utilisateur',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.pink[700],
                                        ),
                                      ),
                                      Text(
                                        _formatDate(annonce.createdAt),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),

                                // Badge anonyme si applicable
                                if (annonce.isAnonymous)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Anonyme',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Contenu de l'annonce
                            Text(annonce.content, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
