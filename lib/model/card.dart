import 'package:gamatutor_kanban/model/columnmovement.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/model/cardlistcollab.dart';

class Card {
  String? cardId;
  String? userId;
  String? title;
  String? learningId;
  String? description;
  String? courseName;
  String? difficulty;
  String? priority;
  DateTime? deadline;
  String? url;
  DateTime? startTime;
  DateTime? endTime;
  bool? deleted;

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
    this.cardId,
    this.userId,
    this.title,
    this.learningId,
    this.description,
    this.courseName,
    this.difficulty,
    this.priority,
    this.deadline,
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
    this.subtasks = const [],
    this.collabList = const [],
    this.columnMovements = const [],
  });

  /// Helper untuk memecah string URL bernilai koma/multivalue menjadi List<String>
  List<String> get urlList {
    if (url == null || url!.trim().isEmpty) return [];
    return url!
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
  }

  /// Helper untuk mengambil jumlah URL/lampiran yang ada
  int get urlCount => urlList.length;

  /// Helper untuk menentukan posisi kolom Kanban berdasarkan alur timestamp skema DB
  String get computedColumn {
    if (reflectionCompletedAt != null && reflectionCompletedAt!.isNotEmpty) {
      return 'reflection';
    }
    if (endTime != null) return 'controlling';
    if (startTime != null && endTime == null) return 'monitoring';
    return 'planning';
  }

  factory Card.fromJson(Map<String, dynamic> json) {
    // Helper aman untuk parsing DateTime
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    // Helper internal untuk memecah subTitle jika mengandung koma (multivalue)
    List<CardList> processSubtaskItem(Map<String, dynamic> item) {
      final String? clId = (item['clId'] ?? item['cl_Id'])?.toString();
      final String? cId = (item['cardId'] ?? item['card_id'])?.toString();
      final String rawSubTitle =
          (item['subTitle'] ?? item['sub_title'])?.toString() ?? '';
      final rawEndTime = item['endTimeList'] ?? item['end_time_list'];
      final DateTime? endTimeParsed = rawEndTime != null
          ? parseDate(rawEndTime)
          : null;
      final rawStartTime = item['startTimeList'] ?? item['start_time_list'];
      final DateTime? startTimeParsed = rawStartTime != null ? parseDate(rawStartTime) : null;

      if (rawSubTitle.contains(',')) {
        return rawSubTitle
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map(
              (s) => CardList(
                clId: clId,
                cardId: cId,
                subTitle: s,
                startTimeList: startTimeParsed,
                endTimeList: endTimeParsed,
              ),
            )
            .toList();
      } else {
        return [
          CardList(
            clId: clId,
            cardId: cId,
            subTitle: rawSubTitle,
            startTimeList: startTimeParsed,
            endTimeList: endTimeParsed,
          ),
        ];
      }
    }

    // Tangani cardList / subtasks
    List<CardList> parsedSubtasks = [];
    final rawSubtasks =
        json['cardList'] ?? json['card_list'] ?? json['subtasks'];

    if (rawSubtasks != null) {
      List items = rawSubtasks is List ? rawSubtasks : [rawSubtasks];
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          final String? clId = (item['clId'] ?? item['cl_id'])?.toString();
          final String? cId = (item['cardId'] ?? item['card_id'])?.toString();
          final String rawSubTitle =
              (item['subTitle'] ?? item['sub_title'])?.toString() ?? '';

          final rawEndTime = item['endTimeList'] ?? item['end_time_list'];
          final DateTime? endTimeParsed = rawEndTime != null
              ? parseDate(rawEndTime)
              : null;
          
          final rawStartTime = item['startTimeList'] ?? item['start_time_list'];
          final DateTime? startTimeParsed = rawStartTime != null ? parseDate(rawStartTime) : null;

          // Jika subTitle di dalam database ternyata berisi koma (multi-value string lama)
          if (rawSubTitle.contains(',')) {
            for (var titlePart in rawSubTitle.split(',')) {
              if (titlePart.trim().isNotEmpty) {
                parsedSubtasks.add(
                  CardList(
                    clId: clId,
                    cardId: cId,
                    subTitle: titlePart.trim(),
                    startTimeList: startTimeParsed,
                    endTimeList: endTimeParsed,
                  ),
                );
              }
            }
          } else if (rawSubTitle.isNotEmpty) {
            parsedSubtasks.add(
              CardList(
                clId: clId,
                cardId: cId,
                subTitle: rawSubTitle,
                startTimeList: startTimeParsed,
                endTimeList: endTimeParsed,
              ),
            );
          }
        }
      }
    }

    // Tangani kolaborasi
    List<CardListCollab> parsedCollab = [];
    final rawCollab = json['collaborations'] ?? json['collab_list'];
    if (rawCollab != null && rawCollab is List) {
      parsedCollab = rawCollab.map((x) => CardListCollab.fromJson(x)).toList();
    }

    // Tangani column movements
    List<ColumnMovement> parsedMovements = [];
    final rawMovements = json['columnMovements'] ?? json['column_movements'];
    if (rawMovements != null && rawMovements is List) {
      parsedMovements = rawMovements
          .map((item) => ColumnMovement.fromJson(item))
          .toList();
    }

    DateTime? parsDate(dynamic value, {bool onlyDate = false}) {
      if (value == null) return null;
      try {
        final parsed = DateTime.parse(value.toString());
        if (onlyDate) {
          return DateTime(parsed.year, parsed.month, parsed.day);
        } else {
          return parsed.toLocal();
        }
      } catch (_) {
        return null;
      }
    }

    return Card(
      cardId: (json['cardId'] ?? json['card_id'])?.toString(),
      userId: (json['userId'] ?? json['user_id'])?.toString(),
      title: (json['title'])?.toString(),
      learningId: (json['learningId'] ?? json['learning_id'])?.toString(),
      description: (json['description'])?.toString(),
      courseName: (json['courseName'] ?? json['course_name'])?.toString(),
      difficulty: (json['difficulty'])?.toString(),
      priority: (json['priority'])?.toString(),

      deadline: parsDate(json['deadline'], onlyDate: true) ?? DateTime.now(),
      url: (json['url'])?.toString(),

      startTime: parseDate(json['startTime'] ?? json['start_time']),
      endTime: parseDate(json['endTime'] ?? json['end_time']),

      deleted: json['deleted'] ?? false,
      satisfactionRating: json['satisfactionRating'] != null
          ? double.tryParse(json['satisfactionRating'].toString())
          : (json['satisfaction_rating'] != null
                ? double.tryParse(json['satisfaction_rating'].toString())
                : null),
      notes: (json['notes'])?.toString(),
      preTestGrade: json['preTestGrade'] != null
          ? int.tryParse(json['preTestGrade'].toString())
          : (json['pre_test_grade'] != null
                ? int.tryParse(json['pre_test_grade'].toString())
                : null),
      postTestGrade: json['postTestGrade'] != null
          ? int.tryParse(json['postTestGrade'].toString())
          : (json['post_test_grade'] != null
                ? int.tryParse(json['post_test_grade'].toString())
                : null),
      reflectionCompletedAt: (json['reflectionCompletedAt'] ?? json['reflection_completed_at'])?.toString(),

      createdAt: parseDate(json['createdAt'] ?? json['created_at']),

      subtasks: parsedSubtasks,
      collabList: parsedCollab,
      columnMovements: parsedMovements,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'user_id': userId,
      'title': title,
      'learning_id': learningId,
      'description': description,
      'course_name': courseName,
      'difficulty': difficulty,
      'priority': priority,
      'deadline': deadline?.toLocal(),
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
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'collablist': collabList.map((c) => c.toJson()).toList(),
    };
  }
}
