class Lesson {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final int orderIndex;
  final String? videoUrl;
  final DateTime? createdAt;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.orderIndex = 0,
    this.videoUrl,
    this.createdAt,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map["id"] as String,
      subjectId: (map["subject_id"] ?? "") as String,
      title: (map["title"] ?? "") as String,
      description: map["description"] as String?,
      orderIndex: (map["order_index"] ?? 0) as int,
      videoUrl: map["video_url"] as String?,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "subject_id": subjectId,
        "title": title,
        "description": description,
        "order_index": orderIndex,
        "video_url": videoUrl,
      };
}
