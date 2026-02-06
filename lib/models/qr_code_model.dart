class QrCodeModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final String userId;

  QrCodeModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
  });

  factory QrCodeModel.fromJson(Map<String, dynamic> json) {
    return QrCodeModel(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }
}
