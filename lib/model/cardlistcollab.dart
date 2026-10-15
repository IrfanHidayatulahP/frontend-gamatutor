class CardListCollab {
  String? collabId;
  String? cardId;
  String? userId;
  String? role; // 'owner' | 'member'
  DateTime? addedAt;

  CardListCollab({
    required this.collabId,
    required this.cardId,
    required this.userId,
    required this.role,
    required this.addedAt
  });

 factory CardListCollab.fromJson(Map<String, dynamic> json) {
    return CardListCollab(
      collabId: json['collab_id'] ?? '',
      cardId: json['card_id'] ?? '',
      userId: json['user_id'] ?? '',
      role: json['member'] ?? 'member',
      addedAt: json['added_at'] != null ? DateTime.parse(json['added_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collabId': collabId,
      'cardId': cardId,
      'userId': userId,
      'role': role,
      'addedAt': addedAt?.toIso8601String()
    };
  }
}