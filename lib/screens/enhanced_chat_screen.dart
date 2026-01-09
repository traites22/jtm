import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/invitation_model.dart';
import '../services/enhanced_messaging_service.dart';
import '../services/invitation_service.dart';
import '../services/biometric_service.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/enhanced_input_field.dart';
import '../widgets/invitation_card.dart';
import '../widgets/read_receipts.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String currentUserId;
  final String? otherUserId;
  final String? conversationId;

  const EnhancedChatScreen({
    super.key,
    required this.currentUserId,
    this.otherUserId,
    this.conversationId,
  });

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _canSendMessage = false;
  String? _pendingInvitationId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    // Vérifier si une conversation existe
    if (widget.otherUserId != null) {
      _canSendMessage = await InvitationService.conversationExists(
        widget.currentUserId,
        widget.otherUserId!,
      );

      if (!_canSendMessage) {
        // Vérifier s'il y a une invitation en attente
        await _checkPendingInvitation();
      }
    }

    // Charger les messages si la conversation existe
    if (_canSendMessage) {
      await _loadMessages();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _checkPendingInvitation() async {
    final pendingInvitations = await InvitationService.getPendingInvitations(widget.currentUserId);
    final invitation = pendingInvitations.firstWhere(
      (inv) => inv.senderId == widget.otherUserId || inv.receiverId == widget.otherUserId,
      orElse: () => pendingInvitations.first,
    );

    if (invitation.senderId == widget.otherUserId) {
      setState(() => _pendingInvitationId = invitation.id);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await EnhancedMessagingService.getMessages(
        widget.conversationId ?? 'default',
      );
      setState(() => _messages = messages);
      _scrollToBottom();
    } catch (e) {
      // Gérer l'erreur
    }
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
    if (!_canSendMessage || widget.otherUserId == null) return;

    final success = await EnhancedMessagingService.sendTextMessage(
      matchId: widget.conversationId ?? 'default',
      senderId: widget.currentUserId,
      text: text,
    );

    if (success) {
      await _loadMessages();
    }
  }

  Future<void> _sendInvitation() async {
    if (widget.otherUserId == null) return;

    // Authentification biométrique avant d'envoyer
    final authResult = await BiometricService.authenticate(
      localizedReason: 'Authentifiez-vous pour envoyer une invitation',
    );

    if (!authResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authResult.frenchMessage)));
      return;
    }

    final success = await InvitationService.sendInvitation(
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId!,
      type: InvitationType.chat,
      message: InvitationService.generateDefaultMessage(InvitationType.chat),
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation envoyée')));
      await _initializeChat(); // Recharger l'état
    }
  }

  Future<void> _handleInvitationResponse(bool accept) async {
    if (_pendingInvitationId == null) return;

    final success = await InvitationService.respondToInvitation(
      invitationId: _pendingInvitationId!,
      accept: accept,
    );

    if (success) {
      setState(() => _pendingInvitationId = null);
      await _initializeChat(); // Recharger l'état

      if (accept) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation acceptée ! Vous pouvez maintenant discuter')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserId != null ? 'Discussion avec ${widget.otherUserId}' : 'Chat'),
        actions: [
          if (!_canSendMessage && widget.otherUserId != null)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _sendInvitation,
              tooltip: 'Envoyer une invitation',
            ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildChatContent(),
    );
  }

  Widget _buildChatContent() {
    if (_pendingInvitationId != null) {
      return _buildPendingInvitationView();
    }

    if (!_canSendMessage) {
      return _buildNoConversationView();
    }

    return Column(
      children: [
        // Liste des messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return EnhancedMessageBubble(
                message: message,
                currentUserId: widget.currentUserId,
                onMessageDelete: () => _loadMessages(),
              );
            },
          ),
        ),

        // Champ de saisie
        EnhancedInputField(
          matchId: widget.conversationId ?? 'default',
          currentUserId: widget.currentUserId,
          onMessageSent: (text) => _sendMessage(text),
        ),
      ],
    );
  }

  Widget _buildPendingInvitationView() {
    return FutureBuilder<InvitationModel?>(
      future: _getPendingInvitation(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final invitation = snapshot.data;
        if (invitation == null) {
          return _buildNoConversationView();
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(invitation.type.icon, size: 64, color: invitation.type.color),
                const SizedBox(height: 16),
                Text('Invitation reçue', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  invitation.type.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (invitation.message != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      invitation.message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleInvitationResponse(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleInvitationResponse(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoConversationView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Commencez la conversation',
              style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              'Envoyez une invitation pour commencer à discuter',
              style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.otherUserId != null ? _sendInvitation : null,
              icon: const Icon(Icons.person_add),
              label: const Text('Envoyer une invitation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<InvitationModel?> _getPendingInvitation() async {
    if (_pendingInvitationId == null) return null;
    return await InvitationService.getInvitation(_pendingInvitationId!);
  }
}

// Écran des invitations
class InvitationsScreen extends StatelessWidget {
  final String currentUserId;

  const InvitationsScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invitations'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Reçues', icon: Icon(Icons.inbox)),
              Tab(text: 'Envoyées', icon: Icon(Icons.send)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            InvitationsList(currentUserId: currentUserId, showReceivedOnly: true),
            InvitationsList(currentUserId: currentUserId, showReceivedOnly: false),
          ],
        ),
      ),
    );
  }
}
