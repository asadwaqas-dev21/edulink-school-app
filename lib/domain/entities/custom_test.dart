class CustomTest {
  final String id;
  final String subjectId;
  final String classId;
  final String title;
  final String? description;
  final DateTime? testDate;
  final int maxMarks;
  final String? createdBy;
  final String? subjectName;
  final DateTime? createdAt;

  const CustomTest({
    required this.id,
    required this.subjectId,
    required this.classId,
    required this.title,
    this.description,
    this.testDate,
    this.maxMarks = 100,
    this.createdBy,
    this.subjectName,
    this.createdAt,
  });

  factory CustomTest.fromMap(Map<String, dynamic> map) {
    final subject = map["subject"];
    return CustomTest(
      id: map["id"] as String,
      subjectId: (map["subject_id"] ?? "") as String,
      classId: (map["class_id"] ?? "") as String,
      title: (map["title"] ?? "") as String,
      description: map["description"] as String?,
      testDate: map["test_date"] == null
          ? null
          : DateTime.tryParse(map["test_date"].toString()),
      maxMarks: (map["max_marks"] ?? 100) as int,
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
        "test_date": testDate?.toIso8601String().split("T").first,
        "max_marks": maxMarks,
        "created_by": createdBy,
      };
}
