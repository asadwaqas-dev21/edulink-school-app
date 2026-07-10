class Subject {
  final String id;
  final String instituteId;
  final String classId;
  final String name;
  final String? code;
  final String? teacherId;
  final String? teacherName;
  final DateTime? createdAt;

  const Subject({
    required this.id,
    required this.instituteId,
    required this.classId,
    required this.name,
    this.code,
    this.teacherId,
    this.teacherName,
    this.createdAt,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    final teacher = map["teacher"];
    return Subject(
      id: map["id"] as String,
      instituteId: (map["institute_id"] ?? "") as String,
      classId: (map["class_id"] ?? "") as String,
      name: (map["name"] ?? "") as String,
      code: map["code"] as String?,
      teacherId: map["teacher_id"] as String?,
      teacherName: teacher is Map ? teacher["full_name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "institute_id": instituteId,
        "class_id": classId,
        "name": name,
        "code": code,
        "teacher_id": teacherId,
      };
}
