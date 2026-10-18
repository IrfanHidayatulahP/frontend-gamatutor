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
    final rawAddedAt = json['addedAt'] ?? json['added_At'];
    return CardListCollab(
      collabId: (json['collabId'] ?? json['collab_id'])?.toString(),
      cardId: (json['cardId'] ?? json['card_id'])?.toString(),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      role: json['role']?.toString() ?? json['member']?.toString() ?? 'member',
      addedAt: rawAddedAt != null ? DateTime.tryParse(rawAddedAt.toString()) : null,
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