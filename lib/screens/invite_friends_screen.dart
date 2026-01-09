import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Veuillez entrer l\'email de votre ami');
      return;
    }

    if (!_emailController.text.contains('@')) {
      _showError('Veuillez entrer un email valide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileBox = Hive.box('profileBox');
      final currentUser = profileBox.get('currentUser');

      if (currentUser == null) {
        _showError('Vous devez être connecté pour envoyer des invitations');
        setState(() => _isLoading = false);
        return;
      }

      // Créer l'invitation
      final invitation = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fromUserId': currentUser['id'],
        'fromUserName': currentUser['name'],
        'toEmail': _emailController.text.trim(),
        'message': _messageController.text.trim().isEmpty
            ? 'Rejoins-moi sur JTM ! 🎉'
            : _messageController.text.trim(),
        'status': 'pending',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'type': 'friend_invite',
      };

      // Sauvegarder l'invitation
      final invitationsBox = Hive.box('invitationsBox');
      await invitationsBox.put(invitation['id'], invitation);

      // Simuler l'envoi d'email (pour le prototype)
      await Future.delayed(const Duration(seconds: 1));

      setState(() => _isLoading = false);

      _clearFields();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation envoyée avec succès ! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearFields() {
    _emailController.clear();
    _messageController.clear();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _shareInvitationLink() async {
    try {
      final profileBox = Hive.box('profileBox');
      final currentUser = profileBox.get('currentUser');

      if (currentUser == null) {
        _showError('Vous devez être connecté pour partager');
        return;
      }

      // Créer un lien d'invitation
      final inviteCode = currentUser['id'].toString();
      final inviteLink = 'https://jtm.app/invite/$inviteCode';

      // Simuler le partage (pour le prototype)
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lien d\'invitation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Votre code d\'invitation :'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  inviteCode,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Lien à partager :'),
              const SizedBox(height: 8),
              SelectableText(inviteLink, style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lien copié dans le presse-papiers ! 📋'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Copier'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Erreur lors du partage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Inviter des amis'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section invitation par email
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Inviter par email',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email de votre ami',
                        prefixIcon: const Icon(Icons.person_add),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'exemple@email.com',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message personnel (optionnel)',
                        prefixIcon: const Icon(Icons.message),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Rejoins-moi sur JTM !',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendInvitation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send),
                                  SizedBox(width: 8),
                                  Text('Envoyer l\'invitation'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section partage de lien
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Partager votre lien',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Invitez vos amis en partageant votre lien d\'invitation personnel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _shareInvitationLink,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link),
                            SizedBox(width: 8),
                            Text('Générer un lien d\'invitation'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section invitations envoyées
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Invitations récentes',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: Hive.openBox('invitationsBox'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final invitationsBox = snapshot.data;
                        if (invitationsBox == null) {
                          return const Text('Aucune invitation envoyée');
                        }

                        final invitations = invitationsBox.values.toList().cast<Map>();
                        final currentUser = Hive.box('profileBox').get('currentUser');

                        if (currentUser == null) {
                          return const Text('Connectez-vous pour voir vos invitations');
                        }

                        final userInvitations = invitations
                            .where((inv) => inv['fromUserId'] == currentUser['id'])
                            .toList()
                            .reversed
                            .take(5)
                            .toList();

                        if (userInvitations.isEmpty) {
                          return const Text('Aucune invitation envoyée');
                        }

                        return Column(
                          children: userInvitations.map((invitation) {
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  invitation['toEmail'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(invitation['toEmail']),
                              subtitle: Text(
                                invitation['message'] ?? 'Invitation JTM',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(invitation['status']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(invitation['status']),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      default:
        return 'Inconnu';
    }
  }
}
