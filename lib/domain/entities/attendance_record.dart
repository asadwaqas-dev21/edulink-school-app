import "package:edulink/core/enums/status_enums.dart";

class AttendanceRecord {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String? markedBy;
  final String? note;
  final String? studentName;

  const AttendanceRecord({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.status,
    this.markedBy,
    this.note,
    this.studentName,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final student = map["student"];
    return AttendanceRecord(
      id: map["id"] as String,
      classId: (map["class_id"] ?? "") as String,
      studentId: (map["student_id"] ?? "") as String,
      date: DateTime.tryParse(map["date"].toString()) ?? DateTime.now(),
      status: AttendanceStatus.fromKey(map["status"] as String?),
      markedBy: map["marked_by"] as String?,
      note: map["note"] as String?,
      studentName: student is Map ? student["full_name"] as String? : null,
    );
  }

  Map<String, dynamic> toMap() => {
        "class_id": classId,
        "student_id": studentId,
        "date": date.toIso8601String().substring(0, 10),
        "status": status.key,
        "marked_by": markedBy,
        "note": note,
      };
}
