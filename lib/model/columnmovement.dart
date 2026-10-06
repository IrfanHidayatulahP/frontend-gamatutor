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
    return ColumnMovement(
      ccmId: json['ccmId'],
      cardId: json['cardId'],
      fromColumn: json['fromColumn'],
      toColumn: json['toColumn'],
      timestamp: DateTime.parse(json['timestamp']),
      completed: json['completed']
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