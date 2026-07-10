class MaterialItem {
  final String id;
  final String lessonId;
  final String title;
  final String fileUrl;
  final String? fileType;
  final DateTime? createdAt;

  const MaterialItem({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.fileUrl,
    this.fileType,
    this.createdAt,
  });

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map["id"] as String,
      lessonId: (map["lesson_id"] ?? "") as String,
      title: (map["title"] ?? "") as String,
      fileUrl: (map["file_url"] ?? "") as String,
      fileType: map["file_type"] as String?,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "lesson_id": lessonId,
        "title": title,
        "file_url": fileUrl,
        "file_type": fileType,
      };
}
