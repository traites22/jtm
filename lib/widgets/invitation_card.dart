import 'package:flutter/material.dart';
import '../models/invitation_model.dart';
import '../services/invitation_service.dart';

class InvitationCard extends StatelessWidget {
  final InvitationModel invitation;
  final String currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final bool showActions;

  const InvitationCard({
    super.key,
    required this.invitation,
    required this.currentUserId,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isReceived = invitation.receiverId == currentUserId;
    final isSent = invitation.senderId == currentUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec type et statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: invitation.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(invitation.type.icon, color: invitation.type.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.type.frenchName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _getInvitationSubtitle(isReceived),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),

            const SizedBox(height: 12),

            // Message de l'invitation
            if (invitation.message != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                child: Text(invitation.message!, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 12),
            ],

            // Informations temporelles
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  _formatTime(invitation.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                if (invitation.expiresAt != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: invitation.isExpired
                        ? Colors.red
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    invitation.expiryText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: invitation.isExpired
                          ? Colors.red
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),

            // Actions
            if (showActions && _shouldShowActions(isReceived, isSent)) ...[
              const SizedBox(height: 16),
              _buildActionButtons(context, isReceived, isSent),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: invitation.status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(invitation.status.icon, size: 12, color: invitation.status.color),
          const SizedBox(width: 4),
          Text(
            invitation.status.frenchName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: invitation.status.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getInvitationSubtitle(bool isReceived) {
    if (isReceived) {
      return 'Invitation reçue';
    } else {
      return 'Invitation envoyée';
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
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return 'Le ${timestamp.day}/${timestamp.month}';
    }
  }

  bool _shouldShowActions(bool isReceived, bool isSent) {
    if (invitation.status.isFinal) return false;

    if (isReceived && invitation.canRespond) return true;
    if (isSent && invitation.status.isPending) return true;

    return false;
  }

  Widget _buildActionButtons(BuildContext context, bool isReceived, bool isSent) {
    if (isReceived) {
      return _buildReceivedActions(context);
    } else {
      return _buildSentActions(context);
    }
  }

  Widget _buildReceivedActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: invitation.canRespond ? onReject : null,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: invitation.canRespond ? onAccept : null,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Accepter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSentActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onCancel,
        icon: const Icon(Icons.not_interested, size: 16),
        label: const Text('Annuler l\'invitation'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange,
          side: const BorderSide(color: Colors.orange),
        ),
      ),
    );
  }
}

class InvitationsList extends StatefulWidget {
  final String currentUserId;
  final bool showReceivedOnly;
  final Function(InvitationModel)? onInvitationTap;

  const InvitationsList({
    super.key,
    required this.currentUserId,
    this.showReceivedOnly = false,
    this.onInvitationTap,
  });

  @override
  State<InvitationsList> createState() => _InvitationsListState();
}

class _InvitationsListState extends State<InvitationsList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvitationModel>>(
      future: _getInvitations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Erreur lors du chargement des invitations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          );
        }

        final invitations = snapshot.data!;

        if (invitations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  widget.showReceivedOnly ? 'Aucune invitation reçue' : 'Aucune invitation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.showReceivedOnly
                      ? 'Vous n\'avez reçu aucune invitation pour le moment'
                      : 'Vous n\'avez aucune invitation en cours',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshInvitations,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return InvitationCard(
                invitation: invitation,
                currentUserId: widget.currentUserId,
                onAccept: () => _handleAccept(invitation),
                onReject: () => _handleReject(invitation),
                onCancel: () => _handleCancel(invitation),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<InvitationModel>> _getInvitations() async {
    if (widget.showReceivedOnly) {
      return await InvitationService.getReceivedInvitations(widget.currentUserId);
    } else {
      final received = await InvitationService.getReceivedInvitations(widget.currentUserId);
      final sent = await InvitationService.getSentInvitations(widget.currentUserId);
      return [...received, ...sent];
    }
  }

  Future<void> _refreshInvitations() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {}); // Forcer le rafraîchissement
  }

  Future<void> _handleAccept(InvitationModel invitation) async {
    final success = await InvitationService.respondToInvitation(
      invitationId: invitation.id,
      accept: true,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation acceptée')));
      setState(() {}); // Rafraîchir la liste
    }
  }

  Future<void> _handleReject(InvitationModel invitation) async {
    final success = await InvitationService.respondToInvitation(
      invitationId: invitation.id,
      accept: false,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation refusée')));
      setState(() {}); // Rafraîchir la liste
    }
  }

  Future<void> _handleCancel(InvitationModel invitation) async {
    final success = await InvitationService.cancelInvitation(
      invitationId: invitation.id,
      userId: widget.currentUserId,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invitation annulée')));
      setState(() {}); // Rafraîchir la liste
    }
  }
}
