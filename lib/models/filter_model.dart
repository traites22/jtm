class FilterModel {
  final int minAge;
  final int maxAge;
  final int maxDistance; // en km
  final List<String> selectedGenders;
  final List<String> selectedInterests;
  final bool onlyVerified;
  final bool onlyOnline;

  const FilterModel({
    this.minAge = 18,
    this.maxAge = 100,
    this.maxDistance = 50,
    this.selectedGenders = const [],
    this.selectedInterests = const [],
    this.onlyVerified = false,
    this.onlyOnline = false,
  });

  // Conversion pour stockage Hive
  Map<String, dynamic> toMap() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
      'maxDistance': maxDistance,
      'selectedGenders': selectedGenders,
      'selectedInterests': selectedInterests,
      'onlyVerified': onlyVerified,
      'onlyOnline': onlyOnline,
    };
  }

  // Création depuis Map (Hive)
  factory FilterModel.fromMap(Map<String, dynamic> map) {
    return FilterModel(
      minAge: map['minAge'] ?? 18,
      maxAge: map['maxAge'] ?? 100,
      maxDistance: map['maxDistance'] ?? 50,
      selectedGenders: List<String>.from(map['selectedGenders'] ?? []),
      selectedInterests: List<String>.from(map['selectedInterests'] ?? []),
      onlyVerified: map['onlyVerified'] ?? false,
      onlyOnline: map['onlyOnline'] ?? false,
    );
  }

  // Copie avec modifications
  FilterModel copyWith({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<String>? selectedGenders,
    List<String>? selectedInterests,
    bool? onlyVerified,
    bool? onlyOnline,
  }) {
    return FilterModel(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      maxDistance: maxDistance ?? this.maxDistance,
      selectedGenders: selectedGenders ?? this.selectedGenders,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      onlyOnline: onlyOnline ?? this.onlyOnline,
    );
  }

  // Vérifier si les filtres sont actifs
  bool get hasActiveFilters {
    return minAge != 18 ||
        maxAge != 100 ||
        maxDistance != 50 ||
        selectedGenders.isNotEmpty ||
        selectedInterests.isNotEmpty ||
        onlyVerified ||
        onlyOnline;
  }

  // Réinitialiser les filtres
  FilterModel get reset => const FilterModel();
}
