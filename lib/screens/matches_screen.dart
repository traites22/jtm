import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _matchesBox = Hive.box('matchesBox');
  final _messagesBox = Hive.box('messagesBox');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match'),
        backgroundColor: Colors.pink[50],
        foregroundColor: Colors.pink[700],
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: _matchesBox.listenable(),
        builder: (context, Box box, _) {
          final matches = box.values.map((e) => Map<String, dynamic>.from(e)).toList();
          matches.sort((a, b) => (b['ts'] ?? 0).compareTo(a['ts'] ?? 0));

          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.pink[300]),
                  const SizedBox(height: 20),
                  Text(
                    'Aucun match pour le moment',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Swipez dans l\'onglet Découvrir pour trouver des profils',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final m = matches[i];
              final key = 'match:${m['id']}';
              final msgs = List<Map>.from(_messagesBox.get(key, defaultValue: []) as List);
              final last = msgs.isNotEmpty ? msgs.last['text'] : 'Matché';

              ImageProvider imageProvider;
              final p = m['photo'];
              if (p == null) {
                imageProvider = const AssetImage('assets/images/p1.jpg');
              } else if (p.toString().startsWith('assets/')) {
                imageProvider = AssetImage(p);
              } else {
                imageProvider = FileImage(File(p));
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                    child: ClipOval(
                      child: Image(
                        image: imageProvider,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, size: 28, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                  title: Text(
                    m['name'] ?? 'Utilisateur',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        last,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matché ${_formatDate(m['ts'])}',
                        style: TextStyle(
                          color: Colors.pink[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(color: Colors.pink[100], shape: BoxShape.circle),
                    child: IconButton(
                      icon: Icon(Icons.chat, color: Colors.pink[600]),
                      onPressed: () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ouverture du chat avec ${m['name']}'),
                              backgroundColor: Colors.pink[600],
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(matchId: m['id'] ?? '', matchName: m['name'] ?? ''),
                          ),
                        );
                      },
                    ),
                  ),
                  onTap: () {
                    // Ouvre directement la conversation au clic sur le match
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(matchId: m['id'] ?? '', matchName: m['name'] ?? ''),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'récemment';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} jours';
    } else {
      return 'le ${date.day}/${date.month}';
    }
  }
}
