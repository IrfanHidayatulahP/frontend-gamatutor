import 'package:gamatutor_kanban/model/columnmovement.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
class Card {
  String? cardId;
  String? userId;
  String? title;
  // No createdAt in model
  CardList? cardList; // 1:1 relation
  List<ColumnMovement>? columnMovements;

  Card({
    required this.cardId,
    required this.userId,
    required this.title,
    required this.cardList,
    required this.columnMovements
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    return Card(
      cardId: json['cardId'],
      userId: json['userId'],
      title: json['title'],
      cardList: json['cardList'] != null ? CardList.fromJson(json['cardList']) : null,
      columnMovements: json['columnMovements'] != null
          ? List<ColumnMovement>.from(json['columnMovements'].map((x) => ColumnMovement.fromJson(x)))
          : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'userId': userId,
      'title': title,
      'cardList': cardList?.toJson(),
      'columnMovements': columnMovements?.map((x) => x.toJson()).toList()
    };
  }
}

