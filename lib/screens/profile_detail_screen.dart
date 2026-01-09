import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/messaging_service.dart';

class ProfileDetailScreen extends StatelessWidget {
  final String id;
  final String name;
  final String intro;
  final String? photoPath;
  final int? age;

  const ProfileDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.intro,
    this.photoPath,
    this.age,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: photoPath != null && photoPath!.startsWith('assets/')
                    ? Image.asset(
                        photoPath!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 48),
                      )
                    : (photoPath != null
                          ? Image.file(
                              File(photoPath!),
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 48),
                            )
                          : Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: const TextStyle(fontSize: 32),
                            )),
              ),
            ),
            const SizedBox(height: 24),
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            if (age != null) ...[
              const SizedBox(height: 8),
              Text('$age ans', style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Text(intro, textAlign: TextAlign.center),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: Hive.box('requestsBox').listenable(keys: [id]),
              builder: (context, Box box, _) {
                final list = List<Map>.from(box.get(id, defaultValue: []) as List);
                final pending = list.any((r) => r['from'] == 'me' && r['status'] == 'pending');
                if (pending) {
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Demande envoyée'),
                    onPressed: null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  );
                }
                return ElevatedButton.icon(
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Envoyer une demande'),
                  onPressed: () => _showSendDialog(context),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await MessagingService.respondToRequest(toId: 'me', fromId: id, accept: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Demande acceptée')));
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Accepter'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await MessagingService.respondToRequest(toId: 'me', fromId: id, accept: false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Demande refusée')));
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Refuser'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSendDialog(BuildContext context) {
    final TextEditingController txt = TextEditingController(
      text: 'Salut, ça te dit de discuter ?',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer une demande'),
        content: TextField(
          controller: txt,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Message...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final ok = await MessagingService.sendRequest(
                from: 'me',
                toId: id,
                text: txt.text.trim(),
              );
              if (context.mounted) {
                if (ok) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Demande envoyée')));
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Demande déjà envoyée')));
                }
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
