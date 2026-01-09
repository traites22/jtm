enum MessageType {
  text,
  image,
  location,
  system,
  audio, // Add a new value 'audio' to the MessageType enum
}

enum MessageStatus { sending, sent, delivered, read, failed }

class MessageModel {
  final String id;
  final String senderId;
  final String matchId;
  final MessageType type;
  final String? text;
  final String? imagePath;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime timestamp;
  final MessageStatus status;
  final Map<String, int> reactions; // emoji -> count
  final bool isDeleted;
  final DateTime? editedAt;
  final DateTime? readAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.matchId,
    required this.type,
    this.text,
    this.imagePath,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.reactions = const {},
    this.isDeleted = false,
    this.editedAt,
    this.readAt,
  });

  // Conversion pour stockage Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'matchId': matchId,
      'type': type.name,
      'text': text,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'reactions': reactions,
      'isDeleted': isDeleted,
      'editedAt': editedAt?.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  // Création depuis Map (Hive)
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      senderId: map['senderId'],
      matchId: map['matchId'],
      type: MessageType.values.firstWhere((e) => e.name == map['type']),
      text: map['text'],
      imagePath: map['imagePath'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['locationName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: MessageStatus.values.firstWhere((e) => e.name == map['status']),
      reactions: Map<String, int>.from(map['reactions'] ?? {}),
      isDeleted: map['isDeleted'] ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['editedAt'])
          : null,
      readAt: map['readAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['readAt']) : null,
    );
  }

  // Création d'un message texte
  factory MessageModel.text({
    required String id,
    required String senderId,
    required String matchId,
    required String text,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      matchId: matchId,
      type: MessageType.text,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // Création d'un message image
  factory MessageModel.image({
    required String id,
    required String senderId,
    required String matchId,
    required String imagePath,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      matchId: matchId,
      type: MessageType.image,
      imagePath: imagePath,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // Création d'un message localisation
  factory MessageModel.location({
    required String id,
    required String senderId,
    required String matchId,
    required double latitude,
    required double longitude,
    required String locationName,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      matchId: matchId,
      type: MessageType.location,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // Copie avec modifications
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? matchId,
    MessageType? type,
    String? text,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? timestamp,
    MessageStatus? status,
    Map<String, int>? reactions,
    bool? isDeleted,
    DateTime? editedAt,
    DateTime? readAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      matchId: matchId ?? this.matchId,
      type: type ?? this.type,
      text: text ?? this.text,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      editedAt: editedAt ?? this.editedAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Ajouter une réaction
  MessageModel addReaction(String emoji) {
    final newReactions = Map<String, int>.from(reactions);
    newReactions[emoji] = (newReactions[emoji] ?? 0) + 1;
    return copyWith(reactions: newReactions);
  }

  // Retirer une réaction
  MessageModel removeReaction(String emoji) {
    final newReactions = Map<String, int>.from(reactions);
    if (newReactions[emoji] != null) {
      newReactions[emoji] = newReactions[emoji]! - 1;
      if (newReactions[emoji]! <= 0) {
        newReactions.remove(emoji);
      }
    }
    return copyWith(reactions: newReactions);
  }

  // Marquer comme lu
  MessageModel markAsRead() {
    return copyWith(status: MessageStatus.read, readAt: DateTime.now());
  }

  // Marquer comme envoyé
  MessageModel markAsSent() {
    return copyWith(status: MessageStatus.sent);
  }

  // Marquer comme échoué
  MessageModel markAsFailed() {
    return copyWith(status: MessageStatus.failed);
  }

  // Éditer le message
  MessageModel edit(String newText) {
    return copyWith(text: newText, editedAt: DateTime.now());
  }

  // Supprimer le message
  MessageModel delete() {
    return copyWith(isDeleted: true);
  }

  // Vérifier si le message est du sender actuel
  bool isFromSender(String currentUserId) {
    return senderId == currentUserId;
  }

  // Obtenir le texte d'affichage
  String get displayText {
    if (isDeleted) return 'Message supprimé';

    switch (type) {
      case MessageType.text:
        return text ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.location:
        return '📍 $locationName';
      case MessageType.system:
        return text ?? '';
      case MessageType.audio:
        return '🎵 Message audio';
    }
  }

  // Vérifier si le message a des réactions
  bool get hasReactions => reactions.isNotEmpty;

  // Obtenir le nombre total de réactions
  int get totalReactions => reactions.values.fold(0, (sum, count) => sum + count);
}
