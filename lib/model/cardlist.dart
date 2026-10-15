class CardList {
  String? cardId; // PK + FK to cards
  String? subTitle;
  String? endTimeList;

  CardList({
    required this.cardId,
    required this.subTitle,
    required this.endTimeList
  });

 

  factory CardList.fromJson(Map<String, dynamic> json) {
    return CardList(
      cardId: json['cardId'] ?? json['card_id'] ?? '',
      subTitle: json['subTitle'] ?? json['sub_title'],
      endTimeList: json['endTimeList'] ?? json['end_time_list']
      );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'subTitle': subTitle,
      'endTimeList' : endTimeList
      };
  }
}