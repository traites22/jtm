import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/unified_match_service.dart';
import '../services/auth_service.dart';
import '../services/cloud_messaging_service.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/enhanced_input_field.dart';

class UnifiedChatScreen extends StatefulWidget {
  final String matchId;
  final String userName;

  const UnifiedChatScreen({super.key, required this.matchId, required this.userName});

  @override
  State<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends State<UnifiedChatScreen> {
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  List<String> _typingUsers = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService.currentUser?.uid;
    _loadMessages();
    _listenToTyping();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    CloudMessagingService.getMessages(widget.matchId).listen((messages) {
      setState(() {
        _messages = messages.reversed.toList(); // Inverser pour ordre chronologique
        _isLoading = false;
      });
      _scrollToBottom();

      // Marquer les messages comme lus
      _markMessagesAsRead();
    });
  }

  void _listenToTyping() {
    CloudMessagingService.getTypingUsers(widget.matchId).listen((typingUsers) {
      setState(() {
        _typingUsers = typingUsers.where((id) => id != _currentUserId).toList();
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _currentUserId == null) return;

    // Envoyer le message avec notification
    final success = await UnifiedMatchService.sendMessageWithNotification(
      matchId: widget.matchId,
      text: text.trim(),
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'envoi du message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    // Implémenter l'envoi d'images
    // Pour l'instant, nous allons simuler
    _sendMessage('📷 Photo envoyée');
  }

  Future<void> _sendLocation() async {
    // Implémenter l'envoi de localisation
    // Pour l'instant, nous allons simuler
    _sendMessage('📍 Position partagée');
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null) return;

    final unreadMessageIds = _messages
        .where((msg) => !msg.isFromSender(_currentUserId!) && msg.status != MessageStatus.read)
        .map((msg) => msg.id)
        .toList();

    if (unreadMessageIds.isNotEmpty) {
      await CloudMessagingService.markMessagesAsRead(
        matchId: widget.matchId,
        messageIds: unreadMessageIds,
      );
    }
  }

  Future<void> _addReaction(String messageId, String emoji) async {
    await CloudMessagingService.addReaction(
      matchId: widget.matchId,
      messageId: messageId,
      emoji: emoji,
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    final success = await CloudMessagingService.deleteMessage(
      matchId: widget.matchId,
      messageId: messageId,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de supprimer ce message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editMessage(String messageId, String newText) async {
    final success = await CloudMessagingService.editMessage(
      matchId: widget.matchId,
      messageId: messageId,
      newText: newText,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier ce message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTextChanged(String text) {
    // Indiquer que l'utilisateur est en train d'écrire
    CloudMessagingService.setTyping(matchId: widget.matchId, isTyping: text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Afficher les informations du profil du match
              _showMatchProfile();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur d'écriture
          if (_typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_typingUsers.length} utilisateur(s) en train d\'écrire...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          // Liste des messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return EnhancedMessageBubble(
                        message: message,
                        currentUserId: _currentUserId ?? '',
                        onReactionAdded: _addReaction,
                        onMessageDeleted: _deleteMessage,
                        onMessageEdited: _editMessage,
                      );
                    },
                  ),
          ),

          // Champ de saisie
          EnhancedInputField(
            matchId: widget.matchId,
            currentUserId: _currentUserId ?? '',
            onMessageSent: _sendMessage,
            onTextChanged: _onTextChanged,
            onImageSelected: _sendImage,
            onLocationSelected: _sendLocation,
          ),
        ],
      ),
    );
  }

  void _showMatchProfile() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Profil de ${widget.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),
            Text('Informations du profil', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Vous pouvez voir plus de détails sur le profil de ${widget.userName}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Naviguer vers le profil détaillé
              // Navigator.of(context).pushNamed('/profile', arguments: widget.matchId);
            },
            child: const Text('Voir le profil'),
          ),
        ],
      ),
    );
  }
}
