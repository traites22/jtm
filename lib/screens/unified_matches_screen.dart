import 'package:flutter/material.dart';
import '../services/unified_match_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'unified_chat_screen.dart';

class UnifiedMatchesScreen extends StatefulWidget {
  const UnifiedMatchesScreen({super.key});

  @override
  State<UnifiedMatchesScreen> createState() => _UnifiedMatchesScreenState();
}

class _UnifiedMatchesScreenState extends State<UnifiedMatchesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: UnifiedMatchService.getEnrichedMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucun match pour le moment',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Continuez de swiper pour trouver des matches',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final user = match['user'] as UserModel;
              final lastMessage = match['lastMessage'] as String? ?? 'Nouveau match';
              final lastMessageTime = match['lastMessageTimeFormatted'] as String? ?? '';
              final unreadCount = match['unreadCount'] as int? ?? 0;
              final isOnline = match['isOnline'] as bool? ?? false;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: user.photos.isNotEmpty
                          ? NetworkImage(user.photos.first)
                          : null,
                      child: user.photos.isEmpty ? const Icon(Icons.person, size: 28) : null,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    if (lastMessageTime.isNotEmpty)
                      Text(
                        lastMessageTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UnifiedChatScreen(
                        matchId: match['matchId'] as String,
                        userName: user.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacementNamed('/swipe');
        },
        child: const Icon(Icons.explore),
        tooltip: 'Découvrir de nouveaux profils',
      ),
    );
  }
}
