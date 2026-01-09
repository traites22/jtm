import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'chat_screen.dart';

class Message {
  final String id;
  final String matchId;
  final String matchName;
  final String lastMessage;
  final DateTime timestamp;
  final bool isRead;
  final String? matchPhoto;

  Message({
    required this.id,
    required this.matchId,
    required this.matchName,
    required this.lastMessage,
    required this.timestamp,
    this.isRead = false,
    this.matchPhoto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matchId': matchId,
      'matchName': matchName,
      'lastMessage': lastMessage,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'matchPhoto': matchPhoto,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      matchId: map['matchId'],
      matchName: map['matchName'],
      lastMessage: map['lastMessage'] ?? 'Nouveau message',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isRead: map['isRead'] ?? false,
      matchPhoto: map['matchPhoto'],
    );
  }
}

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messagesBox = Hive.box('messagesBox');
  final _matchesBox = Hive.box('matchesBox');
  final _searchController = TextEditingController();
  List<Message> _conversations = [];
  List<Message> _filteredConversations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _searchController.addListener(_filterConversations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final matches = _matchesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
      final conversations = <Message>[];

      for (final match in matches) {
        final matchId = match['id'] as String;
        final matchName = match['name'] as String;
        final matchPhoto = match['photo'] as String?;

        // Récupérer les messages pour ce match
        final messagesKey = 'match:$matchId';
        final messages = List<Map>.from(_messagesBox.get(messagesKey, defaultValue: []) as List);

        if (messages.isNotEmpty) {
          final lastMessage = messages.last['text'] as String;
          final timestamp = DateTime.fromMillisecondsSinceEpoch(messages.last['timestamp'] as int);

          conversations.add(
            Message(
              id: messages.last['id'] as String,
              matchId: matchId,
              matchName: matchName,
              lastMessage: lastMessage,
              timestamp: timestamp,
              isRead: messages.last['isRead'] as bool? ?? false,
              matchPhoto: matchPhoto,
            ),
          );
        }
      }

      // Trier par timestamp (plus récent en premier)
      conversations.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
      });
    } catch (e) {
      print('Erreur chargement conversations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations.where((conversation) {
          return conversation.matchName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _markAsRead(String matchId) async {
    try {
      final messagesKey = 'match:$matchId';
      final messages = List<Map>.from(_messagesBox.get(messagesKey, defaultValue: []) as List);

      // Marquer tous les messages comme lus
      for (int i = 0; i < messages.length; i++) {
        messages[i]['isRead'] = true;
      }

      await _messagesBox.put(messagesKey, messages);

      // Mettre à jour la conversation locale
      setState(() {
        final index = _conversations.indexWhere((conv) => conv.matchId == matchId);
        if (index != -1) {
          _conversations[index] = _conversations[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      print('Erreur marquage message lu: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[300],
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: Icon(Icons.search, color: Colors.pink[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          // Liste des conversations
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                  )
                : _filteredConversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined, size: 80, color: Colors.pink[300]),
                        const SizedBox(height: 20),
                        Text(
                          'Aucune conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Vos matchs apparaîtront ici',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _filteredConversations[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: conversation.matchPhoto != null
                                ? NetworkImage(conversation.matchPhoto!)
                                : null,
                            child: conversation.matchPhoto == null
                                ? Icon(Icons.person, color: Colors.grey[600])
                                : null,
                          ),
                          title: Text(
                            conversation.matchName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: conversation.isRead ? Colors.grey[700] : Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                conversation.lastMessage,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTimestamp(conversation.timestamp),
                                style: TextStyle(
                                  color: Colors.pink[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!conversation.isRead)
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.pink[600],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Icon(Icons.chevron_right, color: Colors.grey[400]),
                            ],
                          ),
                          onTap: () async {
                            // Marquer comme lu avant d'ouvrir
                            await _markAsRead(conversation.matchId);

                            // Naviguer vers l'écran de chat
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  matchId: conversation.matchId,
                                  matchName: conversation.matchName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension MessageExtension on Message {
  Message copyWith({
    String? id,
    String? matchId,
    String? matchName,
    String? lastMessage,
    DateTime? timestamp,
    bool? isRead,
    String? matchPhoto,
  }) {
    return Message(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      matchPhoto: matchPhoto ?? this.matchPhoto,
    );
  }
}
