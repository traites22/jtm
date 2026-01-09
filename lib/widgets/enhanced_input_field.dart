import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/enhanced_messaging_service.dart';
import 'location_message.dart';
import 'image_message.dart';

class EnhancedInputField extends StatefulWidget {
  final String matchId;
  final String currentUserId;
  final Function(String) onMessageSent;
  final Function(String)? onLocationShared;
  final Function(String)? onImageShared;

  const EnhancedInputField({
    super.key,
    required this.matchId,
    required this.currentUserId,
    required this.onMessageSent,
    this.onLocationShared,
    this.onImageShared,
  });

  @override
  State<EnhancedInputField> createState() => _EnhancedInputFieldState();
}

class _EnhancedInputFieldState extends State<EnhancedInputField> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  List<String> _typingUsers = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _loadTypingUsers();
  }

  void _loadTypingUsers() async {
    final users = await EnhancedMessagingService.getTypingUsers(widget.matchId);
    if (mounted) {
      setState(() {
        _typingUsers = users.where((userId) => userId != widget.currentUserId).toList();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _isTyping) {
      setState(() {
        _isTyping = _focusNode.hasFocus;
      });

      // Notifier le statut "en train d'écrire"
      EnhancedMessagingService.setTyping(
        matchId: widget.matchId,
        userId: widget.currentUserId,
        isTyping: _focusNode.hasFocus && _textController.text.isNotEmpty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Indicateur "en train d'écrire"
          if (_typingUsers.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTypingText(_typingUsers),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Champ de saisie principal
          Row(
            children: [
              // Bouton pour les options avancées
              PopupMenuButton<String>(
                icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                onSelected: (value) => _handleMenuAction(value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'image',
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_outlined),
                        const SizedBox(width: 8),
                        Text('Photo'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'location',
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined),
                        const SizedBox(width: 8),
                        Text('Localisation'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'emoji',
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_emotions_outlined),
                        const SizedBox(width: 8),
                        Text('Emoji'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Champ de texte
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: 'Écrivez un message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) => _sendMessage(),
                ),
              ),

              const SizedBox(width: 8),

              // Bouton d'envoi
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: _textController.text.isNotEmpty ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTextChanged(String text) {
    // Notifier le statut "en train d'écrire"
    EnhancedMessagingService.setTyping(
      matchId: widget.matchId,
      userId: widget.currentUserId,
      isTyping: text.isNotEmpty,
    );
    _updateTypingUsers();
  }

  void _updateTypingUsers() async {
    final users = await EnhancedMessagingService.getTypingUsers(widget.matchId);
    if (mounted) {
      setState(() {
        _typingUsers = users.where((userId) => userId != widget.currentUserId).toList();
      });
    }
  }

  String _getTypingText(List<String> typingUsers) {
    if (typingUsers.isEmpty) return '';

    if (typingUsers.length == 1) {
      return 'Quelqu\'un écrit...';
    } else if (typingUsers.length == 2) {
      return 'Quelqu\'un écrit...';
    } else {
      return 'Plusieurs personnes écrivent...';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'image':
        _showImagePicker();
        break;
      case 'location':
        _shareLocation();
        break;
      case 'emoji':
        _showEmojiPicker();
        break;
    }
  }

  void _showImagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir une source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Appareil photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final success = await EnhancedMessagingService.sendImageMessage(
          matchId: widget.matchId,
          senderId: widget.currentUserId,
          imagePath: image.path,
        );

        if (success && widget.onImageShared != null) {
          widget.onImageShared!(image.path);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur lors de la sélection de l\'image')));
    }
  }

  void _shareLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager ma position'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Voulez-vous partager votre position actuelle ?'),
            SizedBox(height: 8),
            Text(
              'Votre interlocuteur pourra voir votre position sur une carte.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendLocationMessage();
            },
            child: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendLocationMessage() async {
    final success = await EnhancedMessagingService.sendLocationMessage(
      matchId: widget.matchId,
      senderId: widget.currentUserId,
      // Utiliser des coordonnées par défaut (Paris)
      latitude: 48.8566,
      longitude: 2.3522,
      locationName: 'Position actuelle',
    );

    if (success && widget.onLocationShared != null) {
      widget.onLocationShared!('Position partagée');
    }
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un emoji'),
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
                  _insertEmoji(emoji);
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final currentText = _textController.text;
    final cursorPosition = _textController.selection.baseOffset;
    final newText =
        currentText.substring(0, cursorPosition) + emoji + currentText.substring(cursorPosition);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition + emoji.length),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final success = await EnhancedMessagingService.sendTextMessage(
      matchId: widget.matchId,
      senderId: widget.currentUserId,
      text: text,
    );

    if (success) {
      _textController.clear();
      widget.onMessageSent(text);

      // Notifier que l'utilisateur a arrêté d'écrire
      EnhancedMessagingService.setTyping(
        matchId: widget.matchId,
        userId: widget.currentUserId,
        isTyping: false,
      );
    }
  }
}
