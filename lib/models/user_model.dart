import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final String? phoneNumber;
  final List<String> photos;
  final String bio;
  final List<String> interests;
  final Map<String, double>? location; // latitude, longitude
  final Map<String, dynamic> preferences;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    this.phoneNumber,
    this.photos = const [],
    this.bio = '',
    this.interests = const [],
    this.location,
    this.preferences = const {},
    required this.isVerified,
    required this.createdAt,
    required this.lastActiveAt,
  });

  // Copie avec modification
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    List<String>? photos,
    String? bio,
    List<String>? interests,
    Map<String, double>? location,
    Map<String, dynamic>? preferences,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  // Convertir en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'photos': photos,
      'bio': bio,
      'interests': interests,
      'location': location,
      'preferences': preferences,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  // Créer depuis une Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Gestion sécurisée des timestamps
    DateTime createdAt;
    DateTime lastActiveAt;

    // Gérer createdAt
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      try {
        createdAt = DateTime.parse(map['createdAt']);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // Gérer lastActiveAt
    if (map['lastActiveAt'] is Timestamp) {
      lastActiveAt = (map['lastActiveAt'] as Timestamp).toDate();
    } else if (map['lastActiveAt'] is String) {
      try {
        lastActiveAt = DateTime.parse(map['lastActiveAt']);
      } catch (e) {
        lastActiveAt = DateTime.now();
      }
    } else if (map['lastActive'] != null) {
      lastActiveAt = DateTime.now();
    } else {
      lastActiveAt = DateTime.now();
    }

    return UserModel(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      phoneNumber: map['phoneNumber'],
      photos: List<String>.from(map['photos'] ?? []),
      bio: map['bio'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      location: map['location'] != null ? Map<String, double>.from(map['location']) : null,
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      isVerified: map['isVerified'] ?? false,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
