import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/inbox_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _messagesBox = Hive.box('messagesBox');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildAvatar(String? p) {
    ImageProvider imageProvider;
    if (p == null)
      imageProvider = const AssetImage('assets/images/p1.jpg');
    else if (p.toString().startsWith('assets/'))
      imageProvider = AssetImage(p);
    else
      imageProvider = FileImage(File(p));

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: Image(
          image: imageProvider,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const Icon(Icons.person),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, {required bool showUnread}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final c = list[i];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                _buildAvatar(c['photo']),
                if (c['isOnline'] == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              c['name'] ?? c['id'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c['lastText'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  c['lastTime'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            trailing: showUnread && (c['unreadCount'] as int) > 0
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.pink.shade300, shape: BoxShape.circle),
                    child: Text(
                      c['unreadCount'].toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(matchId: c['id'], matchName: c['name'] ?? ''),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              // Toggle theme
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDarkMode ? Colors.pink.shade300 : Colors.blueAccent,
          labelColor: isDarkMode ? Colors.pink.shade300 : Colors.blueAccent,
          unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Reçus'),
            Tab(text: 'Envoyés'),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _messagesBox.listenable(),
        builder: (context, Box box, _) {
          final all = InboxService.getConversationsSync();
          final rec = all.where((c) => c['hasIncoming'] == true).toList();
          final sent = all.where((c) => c['hasOutgoing'] == true).toList();
          return TabBarView(
            controller: _tabController,
            children: [_buildList(rec, showUnread: true), _buildList(sent, showUnread: false)],
          );
        },
      ),
    );
  }
}
