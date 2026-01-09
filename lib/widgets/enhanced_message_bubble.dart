import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/enhanced_messaging_service.dart';
import '../services/profile_service.dart';
import 'message_reactions.dart';
import 'location_message.dart';
import 'image_message.dart';

class EnhancedMessageBubble extends StatefulWidget {
  final MessageModel message;
  final String currentUserId;
  final Function()? onMessageEdit;
  final Function()? onMessageDelete;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onMessageEdit,
    this.onMessageDelete,
  });

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble> {
  bool _showActions = false;

  @override
  Widget build(BuildContext context) {
    final isFromCurrentUser = widget.message.isFromSender(widget.currentUserId);

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isFromCurrentUser ? 64 : 8,
        right: isFromCurrentUser ? 8 : 64,
      ),
      child: Column(
        crossAxisAlignment: isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bulle de message principale
          GestureDetector(
            onLongPress: () => _showMessageActions(context),
            child: Container(
              decoration: BoxDecoration(
                color: _getBubbleColor(context, isFromCurrentUser),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(context, isFromCurrentUser),
            ),
          ),

          // Réactions
          MessageReactions(message: widget.message, currentUserId: widget.currentUserId),

          // Actions (long press)
          if (_showActions) ...[
            const SizedBox(height: 4),
            _buildActionButtons(context, isFromCurrentUser),
          ],

          // Statut et timestamp
          const SizedBox(height: 2),
          _buildMessageStatus(context, isFromCurrentUser),
        ],
      ),
    );
  }

  Color _getBubbleColor(BuildContext context, bool isFromCurrentUser) {
    if (isFromCurrentUser) {
      return Theme.of(context).colorScheme.primary;
    } else {
      return Theme.of(context).colorScheme.surface;
    }
  }

  Widget _buildMessageContent(BuildContext context, bool isFromCurrentUser) {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextMessage(context, isFromCurrentUser);
      case MessageType.image:
        return ImageMessage(message: widget.message, isFromCurrentUser: isFromCurrentUser);
      case MessageType.location:
        return LocationMessage(message: widget.message, isFromCurrentUser: isFromCurrentUser);
      case MessageType.system:
        return _buildSystemMessage(context);
      case MessageType.audio:
        return _buildAudioMessage(context, isFromCurrentUser);
    }
  }

  Widget _buildTextMessage(BuildContext context, bool isFromCurrentUser) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.editedAt != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: 12,
                  color: isFromCurrentUser
                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'modifié',
                  style: TextStyle(
                    fontSize: 10,
                    color: isFromCurrentUser
                        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Text(
            widget.message.displayText,
            style: TextStyle(
              color: isFromCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        widget.message.displayText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAudioMessage(BuildContext context, bool isFromCurrentUser) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_circle,
            color: isFromCurrentUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            'Message audio',
            style: TextStyle(
              color: isFromCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatus(BuildContext context, bool isFromCurrentUser) {
    if (!isFromCurrentUser) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône de statut
        Icon(_getStatusIcon(), size: 12, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        // Timestamp
        Text(
          _formatTime(widget.message.timestamp),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        // Indicateur de lecture si disponible
        if (widget.message.readAt != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.done_all, size: 12, color: Colors.blue),
        ],
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (widget.message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showMessageActions(BuildContext context) {
    setState(() {
      _showActions = !_showActions;
    });

    if (_showActions) {
      // Masquer automatiquement après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showActions = false;
          });
        }
      });
    }
  }

  Widget _buildActionButtons(BuildContext context, bool isFromCurrentUser) {
    if (!isFromCurrentUser || widget.message.type != MessageType.text) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Réagir
          ReactionButton(
            message: widget.message,
            currentUserId: widget.currentUserId,
            onTap: () {
              setState(() => _showActions = false);
            },
          ),
          const SizedBox(width: 8),
          // Copier
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              _copyMessage(context);
              setState(() => _showActions = false);
            },
          ),
          const SizedBox(width: 8),
          // Supprimer
          IconButton(
            icon: const Icon(Icons.delete, size: 16),
            onPressed: () {
              _deleteMessage(context);
              setState(() => _showActions = false);
            },
          ),
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    // Copier le texte du message dans le presse-papiers
    // Dans une vraie app, utiliser flutter/services
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copié')));
  }

  void _deleteMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce message ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onMessageDelete != null) {
                widget.onMessageDelete!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
