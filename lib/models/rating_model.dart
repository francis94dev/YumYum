class RatingModel {
  final String id;
  final String targetId;
  final String targetType; // 'recipe' or 'user'
  final String authorId;
  final int value;
  final String? comment;

  RatingModel({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.authorId,
    required this.value,
    this.comment,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] as String,
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as String,
      authorId: json['authorId'] as String,
      value: json['value'] as int,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetId': targetId,
      'targetType': targetType,
      'authorId': authorId,
      'value': value,
      'comment': comment,
    };
  }
}
