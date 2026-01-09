import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('À propos'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Fondateur
            _buildFounderCard(context),

            const SizedBox(height: 24),

            // Section Mission
            _buildMissionCard(context),

            const SizedBox(height: 24),

            // Section Avantages
            _buildAdvantagesCard(context),

            const SizedBox(height: 24),

            // Section Technologies
            _buildTechCard(context),

            const SizedBox(height: 24),

            // Section Contact
            _buildContactCard(context),

            const SizedBox(height: 32),

            // Version
            _buildVersionCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFounderCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Photo du fondateur
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 16),

            // Nom du fondateur
            Text(
              'Zala Aziz Farick',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Étudiant en Informatique à l\'IFOAD',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.withOpacity(0.4)),
            ),

            const SizedBox(height: 16),

            // Citation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"JTM a été conçue pour permettre aux jeunes de faire de nouvelles rencontres de manière simple, sécurisée et moderne."',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Notre Mission',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'JTM (Juste Toi et Moi) est une application de rencontre moderne créée pour révolutionner la façon dont les jeunes se connectent. Notre mission est de :',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ..._buildMissionPoints(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMissionPoints(BuildContext context) {
    final points = [
      '🎯 Faciliter les rencontres authentiques',
      '🛡️ Assurer la sécurité et la confidentialité',
      '📱 Offrir une expérience mobile moderne',
      '💬 Promouvoir des conversations significatives',
      '🌍 Connecter les jeunes du monde entier',
    ];

    return points
        .map(
          (point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Expanded(child: Text(point, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildAdvantagesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Pourquoi choisir JTM ?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildAdvantagePoints(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAdvantagePoints(BuildContext context) {
    final advantages = [
      {
        'icon': Icons.verified_user,
        'title': 'Profils Vérifiés',
        'description': 'Système de vérification pour garantir l\'authenticité des profils',
      },
      {
        'icon': Icons.security,
        'title': 'Sécurité Maximale',
        'description': 'Authentification biométrique et chiffrement de bout en bout',
      },
      {
        'icon': Icons.location_on,
        'title': 'Matching Intelligent',
        'description': 'Algorithme avancé pour des compatibilités précises',
      },
      {
        'icon': Icons.chat,
        'title': 'Chat en Temps Réel',
        'description': 'Messagerie instantanée avec notifications push',
      },
      {
        'icon': Icons.psychology,
        'title': 'Interface Intuitive',
        'description': 'Design moderne et expérience utilisateur optimisée',
      },
      {
        'icon': Icons.diversity_3,
        'title': 'Inclusivité',
        'description': 'Application ouverte à tous sans discrimination',
      },
    ];

    return advantages
        .map(
          (advantage) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    advantage['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        advantage['title'] as String,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        advantage['description'] as String,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildTechCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Technologies',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTechChip(context, 'Flutter', 'Framework UI'),
                _buildTechChip(context, 'Firebase', 'Backend & Auth'),
                _buildTechChip(context, 'Hive', 'Base de données'),
                _buildTechChip(context, 'Material 3', 'Design System'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechChip(BuildContext context, String tech, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            tech,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Contact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContactItem(context, Icons.email, 'zala.aziz.farik@jtm.app', 'Email'),
            const SizedBox(height: 12),
            _buildContactItem(context, Icons.language, '@zala_aziz_jtm', 'Instagram'),
            const SizedBox(height: 12),
            _buildContactItem(context, Icons.link, 'jtm.app', 'Site Web'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, IconData icon, String value, String label) {
    return InkWell(
      onTap: () {
        // Copier dans le presse-papiers
        // Pour un vrai projet, implémenter les actions appropriées
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label copié : $value'), backgroundColor: Colors.green),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.copy,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.info, color: primaryColor, size: 32),
            const SizedBox(height: 12),
            Text(
              'JTM',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: onSurfaceColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              ' 2024 Zala Aziz Farik - Tous droits réservés',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: onSurfaceColor.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implémenter la navigation vers le store
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bientôt disponible sur les stores !'),
                      backgroundColor: primaryColor,
                    ),
                  );
                },
                icon: const Icon(Icons.star),
                label: const Text('Noter JTM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
