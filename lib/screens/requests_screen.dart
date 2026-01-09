import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/messaging_service.dart';
import 'profile_detail_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _requestsBox = Hive.box('requestsBox');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de message')),
      body: ValueListenableBuilder(
        valueListenable: _requestsBox.listenable(keys: ['me']),
        builder: (context, Box box, _) {
          final list = List<Map>.from(box.get('me', defaultValue: []) as List);
          if (list.isEmpty) return const Center(child: Text('Aucune demande'));
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = list[i];
              final from = r['from'] as String? ?? 'Utilisateur';
              final text = r['text'] as String? ?? '';
              return ListTile(
                title: Text(from),
                subtitle: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailScreen(id: from, name: from, intro: text),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await MessagingService.respondToRequest(
                          toId: 'me',
                          fromId: from,
                          accept: true,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Demande acceptée')));
                        Navigator.of(context).pop();
                      },
                      child: const Text('Accepter'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await MessagingService.respondToRequest(
                          toId: 'me',
                          fromId: from,
                          accept: false,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Demande refusée')));
                      },
                      child: const Text('Refuser'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
