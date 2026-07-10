import "package:edulink/core/enums/status_enums.dart";

class Submission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? fileUrl;
  final String? note;
  final num? grade;
  final String? feedback;
  final SubmissionStatus status;
  final String? studentName;
  final String? assignmentTitle;
  final DateTime? submittedAt;
  final DateTime? gradedAt;

  const Submission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.fileUrl,
    this.note,
    this.grade,
    this.feedback,
    this.status = SubmissionStatus.submitted,
    this.studentName,
    this.assignmentTitle,
    this.submittedAt,
    this.gradedAt,
  });

  factory Submission.fromMap(Map<String, dynamic> map) {
    final student = map["student"];
    final assignment = map["assignment"];
    return Submission(
      id: map["id"] as String,
      assignmentId: (map["assignment_id"] ?? "") as String,
      studentId: (map["student_id"] ?? "") as String,
      fileUrl: map["file_url"] as String?,
      note: map["note"] as String?,
      grade: map["grade"] as num?,
      feedback: map["feedback"] as String?,
      status: SubmissionStatus.fromKey(map["status"] as String?),
      studentName: student is Map ? student["full_name"] as String? : null,
      assignmentTitle: assignment is Map ? assignment["title"] as String? : null,
      submittedAt: map["submitted_at"] == null
          ? null
          : DateTime.tryParse(map["submitted_at"].toString()),
      gradedAt: map["graded_at"] == null
          ? null
          : DateTime.tryParse(map["graded_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "assignment_id": assignmentId,
        "student_id": studentId,
        "file_url": fileUrl,
        "note": note,
        "grade": grade,
        "feedback": feedback,
        "status": status.key,
      };
}
