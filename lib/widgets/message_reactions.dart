import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/enhanced_messaging_service.dart';

class MessageReactions extends StatefulWidget {
  final MessageModel message;
  final String currentUserId;
  final Function(String)? onReactionAdded;
  final Function(String)? onReactionRemoved;

  const MessageReactions({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onReactionAdded,
    this.onReactionRemoved,
  });

  @override
  State<MessageReactions> createState() => _MessageReactionsState();
}

class _MessageReactionsState extends State<MessageReactions> {
  bool _showEmojiPicker = false;
  String? _userReaction;

  @override
  void initState() {
    super.initState();
    _loadUserReaction();
  }

  void _loadUserReaction() {
    // Vérifier si l'utilisateur actuel a déjà réagi
    final reactionKey = '${widget.message.id}_reactions_${widget.currentUserId}';
    // Dans une vraie app, charger depuis le stockage
    // Pour l'instant, nous allons simuler
    setState(() {
      _userReaction = null; // À charger depuis le service
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.message.hasReactions && !_showEmojiPicker) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.hasReactions) ...[const SizedBox(height: 4), _buildReactionsList()],
        if (_showEmojiPicker) ...[const SizedBox(height: 8), _buildEmojiPicker()],
      ],
    );
  }

  Widget _buildReactionsList() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: widget.message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;
        final isUserReaction = _userReaction == emoji;

        return GestureDetector(
          onTap: () => _toggleReaction(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUserReaction
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUserReaction
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isUserReaction ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 16,
                    color: isUserReaction ? Theme.of(context).colorScheme.onPrimaryContainer : null,
                  ),
                ),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isUserReaction
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Réagir',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EnhancedMessagingService.popularEmojis.map((emoji) {
              return GestureDetector(
                onTap: () => _addReaction(emoji),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleReaction(String emoji) {
    if (_userReaction == emoji) {
      // Retirer la réaction
      _removeReaction(emoji);
    } else {
      // Ajouter/remplacer la réaction
      _addReaction(emoji);
    }
  }

  void _addReaction(String emoji) async {
    setState(() {
      _userReaction = emoji;
      _showEmojiPicker = false;
    });

    final success = await EnhancedMessagingService.addReaction(
      matchId: widget.message.matchId,
      messageId: widget.message.id,
      emoji: emoji,
      userId: widget.currentUserId,
    );

    if (success && widget.onReactionAdded != null) {
      widget.onReactionAdded!(emoji);
    }
  }

  void _removeReaction(String emoji) async {
    setState(() {
      _userReaction = null;
    });

    final success = await EnhancedMessagingService.removeReaction(
      matchId: widget.message.matchId,
      messageId: widget.message.id,
      userId: widget.currentUserId,
    );

    if (success && widget.onReactionRemoved != null) {
      widget.onReactionRemoved!(emoji);
    }
  }
}

class ReactionButton extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final VoidCallback? onTap;

  const ReactionButton({super.key, required this.message, required this.currentUserId, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showReactionDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_reaction_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
            if (message.totalReactions > 0) ...[
              const SizedBox(width: 4),
              Text(
                message.totalReactions.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réagir au message'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1,
            ),
            itemCount: EnhancedMessagingService.popularEmojis.length,
            itemBuilder: (context, index) {
              final emoji = EnhancedMessagingService.popularEmojis[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  // Ajouter la réaction ici
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ],
      ),
    );
  }
}
