import 'package:flutter/material.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';
import '../widgets/interest_tags.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late FilterModel _filters;
  int _minAge = 18;
  int _maxAge = 100;
  int _maxDistance = 50;

  @override
  void initState() {
    super.initState();
    _filters = FilterService.getFilters();
    _minAge = _filters.minAge;
    _maxAge = _filters.maxAge;
    _maxDistance = _filters.maxDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres de recherche'),
        actions: [TextButton(onPressed: _resetFilters, child: const Text('Réinitialiser'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Âge
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Âge', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Minimum: $_minAge ans'),
                              Slider(
                                value: _minAge.toDouble(),
                                min: 18,
                                max: 99,
                                divisions: 81,
                                onChanged: (value) {
                                  setState(() {
                                    _minAge = value.round();
                                    if (_minAge > _maxAge) {
                                      _maxAge = _minAge;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Maximum: $_maxAge ans'),
                              Slider(
                                value: _maxAge.toDouble(),
                                min: 19,
                                max: 100,
                                divisions: 81,
                                onChanged: (value) {
                                  setState(() {
                                    _maxAge = value.round();
                                    if (_maxAge < _minAge) {
                                      _minAge = _maxAge;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Distance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance maximum', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('$_maxDistance km'),
                      ],
                    ),
                    Slider(
                      value: _maxDistance.toDouble(),
                      min: 5,
                      max: 200,
                      divisions: 39,
                      onChanged: (value) {
                        setState(() {
                          _maxDistance = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5 km', style: Theme.of(context).textTheme.bodySmall),
                        Text('200 km', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Genre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Genre', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Homme'),
                          selected: _filters.selectedGenders.contains('homme'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _filters = _filters.copyWith(
                                  selectedGenders: [..._filters.selectedGenders, 'homme'],
                                );
                              } else {
                                _filters = _filters.copyWith(
                                  selectedGenders: _filters.selectedGenders
                                      .where((g) => g != 'homme')
                                      .toList(),
                                );
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Femme'),
                          selected: _filters.selectedGenders.contains('femme'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _filters = _filters.copyWith(
                                  selectedGenders: [..._filters.selectedGenders, 'femme'],
                                );
                              } else {
                                _filters = _filters.copyWith(
                                  selectedGenders: _filters.selectedGenders
                                      .where((g) => g != 'femme')
                                      .toList(),
                                );
                              }
                            });
                          },
                        ),
                        FilterChip(
                          label: const Text('Autre'),
                          selected: _filters.selectedGenders.contains('autre'),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _filters = _filters.copyWith(
                                  selectedGenders: [..._filters.selectedGenders, 'autre'],
                                );
                              } else {
                                _filters = _filters.copyWith(
                                  selectedGenders: _filters.selectedGenders
                                      .where((g) => g != 'autre')
                                      .toList(),
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Intérêts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InterestTags(
                  selectedInterests: _filters.selectedInterests,
                  onInterestAdded: (interest) {
                    setState(() {
                      _filters = _filters.copyWith(
                        selectedInterests: [..._filters.selectedInterests, interest],
                      );
                    });
                  },
                  onInterestRemoved: (interest) {
                    setState(() {
                      _filters = _filters.copyWith(
                        selectedInterests: _filters.selectedInterests
                            .where((i) => i != interest)
                            .toList(),
                      );
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Options supplémentaires
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Options', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Profils vérifiés uniquement'),
                      subtitle: const Text(
                        'Afficher seulement les profils avec badge de vérification',
                      ),
                      value: _filters.onlyVerified,
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(onlyVerified: value ?? false);
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('En ligne uniquement'),
                      subtitle: const Text('Afficher seulement les profils actuellement connectés'),
                      value: _filters.onlyOnline,
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(onlyOnline: value ?? false);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = const FilterModel();
      _minAge = 18;
      _maxAge = 100;
      _maxDistance = 50;
    });
  }

  void _applyFilters() async {
    final updatedFilters = _filters.copyWith(
      minAge: _minAge,
      maxAge: _maxAge,
      maxDistance: _maxDistance,
    );

    await FilterService.saveFilters(updatedFilters);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Filtres appliqués avec succès!')));
      Navigator.of(context).pop(true);
    }
  }
}
