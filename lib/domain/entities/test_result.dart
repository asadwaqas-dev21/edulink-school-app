class TestResult {
  final String id;
  final String testId;
  final String studentId;
  final num obtainedMarks;
  final String? remarks;
  final String? studentName;
  final DateTime? createdAt;

  const TestResult({
    required this.id,
    required this.testId,
    required this.studentId,
    this.obtainedMarks = 0,
    this.remarks,
    this.studentName,
    this.createdAt,
  });

  factory TestResult.fromMap(Map<String, dynamic> map) {
    final student = map["student"];
    return TestResult(
      id: map["id"] as String,
      testId: (map["test_id"] ?? "") as String,
      studentId: (map["student_id"] ?? "") as String,
      obtainedMarks: (map["obtained_marks"] ?? 0) as num,
      remarks: map["remarks"] as String?,
      studentName: student is Map ? student["full_name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "test_id": testId,
        "student_id": studentId,
        "obtained_marks": obtainedMarks,
        "remarks": remarks,
      };
}
