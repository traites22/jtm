import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ReadReceipts extends StatelessWidget {
  final MessageModel message;
  final String currentUserId;
  final Map<String, String>? userNames; // userId -> userName

  const ReadReceipts({
    super.key,
    required this.message,
    required this.currentUserId,
    this.userNames,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.isFromSender(currentUserId)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [_buildReadStatus(context)]),
    );
  }

  Widget _buildReadStatus(BuildContext context) {
    switch (message.status) {
      case MessageStatus.sending:
        return _buildStatusIndicator(
          context,
          icon: Icons.access_time,
          color: Theme.of(context).colorScheme.outline,
          label: 'Envoi en cours...',
        );
      case MessageStatus.sent:
        return _buildStatusIndicator(
          context,
          icon: Icons.done,
          color: Theme.of(context).colorScheme.outline,
          label: 'Envoyé',
        );
      case MessageStatus.delivered:
        return _buildStatusIndicator(
          context,
          icon: Icons.done_all,
          color: Theme.of(context).colorScheme.outline,
          label: 'Distribué',
        );
      case MessageStatus.read:
        return _buildReadIndicator(context);
      case MessageStatus.failed:
        return _buildStatusIndicator(
          context,
          icon: Icons.error,
          color: Colors.red,
          label: 'Échec de l\'envoi',
        );
    }
  }

  Widget _buildStatusIndicator(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildReadIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done_all, size: 12, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          'Lu',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue, fontSize: 10),
        ),
        if (message.readAt != null) ...[
          const SizedBox(width: 4),
          Text(
            _formatReadTime(message.readAt!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.blue.withOpacity(0.7), fontSize: 9),
          ),
        ],
      ],
    );
  }

  String _formatReadTime(DateTime readTime) {
    final now = DateTime.now();
    final difference = now.difference(readTime);

    if (difference.inMinutes < 1) {
      return 'à l\'instant';
    } else if (difference.inHours < 1) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'il y a ${difference.inHours}h';
    } else {
      return 'le ${readTime.day}/${readTime.month}';
    }
  }
}

class TypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final Map<String, String>? userNames;

  const TypingIndicator({super.key, required this.typingUsers, this.userNames});

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTypingDots(context),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getTypingText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 400 + (index * 100)),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  String _getTypingText() {
    final count = typingUsers.length;

    if (count == 1) {
      return 'Quelqu\'un écrit...';
    } else if (count == 2) {
      return 'Quelqu\'un écrit...';
    } else {
      return 'Plusieurs personnes écrivent...';
    }
  }
}

class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final DateTime? timestamp;
  final bool isRead;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.timestamp,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getStatusIcon(), size: 12, color: _getStatusColor(context)),
        if (timestamp != null) ...[
          const SizedBox(width: 4),
          Text(
            _formatTime(timestamp!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _getStatusColor(context), fontSize: 10),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (status) {
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

  Color _getStatusColor(BuildContext context) {
    if (status == MessageStatus.failed) {
      return Colors.red;
    }

    if (status == MessageStatus.read || isRead) {
      return Colors.blue;
    }

    return Theme.of(context).colorScheme.outline;
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
}

class OnlineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;

  const OnlineStatusIndicator({super.key, required this.isOnline, this.lastSeen});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _getStatusText(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isOnline ? Colors.green : Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getStatusText() {
    if (isOnline) {
      return 'En ligne';
    }

    if (lastSeen == null) {
      return 'Hors ligne';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return 'Il y a longtemps';
    }
  }
}
