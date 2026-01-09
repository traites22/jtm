import 'package:flutter/material.dart';

class InterestTags extends StatefulWidget {
  final List<String> selectedInterests;
  final Function(String) onInterestAdded;
  final Function(String) onInterestRemoved;
  final bool isEditable;

  const InterestTags({
    super.key,
    required this.selectedInterests,
    required this.onInterestAdded,
    required this.onInterestRemoved,
    this.isEditable = true,
  });

  @override
  State<InterestTags> createState() => _InterestTagsState();
}

class _InterestTagsState extends State<InterestTags> {
  final TextEditingController _tagController = TextEditingController();

  // Suggestions d'intérêts populaires
  static const List<String> _suggestions = [
    'Voyages',
    'Musique',
    'Cuisine',
    'Sport',
    'Cinéma',
    'Lecture',
    'Photo',
    'Danse',
    'Art',
    'Technologie',
    'Jeux vidéo',
    'Nature',
    'Randonnée',
    'Yoga',
    'Méditation',
    'Animaux',
    'Mode',
    'Architecture',
    'Théâtre',
    'Concerts',
    'Festivals',
    'Volontariat',
    'Entrepreneuriat',
    'Science',
    'Histoire',
    'Langues',
    'Jardinage',
    'Bricolage',
    'Astronomie',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intérêts (${widget.selectedInterests.length}/10)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        // Tags sélectionnés
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.selectedInterests.map((interest) {
            return Chip(
              label: Text(interest),
              onDeleted: widget.isEditable ? () => widget.onInterestRemoved(interest) : null,
              deleteIcon: widget.isEditable ? const Icon(Icons.close, size: 16) : null,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        if (widget.isEditable) ...[
          // Champ pour ajouter un intérêt
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: 'Ajouter un intérêt',
                    hintText: 'Ex: Voyages, Musique...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && widget.selectedInterests.length < 10) {
                      widget.onInterestAdded(value.trim());
                      _tagController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final value = _tagController.text.trim();
                  if (value.isNotEmpty && widget.selectedInterests.length < 10) {
                    widget.onInterestAdded(value);
                    _tagController.clear();
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Suggestions
          if (widget.selectedInterests.length < 10) ...[
            Text('Suggestions populaires:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .where((suggestion) {
                    return !widget.selectedInterests.contains(suggestion.toLowerCase());
                  })
                  .take(12)
                  .map((suggestion) {
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: widget.selectedInterests.length < 10
                          ? () => widget.onInterestAdded(suggestion)
                          : null,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    );
                  })
                  .toList(),
            ),
          ],
        ],
      ],
    );
  }
}
