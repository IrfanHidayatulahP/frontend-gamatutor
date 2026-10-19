class CardList {
  String? clId;
  String? cardId;
  String? subTitle;
  DateTime? endTimeList;
  DateTime? startTimeList;

  CardList({
    this.clId,
    this.cardId,
    this.subTitle,
    this.endTimeList,
    this.startTimeList,
  });

  factory CardList.fromJson(Map<String, dynamic> json) {
  return CardList(
    clId: json['cl_id'] ?? json['clId'],
    cardId: json['card_id'] ?? json['cardId'],
    subTitle: json['sub_title'] ?? json['subTitle'],
    // Pastikan menangani start_time_list dari database
    startTimeList: json['start_time_list'] != null 
        ? DateTime.parse(json['start_time_list']) 
        : (json['startTimeList'] != null ? DateTime.parse(json['startTimeList']) : null),
    endTimeList: json['end_time_list'] != null 
        ? DateTime.parse(json['end_time_list']) 
        : (json['endTimeList'] != null ? DateTime.parse(json['endTimeList']) : null),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'clId': clId,
      'cardId': cardId,
      'subTitle': subTitle,
      'endTimeList': endTimeList?.toIso8601String(),
      'startTimeList': startTimeList?.toIso8601String(),
    };
  }
}