import 'package:flutter/material.dart';

enum InvitationStatus {
  pending, // En attente de réponse
  accepted, // Acceptée
  rejected, // Refusée
  expired, // Expirée
  cancelled, // Annulée
}

enum InvitationType {
  chat, // Invitation à discuter
  date, // Invitation à un rendez-vous
  event, // Invitation à un événement
  friendship, // Demande d'amitié
}

class InvitationModel {
  final String id;
  final String senderId;
  final String receiverId;
  final InvitationType type;
  final InvitationStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? respondedAt;
  final Map<String, dynamic>? metadata; // Données supplémentaires selon le type

  const InvitationModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.status,
    this.message,
    required this.createdAt,
    this.expiresAt,
    this.respondedAt,
    this.metadata,
  });

  // Constructeur pour créer une nouvelle invitation
  factory InvitationModel.create({
    required String senderId,
    required String receiverId,
    required InvitationType type,
    String? message,
    Map<String, dynamic>? metadata,
    Duration? expiryDuration,
  }) {
    return InvitationModel(
      id: _generateId(),
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      status: InvitationStatus.pending,
      message: message,
      createdAt: DateTime.now(),
      expiresAt: expiryDuration != null ? DateTime.now().add(expiryDuration) : null,
      metadata: metadata,
    );
  }

  // Copie avec modification
  InvitationModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    InvitationType? type,
    InvitationStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    Map<String, dynamic>? metadata,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Accepter l'invitation
  InvitationModel accept() {
    return copyWith(status: InvitationStatus.accepted, respondedAt: DateTime.now());
  }

  // Refuser l'invitation
  InvitationModel reject() {
    return copyWith(status: InvitationStatus.rejected, respondedAt: DateTime.now());
  }

  // Annuler l'invitation
  InvitationModel cancel() {
    return copyWith(status: InvitationStatus.cancelled, respondedAt: DateTime.now());
  }

  // Vérifier si l'invitation est expirée
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Vérifier si l'invitation est toujours valide
  bool get isValid {
    return !isExpired && status == InvitationStatus.pending;
  }

  // Vérifier si l'invitation peut être répondue
  bool get canRespond {
    return status == InvitationStatus.pending && !isExpired;
  }

  // Obtenir le temps restant avant expiration
  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }

  // Obtenir le texte d'expiration
  String get expiryText {
    if (expiresAt == null) return '';

    final timeLeft = timeUntilExpiry!;
    if (timeLeft.isNegative) return 'Expirée';

    if (timeLeft.inDays > 0) {
      return 'Expire dans ${timeLeft.inDays}j';
    } else if (timeLeft.inHours > 0) {
      return 'Expire dans ${timeLeft.inHours}h';
    } else if (timeLeft.inMinutes > 0) {
      return 'Expire dans ${timeLeft.inMinutes}min';
    } else {
      return 'Expire dans quelques instants';
    }
  }

  // Convertir en Map pour le stockage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'status': status.name,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Créer depuis une Map
  factory InvitationModel.fromMap(Map<String, dynamic> map) {
    return InvitationModel(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      type: InvitationType.values.firstWhere((e) => e.name == map['type']),
      status: InvitationStatus.values.firstWhere((e) => e.name == map['status']),
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
      respondedAt: map['respondedAt'] != null ? DateTime.parse(map['respondedAt']) : null,
      metadata: map['metadata'],
    );
  }

  // Générer un ID unique
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  @override
  String toString() {
    return 'InvitationModel(id: $id, type: $type, status: $status, senderId: $senderId, receiverId: $receiverId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvitationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extensions pour les types d'invitation
extension InvitationTypeExtension on InvitationType {
  String get frenchName {
    switch (this) {
      case InvitationType.chat:
        return 'Discussion';
      case InvitationType.date:
        return 'Rendez-vous';
      case InvitationType.event:
        return 'Événement';
      case InvitationType.friendship:
        return 'Amitié';
    }
  }

  String get description {
    switch (this) {
      case InvitationType.chat:
        return 'Veut discuter avec vous';
      case InvitationType.date:
        return 'Vous propose un rendez-vous';
      case InvitationType.event:
        return 'Vous invite à un événement';
      case InvitationType.friendship:
        return 'Veut devenir votre ami(e)';
    }
  }

  IconData get icon {
    switch (this) {
      case InvitationType.chat:
        return Icons.chat;
      case InvitationType.date:
        return Icons.favorite;
      case InvitationType.event:
        return Icons.event;
      case InvitationType.friendship:
        return Icons.person_add;
    }
  }

  Color get color {
    switch (this) {
      case InvitationType.chat:
        return Colors.blue;
      case InvitationType.date:
        return Colors.pink;
      case InvitationType.event:
        return Colors.purple;
      case InvitationType.friendship:
        return Colors.green;
    }
  }
}

// Extensions pour les statuts d'invitation
extension InvitationStatusExtension on InvitationStatus {
  String get frenchName {
    switch (this) {
      case InvitationStatus.pending:
        return 'En attente';
      case InvitationStatus.accepted:
        return 'Acceptée';
      case InvitationStatus.rejected:
        return 'Refusée';
      case InvitationStatus.expired:
        return 'Expirée';
      case InvitationStatus.cancelled:
        return 'Annulée';
    }
  }

  String get description {
    switch (this) {
      case InvitationStatus.pending:
        return 'En attente de réponse';
      case InvitationStatus.accepted:
        return 'Invitation acceptée';
      case InvitationStatus.rejected:
        return 'Invitation refusée';
      case InvitationStatus.expired:
        return 'Invitation expirée';
      case InvitationStatus.cancelled:
        return 'Invitation annulée';
    }
  }

  IconData get icon {
    switch (this) {
      case InvitationStatus.pending:
        return Icons.schedule;
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.rejected:
        return Icons.cancel;
      case InvitationStatus.expired:
        return Icons.timer_off;
      case InvitationStatus.cancelled:
        return Icons.not_interested;
    }
  }

  Color get color {
    switch (this) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.rejected:
        return Colors.red;
      case InvitationStatus.expired:
        return Colors.grey;
      case InvitationStatus.cancelled:
        return Colors.grey;
    }
  }

  bool get isPending => this == InvitationStatus.pending;
  bool get isAccepted => this == InvitationStatus.accepted;
  bool get isRejected => this == InvitationStatus.rejected;
  bool get isExpired => this == InvitationStatus.expired;
  bool get isCancelled => this == InvitationStatus.cancelled;
  bool get isFinal => [
    InvitationStatus.accepted,
    InvitationStatus.rejected,
    InvitationStatus.expired,
    InvitationStatus.cancelled,
  ].contains(this);
}
