class Quiz {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final int questionCount;

  const Quiz({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    this.createdBy,
    this.createdAt,
    this.questionCount = 0,
  });

  factory Quiz.fromMap(Map<String, dynamic> map) {
    final count = map["quiz_questions"];
    return Quiz(
      id: map["id"] as String,
      subjectId: (map["subject_id"] ?? "") as String,
      title: (map["title"] ?? "") as String,
      description: map["description"] as String?,
      createdBy: map["created_by"] as String?,
      questionCount: count is List
          ? count.length
          : (count is Map && count["count"] != null ? count["count"] as int : 0),
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "subject_id": subjectId,
        "title": title,
        "description": description,
        "created_by": createdBy,
      };
}
