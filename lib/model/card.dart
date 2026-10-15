import 'package:gamatutor_kanban/model/columnmovement.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/model/cardlistcollab.dart';
class Card {
  String? cardId;
  String? userId;
  String? title;
  String nmMatkul;
  String learningId;
  String? description;
  String? courseName;
  String? difficulty;
  String? priority;
  DateTime deadline;
  String? url;
  DateTime? startTime;
  DateTime? endTime;
  bool deleted;

  // Evaluasi & Refleksi Mandiri
  double? satisfactionRating;
  String? notes;
  int? preTestGrade;
  int? postTestGrade;
  String? reflectionCompletedAt;
  DateTime? createdAt;

  List<CardList> subtasks;
  List<CardListCollab> collabList;
  List<ColumnMovement>? columnMovements;

  Card({
    required this.cardId,
    required this.userId,
    required this.nmMatkul,
    required this.title,
    required this.learningId,
    this.description,
    this.courseName,
    this.difficulty,
    this.priority,
    required this.deadline,
    this.url,
    this.startTime,
    this.endTime,
    this.deleted = false,
    this.satisfactionRating,
    this.notes,
    this.preTestGrade,
    this.postTestGrade,
    this.reflectionCompletedAt,
    this.createdAt,
    this.subtasks = const[],
    this.collabList = const[],
    this.columnMovements = const[]
  });

 /// Helper untuk menentukan posisi kolom Kanban berdasarkan alur timestamp skema DB
  String get computedColumn {
    if (reflectionCompletedAt != null) return 'reflection';
    if (endTime != null) return 'controlling';
    if (startTime != null) return 'monitoring';
    return 'planning';
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      cardId: json['card_id'] ?? '',
      userId: json['user_id'] ?? '',
      nmMatkul: json['NmMatkul'] ?? json['nm_matkul'] ?? '',
      title: json['title'] ?? '',
      learningId: json['learning_id'] ?? '',
      description: json['description'],
      courseName: json['course_name'],
      difficulty: json['difficulty'],
      priority: json['priority'],
      deadline: DateTime.parse(json['deadline'] ?? DateTime.now().toIso8601String()),
      url: json['url'],
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      deleted: json['deleted'] ?? false,
      satisfactionRating: json['satisfaction_rating'] != null ? double.tryParse(json['satisfaction_rating'].toString()) : null,
      notes: json['notes'],
      preTestGrade: json['pre_test_grade'],
      postTestGrade: json['post_test_grade'],
      reflectionCompletedAt: json['reflection_completed_at'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List).map((x) => CardList.fromJson(x)).toList()
          : [],
      collabList: json['collab_list'] != null
          ? (json['collab_list'] as List).map((x) => CardListCollab.fromJson(x)).toList()
          : [],
      columnMovements: (json['columnMovements'] ?? json['column_movements'] != null)
          ? ((json['columnMovements'] ?? json['column_movements']) as List)
              .map((item) => ColumnMovement.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'user_id': userId,
      'NmMatkul': nmMatkul,
      'title': title,
      'learning_id': learningId,
      'description': description,
      'course_name': courseName,
      'difficulty': difficulty,
      'priority': priority,
      'deadline': deadline.toIso8601String(),
      'url': url,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'deleted': deleted,
      'satisfaction_rating': satisfactionRating,
      'notes': notes,
      'pre_test_grade': preTestGrade,
      'post_test_grade': postTestGrade,
      'reflection_completed_at': reflectionCompletedAt,
      'created_at': createdAt?.toIso8601String(),
      'column_movements': columnMovements?.map((x) => x.toJson()).toList(),
    };
  }
}

