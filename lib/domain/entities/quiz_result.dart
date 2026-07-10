class QuizResult {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final int totalPoints;
  final DateTime? submittedAt;

  // Optional, populated by joined queries
  final String? studentName;
  final String? quizTitle;

  const QuizResult({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    required this.totalPoints,
    this.submittedAt,
    this.studentName,
    this.quizTitle,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    final studentData = map["student"];
    final quizData = map["quiz"];
    return QuizResult(
      id: map["id"] as String,
      quizId: map["quiz_id"] as String,
      studentId: map["student_id"] as String,
      score: (map["score"] ?? 0) as int,
      totalPoints: (map["total_points"] ?? 0) as int,
      submittedAt: map["submitted_at"] == null
          ? null
          : DateTime.tryParse(map["submitted_at"].toString()),
      studentName:
          studentData is Map ? studentData["full_name"] as String? : null,
      quizTitle: quizData is Map ? quizData["title"] as String? : null,
    );
  }

  Map<String, dynamic> toMap() => {
        "quiz_id": quizId,
        "student_id": studentId,
        "score": score,
        "total_points": totalPoints,
      };

  double get percentage => totalPoints > 0 ? (score / totalPoints) * 100 : 0;
}
