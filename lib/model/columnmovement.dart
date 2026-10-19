class ColumnMovement {
  String? ccmId;
  String? cardId;
  String? fromColumn;
  String? toColumn;
  DateTime? timestamp;
  bool? completed;

  ColumnMovement({
    required this.ccmId,
    required this.cardId,
    required this.fromColumn,
    required this.toColumn,
    required this.timestamp,
    required this.completed
  });
  
  factory ColumnMovement.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    return ColumnMovement(
      ccmId: (json['ccmId'] ?? json['ccm_id'])?.toString(),
      cardId: (json['cardId'] ?? json['card_id'])?.toString(),
      fromColumn: (json['fromColumn'] ?? json['from_column'])?.toString(),
      toColumn: (json['toColumn'] ?? json['to_column'])?.toString() ?? '',
      timestamp: rawTimestamp != null ? DateTime.tryParse(rawTimestamp.toString()) : null,
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ccmId': ccmId,
      'cardId': cardId,
      'fromColumn': fromColumn,
      'toColumn': toColumn,
      'timestamp': timestamp?.toIso8601String(),
      'completed': completed
    };
  }
}