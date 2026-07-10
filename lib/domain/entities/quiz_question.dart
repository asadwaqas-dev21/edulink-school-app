class QuizQuestion {
  final String id;
  final String quizId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final int points;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.points = 1,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final rawOptions = map["options"];
    return QuizQuestion(
      id: map["id"] as String,
      quizId: (map["quiz_id"] ?? "") as String,
      question: (map["question"] ?? "") as String,
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : <String>[],
      correctIndex: (map["correct_index"] ?? 0) as int,
      points: (map["points"] ?? 1) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        "quiz_id": quizId,
        "question": question,
        "options": options,
        "correct_index": correctIndex,
        "points": points,
      };
}
