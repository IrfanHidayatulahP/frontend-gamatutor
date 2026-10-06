import 'package:gamatutor_kanban/model/learningStrat.dart';
import 'package:gamatutor_kanban/model/cardlistcollab.dart';

class CardList {
  String? cardId; // PK + FK to cards
  String? learningId;
  String? subTitle;
  String? description;
  String? courseName;
  String? difficulty; // 'easy' | 'medium' | 'hard' | 'expert'
  String? priority; // 'low' | 'medium' | 'high' | 'critical'
  DateTime? deadline;
  String? url;
  DateTime? startTime;
  DateTime? endTime;
  bool? deleted;
  
  // Self-reflection fields
  double? satisfactionRating;
  String? notes;
  int? preTestGrade;
  int? postTestGrade;
  String? reflectionQ1Strategy;
  double? reflectionQ2Confidence;
  String? reflectionQ3WhatLearned;
  String? reflectionQ4Value;
  DateTime? reflectionCompletedAt;
  double? personalBestTime;
  double? personalBestGrade;
  DateTime? personalBestAchievedAt;
  double? goalCheckRating;
  DateTime? goalCheckTimestamp;
  
  // Relations
  LearningStrat? learningStrat;
  List<CardListCollab>? collaborations;

  CardList({
    required this.cardId,
    required this.learningId,
    required this.subTitle,
    required this.description,
    required this.courseName,
    required this.difficulty,
    required this.priority,
    this.deadline,
    this.url,
    required this.startTime,
    this.endTime,
    this.deleted,
    this.satisfactionRating,
    this.notes,
    this.preTestGrade,
    this.postTestGrade,
    this.reflectionQ1Strategy,
    this.reflectionQ2Confidence,
    this.reflectionQ3WhatLearned,
    this.reflectionQ4Value,
    this.reflectionCompletedAt,
    this.personalBestTime,
    this.personalBestGrade,
    this.personalBestAchievedAt,
    this.goalCheckRating,
    this.goalCheckTimestamp,
    this.learningStrat,
    this.collaborations
  });

  factory CardList.fromJson(Map<String, dynamic> json) {
    return CardList(
      cardId: json['cardId'],
      learningId: json['learningId'],
      subTitle: json['subTitle'],
      description: json['description'],
      courseName: json['courseName'],
      difficulty: json['difficulty'],
      priority: json['priority'],
      deadline: DateTime.parse(json['deadline']),
      url: json['url'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      deleted: json['deleted'],
      satisfactionRating: json['satisfactionRating'],
      notes: json['notes'],
      preTestGrade: json['preTestGrade'],
      postTestGrade: json['postTestGrade'],
      reflectionQ1Strategy: json['reflectionQ1Strategy'],
      reflectionQ2Confidence: json['reflectionQ2Confidence'],
      reflectionQ3WhatLearned: json['reflectionQ3WhatLearned'],
      reflectionQ4Value: json['reflectionQ4Value'],
      reflectionCompletedAt: DateTime.parse(json['reflectionCompletedAt']),
      personalBestTime: json['personalBestTime'],
      personalBestGrade: json['personalBestGrade'],
      personalBestAchievedAt: DateTime.parse(json['personalBestAchievedAt']),
      goalCheckRating: json['goalCheckRating'],
      goalCheckTimestamp: DateTime.parse(json['goalCheckTimestamp']),
      learningStrat: json['learningStrat'] != null
          ? LearningStrat.fromJson(json['learningStrat'])
          : null,
      collaborations: json['collaborations'] != null
          ? List<CardListCollab>.from(json['collaborations'].map((x) => CardListCollab.fromJson(x)))
          : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'learningId': learningId,
      'subTitle': subTitle,
      'description': description,
      'courseName': courseName,
      'difficulty': difficulty,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'url': url,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'deleted': deleted,
      'satisfactionRating': satisfactionRating,
      'notes': notes,
      'preTestGrade': preTestGrade,
      'postTestGrade': postTestGrade,
      'reflectionQ1Strategy': reflectionQ1Strategy,
      'reflectionQ2Confidence': reflectionQ2Confidence,
      'reflectionQ3WhatLearned': reflectionQ3WhatLearned,
      'reflectionQ4Value': reflectionQ4Value,
      'reflectionCompletedAt': reflectionCompletedAt?.toIso8601String(),
      'personalBestTime': personalBestTime,
      'personalBestGrade': personalBestGrade,
      'personalBestAchievedAt': personalBestAchievedAt?.toIso8601String(),
      'goalCheckRating': goalCheckRating,
      'goalCheckTimestamp': goalCheckTimestamp?.toIso8601String(),
      'learningStrat': learningStrat?.toJson(),
      'collaborations': collaborations?.map((x) => x.toJson()).toList()
    };
  }
}