class Enrollment {
  final String id;
  final String classId;
  final String studentId;
  final String? rollNo;
  final String? studentName;
  final String? studentEmail;
  final String? className;
  final DateTime? createdAt;

  const Enrollment({
    required this.id,
    required this.classId,
    required this.studentId,
    this.rollNo,
    this.studentName,
    this.studentEmail,
    this.className,
    this.createdAt,
  });

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    final student = map["student"];
    final cls = map["class"];
    return Enrollment(
      id: map["id"] as String,
      classId: (map["class_id"] ?? "") as String,
      studentId: (map["student_id"] ?? "") as String,
      rollNo: map["roll_no"] as String?,
      studentName: student is Map ? student["full_name"] as String? : null,
      studentEmail: student is Map ? student["email"] as String? : null,
      className: cls is Map ? cls["name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "class_id": classId,
        "student_id": studentId,
        "roll_no": rollNo,
      };
}
