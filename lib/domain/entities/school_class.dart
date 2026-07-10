class SchoolClass {
  final String id;
  final String instituteId;
  final String name;
  final String? section;
  final String? gradeLevel;
  final String? classTeacherId;
  final DateTime? createdAt;

  const SchoolClass({
    required this.id,
    required this.instituteId,
    required this.name,
    this.section,
    this.gradeLevel,
    this.classTeacherId,
    this.createdAt,
  });

  String get displayName =>
      section == null || section!.isEmpty ? name : "$name - $section";

  factory SchoolClass.fromMap(Map<String, dynamic> map) {
    return SchoolClass(
      id: map["id"] as String,
      instituteId: (map["institute_id"] ?? "") as String,
      name: (map["name"] ?? "") as String,
      section: map["section"] as String?,
      gradeLevel: map["grade_level"] as String?,
      classTeacherId: map["class_teacher_id"] as String?,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "institute_id": instituteId,
        "name": name,
        "section": section,
        "grade_level": gradeLevel,
        "class_teacher_id": classTeacherId,
      };
}
