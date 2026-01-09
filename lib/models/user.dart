class UserModel {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> photos; // local paths
  final List<String> interests; // tags d'intérêts
  final String? location; // ville ou région
  final double? latitude; // pour calculs de distance
  final double? longitude;
  final String gender; // 'homme', 'femme', 'autre'
  final String? lookingFor; // préférences de recherche
  final String? job; // profession
  final String? education; // formation
  final bool verified; // profil vérifié
  final DateTime? lastSeen; // dernière connexion
  final bool isOnline; // statut en ligne

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.photos,
    this.interests = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.gender = 'autre',
    this.lookingFor,
    this.job,
    this.education,
    this.verified = false,
    this.lastSeen,
    this.isOnline = false,
  });

  // Conversion pour stockage Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'photos': photos,
      'interests': interests,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'gender': gender,
      'lookingFor': lookingFor,
      'job': job,
      'education': education,
      'verified': verified,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isOnline': isOnline,
    };
  }

  // Création depuis Map (Hive)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      bio: map['bio'],
      photos: List<String>.from(map['photos'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      location: map['location'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      gender: map['gender'] ?? 'autre',
      lookingFor: map['lookingFor'],
      job: map['job'],
      education: map['education'],
      verified: map['verified'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
      isOnline: map['isOnline'] ?? false,
    );
  }

  // Copie avec modifications
  UserModel copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    List<String>? photos,
    List<String>? interests,
    String? location,
    double? latitude,
    double? longitude,
    String? gender,
    String? lookingFor,
    String? job,
    String? education,
    bool? verified,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      job: job ?? this.job,
      education: education ?? this.education,
      verified: verified ?? this.verified,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
