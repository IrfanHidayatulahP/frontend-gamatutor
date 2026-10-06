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
      collabId: json['collabId'],
      cardId: json['cardId'],
      userId: json['userId'],
      role: json['role'],
      addedAt: DateTime.parse(json['addedAt'])
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