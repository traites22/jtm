import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';
import 'inbox_screen.dart';
import 'announcements_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _preview(String key) {
    final t = FuturisticTheme.getTheme(key);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: t.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.colorScheme.primary),
      ),
      child: Center(child: Text('Aperçu', style: t.textTheme.bodyMedium)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settingsBox');
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder(
          valueListenable: box.listenable(keys: ['theme']),
          builder: (context, Box b, _) {
            final selected = b.get('theme', defaultValue: FuturisticTheme.cyberNeonKey) as String;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Langue: Français'),
                const SizedBox(height: 12),
                const Text('Authentification locale activée'),
                const SizedBox(height: 24),
                const Text('Thème :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  value: FuturisticTheme.cyberNeonKey,
                  groupValue: selected,
                  title: const Text('Cyber Neon'),
                  subtitle: const Text('Bleu cyan + magenta, néon + glass'),
                  secondary: _preview(FuturisticTheme.cyberNeonKey),
                  onChanged: (v) => b.put('theme', v),
                ),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  value: FuturisticTheme.cyberpunkKey,
                  groupValue: selected,
                  title: const Text('Sombre Cyberpunk'),
                  subtitle: const Text('Noir profond + magenta + bleu'),
                  secondary: _preview(FuturisticTheme.cyberpunkKey),
                  onChanged: (v) => b.put('theme', v),
                ),
                // ignore: deprecated_member_use
                RadioListTile<String>(
                  value: FuturisticTheme.minimalGlassKey,
                  groupValue: selected,
                  title: const Text('Minimal Glass'),
                  subtitle: const Text('Pastels doux, glassmorphism discret'),
                  secondary: _preview(FuturisticTheme.minimalGlassKey),
                  onChanged: (v) => b.put('theme', v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: b.get('theme_animate', defaultValue: true) as bool,
                  title: const Text('Transition animée du thème'),
                  onChanged: (v) => b.put('theme_animate', v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Messages'),
                  subtitle: const Text('Voir les conversations reçues / envoyées'),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const InboxScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.announcement_outlined),
                  title: const Text('Annonces'),
                  subtitle: const Text('Publier et consulter les annonces'),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.phonelink_ring),
                  title: const Text('Afficher le token FCM'),
                  subtitle: const Text('Afficher / copier le token FCM stocké localement'),
                  onTap: () {
                    final token = Hive.box('settingsBox').get('fcm_token') as String?;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Token FCM'),
                        content: SelectableText(token ?? 'Aucun token trouvé'),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              if (token != null) {
                                await Clipboard.setData(ClipboardData(text: token));
                              }
                              Navigator.of(context).pop();
                            },
                            child: const Text('Copier'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Notification permission control (Android 13+)
                FutureBuilder<PermissionStatus>(
                  future: Permission.notification.status,
                  builder: (context, snap) {
                    final status = snap.data;
                    return ListTile(
                      leading: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Autoriser les notifications'),
                      subtitle: Text(
                        status == null
                            ? 'Vérifier le statut...'
                            : status.isGranted
                            ? 'Autorisé'
                            : 'Non autorisé',
                      ),
                      onTap: () async {
                        final result = await Permission.notification.request();
                        final message = result.isGranted
                            ? 'Notifications autorisées'
                            : 'Autorisation refusée';
                        // store the result locally for quick reference
                        Hive.box('settingsBox').put('notifications_granted', result.isGranted);
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Dernière notification
                Builder(
                  builder: (context) {
                    final last =
                        Hive.box('settingsBox').get('last_notification') as Map<dynamic, dynamic>?;
                    final title = last?['title'] ?? 'Aucune notification';
                    final body = last?['body'] ?? '';
                    final timeStr = (last != null && last['time'] is String)
                        ? (DateTime.tryParse(last['time'] as String)?.toLocal().toString() ?? '')
                        : '';
                    return ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Dernière notification'),
                      subtitle: Text('$title\n$body${timeStr.isNotEmpty ? '\n$timeStr' : ''}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          Hive.box('settingsBox').delete('last_notification');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Dernière notification supprimée')),
                            );
                          }
                          (context as Element).markNeedsBuild();
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
