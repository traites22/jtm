import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/invitation_model.dart';
import '../services/messaging_service.dart';
import '../services/invitation_service.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String matchName;
  final bool autofocus;
  const ChatScreen({
    super.key,
    required this.matchId,
    required this.matchName,
    this.autofocus = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messagesBox = Hive.box('messagesBox');
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _checkThemeMode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final matchesBox = Hive.box('matchesBox');
      final exists = matchesBox.get(widget.matchId) != null;
      if (!exists) {
        // No match — inform and go back
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Vous ne pouvez pas discuter sans match')));
          Navigator.of(context).pop();
        }
        return;
      }

      // mark incoming messages as read
      await MessagingService.markAllRead(matchId: widget.matchId);

      // if requested, focus the input so user can start typing immediately
      if (widget.autofocus && mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _checkThemeMode() {
    final brightness = MediaQuery.of(context).platformBrightness;
    setState(() {
      _isDarkMode = brightness == Brightness.dark;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _showInvitationDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inviter quelqu\'un'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le nom d\'utilisateur à inviter:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final username = controller.text.trim();
                    if (username.isNotEmpty) {
                      await InvitationService.sendInvitation(
                        senderId: 'me',
                        receiverId: username,
                        type: InvitationType.chat,
                        message: 'Je vous invite à discuter sur JTM !',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invitation envoyée !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Inviter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final ok = await MessagingService.sendMessage(
      matchId: widget.matchId,
      sender: 'me',
      text: text,
    );
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Impossible d\'envoyer : pas de match')));
      }
      return;
    }

    _controller.clear();
    _scrollToBottom();

    // Simulate a simple auto-reply from the match after 1s
    Future.delayed(const Duration(seconds: 1), () async {
      await MessagingService.sendMessage(
        matchId: widget.matchId,
        sender: 'them',
        text: 'Merci pour ton message 😊',
      );
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTextChanged(String v) {
    if (!_isTyping) setState(() => _isTyping = true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isTyping = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = 'match:${widget.matchId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.matchName),
        backgroundColor: Colors.transparent,
        foregroundColor: _isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showInvitationDialog,
            tooltip: 'Inviter quelqu\'un',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _messagesBox.listenable(keys: [key]),
              builder: (context, Box box, _) {
                final messages = List<Map>.from(box.get(key, defaultValue: []) as List);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (c, i) {
                    final m = messages[i];
                    final isMe = m['sender'] == 'me';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? (_isDarkMode ? Colors.pink.shade300 : Colors.blueAccent)
                              : (_isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m['image'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: m['image'].toString().startsWith('assets/')
                                      ? Image.asset(
                                          m['image'],
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(m['image']),
                                          width: 180,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            if ((m['text'] ?? '').isNotEmpty)
                              Text(
                                m['text'] ?? '',
                                style: TextStyle(
                                  color: isMe
                                      ? (_isDarkMode ? Colors.white : Colors.white)
                                      : (_isDarkMode ? Colors.white : Colors.black),
                                  fontSize: 16,
                                ),
                              ),
                            const SizedBox(height: 6),
                            if (isMe)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    m['read'] == true ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color: isMe
                                        ? (_isDarkMode ? Colors.white70 : Colors.white70)
                                        : (_isDarkMode ? Colors.white70 : Colors.black54),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (m['read'] == true) ? 'Lu' : 'Envoyé',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? (_isDarkMode ? Colors.white70 : Colors.white70)
                                          : (_isDarkMode ? Colors.white70 : Colors.black54),
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
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: TextStyle(
                          color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.pink.shade300 : Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 75,
                        );
                        if (picked == null) return;
                        final sent = await MessagingService.sendMessage(
                          matchId: widget.matchId,
                          sender: 'me',
                          text: '',
                          imagePath: picked.path,
                        );
                        if (!sent && mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Échec envoi image')));
                        _scrollToBottom();
                      },
                      icon: const Icon(Icons.photo, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.pink.shade300 : Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
