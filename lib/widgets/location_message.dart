import 'package:flutter/material.dart';
import '../models/message_model.dart';

class LocationMessage extends StatelessWidget {
  final MessageModel message;
  final bool isFromCurrentUser;

  const LocationMessage({super.key, required this.message, required this.isFromCurrentUser});

  @override
  Widget build(BuildContext context) {
    if (message.type != MessageType.location) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showLocationDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.locationName ?? 'Position partagée',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Stack(
                    children: [
                      // Carte simulée
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 32, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 4),
                            Text(
                              'Position partagée',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (message.latitude != null && message.longitude != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${message.latitude!.toStringAsFixed(4)}, ${message.longitude!.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Pointeur de position
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Le ${timestamp.day}/${timestamp.month}';
    }
  }

  void _showLocationDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Détails de la position'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.locationName ?? 'Position partagée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (message.latitude != null && message.longitude != null) ...[
              Text('Coordonnées:', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                'Latitude: ${message.latitude!.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Longitude: ${message.longitude!.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Text('Partagée le:', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.day}/${message.timestamp.month}/${message.timestamp.year} à ${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class LocationSharingButton extends StatelessWidget {
  final VoidCallback? onLocationShared;

  const LocationSharingButton({super.key, this.onLocationShared});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLocationDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager ma position'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Voulez-vous partager votre position actuelle ?', textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text(
              'Votre interlocuteur pourra voir votre position sur une carte.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onLocationShared != null) {
                onLocationShared!();
              }
            },
            child: const Text('Partager'),
          ),
        ],
      ),
    );
  }
}
