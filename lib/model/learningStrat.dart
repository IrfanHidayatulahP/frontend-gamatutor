import 'package:gamatutor_kanban/model/cardlist.dart';

class LearningStrat {
  String? learningId;
  String? keyCode; // 'time_management', 'organization', etc.
  String? learningStrategy; // 'Rehearsal' | 'Organization' | 'Elaboration' | 'Time Management' | 'Help-Seeking' | 'Metacognitive Self-Regulation'
  String? description;
  DateTime? createdAt;
  List<CardList>? cardLists;

  LearningStrat({
    required this.learningId,
    required this.keyCode,
    required this.learningStrategy,
    required this.description,
    required this.createdAt,
    required this.cardLists,
  });

  factory LearningStrat.fromJson(Map<String, dynamic> json) {
    return LearningStrat(
      learningId: (json['learningId'] ?? json['learning_id'])?.toString(),
      keyCode: (json['keyCode'] ?? json['key_code'])?.toString(),
      learningStrategy: (json['learningStrategy'] ?? json['learning_strategy'])
          ?.toString(),
      description: json['description']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      cardLists: json['cardLists'] != null
          ? List<CardList>.from(
              json['cardLists'].map((x) => CardList.fromJson(x)),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learningId': learningId,
      'keyCode': keyCode,
      'learningStrategy': learningStrategy,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'cardLists': cardLists?.map((x) => x.toJson()).toList(),
    };
  }
}
