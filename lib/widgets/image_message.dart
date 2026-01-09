import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';

class ImageMessage extends StatelessWidget {
  final MessageModel message;
  final bool isFromCurrentUser;

  const ImageMessage({super.key, required this.message, required this.isFromCurrentUser});

  @override
  Widget build(BuildContext context) {
    if (message.type != MessageType.image) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showFullImage(context),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildImage(),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (message.imagePath == null) {
      return Container(
        height: 200,
        width: 280,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image non disponible', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // Vérifier si c'est une image locale ou une URL
    final isLocalImage =
        message.imagePath!.startsWith('/') || message.imagePath!.startsWith('assets/');

    if (isLocalImage) {
      return Image.asset(
        message.imagePath!,
        height: 200,
        width: 280,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: 280,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Image non disponible', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      );
    } else {
      // Pour les images réseau (URL)
      return Container(
        height: 200,
        width: 280,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image réseau', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
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

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Background noir semi-transparent
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.black.withOpacity(0.8)),
            ),
            // Image en plein écran
            Center(child: InteractiveViewer(child: _buildFullScreenImage(context))),
            // Bouton de fermeture
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            // Informations sur l'image
            if (message.imagePath != null)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Image partagée',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFullTime(message.timestamp),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenImage(BuildContext context) {
    if (message.imagePath == null) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Image non disponible', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final isLocalImage =
        message.imagePath!.startsWith('/') || message.imagePath!.startsWith('assets/');

    if (isLocalImage) {
      return Image.asset(
        message.imagePath!,
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Image non disponible', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      );
    } else {
      return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Image réseau', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  String _formatFullTime(DateTime timestamp) {
    return 'Envoyée le ${timestamp.day}/${timestamp.month}/${timestamp.year} à ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class ImageSharingButton extends StatelessWidget {
  final Function(String)? onImageSelected;

  const ImageSharingButton({super.key, this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Icon(
          Icons.photo_library_outlined,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager une image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Choisissez une source pour votre image', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Appareil photo',
                  onTap: () => _selectImage(context, ImageSource.camera),
                ),
                _buildImageSourceOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () => _selectImage(context, ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ],
      ),
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
            ),
            child: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _selectImage(BuildContext context, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && onImageSelected != null) {
        onImageSelected!(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erreur lors de la sélection de l\'image')));
      }
    }
  }
}
