class Assignment {
  final String id;
  final String subjectId;
  final String classId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int maxPoints;
  final String? createdBy;
  final String? subjectName;
  final DateTime? createdAt;

  const Assignment({
    required this.id,
    required this.subjectId,
    required this.classId,
    required this.title,
    this.description,
    this.dueDate,
    this.maxPoints = 100,
    this.createdBy,
    this.subjectName,
    this.createdAt,
  });

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now());

  factory Assignment.fromMap(Map<String, dynamic> map) {
    final subject = map["subject"];
    return Assignment(
      id: map["id"] as String,
      subjectId: (map["subject_id"] ?? "") as String,
      classId: (map["class_id"] ?? "") as String,
      title: (map["title"] ?? "") as String,
      description: map["description"] as String?,
      dueDate: map["due_date"] == null
          ? null
          : DateTime.tryParse(map["due_date"].toString()),
      maxPoints: (map["max_points"] ?? 100) as int,
      createdBy: map["created_by"] as String?,
      subjectName: subject is Map ? subject["name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "subject_id": subjectId,
        "class_id": classId,
        "title": title,
        "description": description,
        "due_date": dueDate?.toIso8601String(),
        "max_points": maxPoints,
        "created_by": createdBy,
      };
}
