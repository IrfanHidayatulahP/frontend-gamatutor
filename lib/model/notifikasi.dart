class Notification {
  String? notifId;
  String? userId;
  String? type; // 'push' | 'smart_reminder' | 'social_presence' | 'encouragement'
  String? title;
  String? message;
  DateTime? sentAt;
  bool? delivered;
  String? deliveryError;
  DateTime? scheduledFor;
  String? reminderReason;
  String? triggerAction;
  String? triggerUserId;
  bool? read;
  DateTime? readAt;
  bool? clicked;
  DateTime? clickedAt;
  DateTime? createdAt;

  Notification({
    required this.notifId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.delivered,
    required this.deliveryError,
    required this.scheduledFor,
    required this.reminderReason,
    required this.triggerAction,
    required this.triggerUserId,
    required this.read,
    required this.readAt,
    required this.clicked,
    required this.clickedAt,
    required this.createdAt
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notifId: json['notifId'],
      userId: json['userId'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      delivered: json['delivered'],
      deliveryError: json['deliveryError'],
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : null,
      reminderReason: json['reminderReason'],
      triggerAction: json['triggerAction'],
      triggerUserId: json['triggerUserId'],
      read: json['read'],
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      clicked: json['clicked'],
      clickedAt: json['clickedAt'] != null ? DateTime.parse(json['clickedAt']) : null,
      createdAt: DateTime.parse(json['createdAt'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifId': notifId,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'sentAt': sentAt?.toIso8601String(),
      'delivered': delivered,
      'deliveryError': deliveryError,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'reminderReason': reminderReason,
      'triggerAction': triggerAction,
      'triggerUserId': triggerUserId,
      'read': read,
      'readAt': readAt?.toIso8601String(),
      'clicked': clicked,
      'clickedAt': clickedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String()
    };
  }
}