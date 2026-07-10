import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/domain/entities/assignment.dart";
import "package:edulink/domain/entities/quiz.dart";
import "package:edulink/domain/entities/quiz_question.dart";
import "package:edulink/domain/entities/quiz_result.dart";
import "package:edulink/domain/entities/submission.dart";

/// Assignments, submissions, quizzes and quiz questions.
class AssessmentRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  // ── Assignments ──
  Future<List<Assignment>> assignmentsForClass(String classId) async {
    final data = await _client
        .from(SupabaseConfig.tAssignments)
        .select("*, subject:subject_id(name)")
        .eq("class_id", classId)
        .order("due_date");
    return (data as List).map((e) => Assignment.fromMap(e)).toList();
  }

  Future<List<Assignment>> assignmentsForSubject(String subjectId) async {
    final data = await _client
        .from(SupabaseConfig.tAssignments)
        .select("*, subject:subject_id(name)")
        .eq("subject_id", subjectId)
        .order("due_date");
    return (data as List).map((e) => Assignment.fromMap(e)).toList();
  }

  Future<Assignment> createAssignment(Assignment a) async {
    final data = await _client
        .from(SupabaseConfig.tAssignments)
        .insert(a.toMap())
        .select("*, subject:subject_id(name)")
        .single();
    return Assignment.fromMap(data);
  }

  Future<void> deleteAssignment(String id) async {
    await _client.from(SupabaseConfig.tAssignments).delete().eq("id", id);
  }

  // ── Submissions ──
  Future<List<Submission>> submissions(String assignmentId) async {
    final data = await _client
        .from(SupabaseConfig.tSubmissions)
        .select("*, student:student_id(full_name)")
        .eq("assignment_id", assignmentId)
        .order("submitted_at");
    return (data as List).map((e) => Submission.fromMap(e)).toList();
  }

  Future<Submission?> mySubmission(String assignmentId, String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tSubmissions)
        .select("*, student:student_id(full_name)")
        .eq("assignment_id", assignmentId)
        .eq("student_id", studentId)
        .maybeSingle();
    return data == null ? null : Submission.fromMap(data);
  }

  Future<List<Submission>> studentSubmissions(String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tSubmissions)
        .select("*, assignment:assignment_id(title)")
        .eq("student_id", studentId)
        .order("submitted_at", ascending: false);
    return (data as List).map((e) => Submission.fromMap(e)).toList();
  }

  Future<Submission> submit(Submission s) async {
    final data = await _client
        .from(SupabaseConfig.tSubmissions)
        .upsert(s.toMap(), onConflict: "assignment_id,student_id")
        .select("*, student:student_id(full_name)")
        .single();
    return Submission.fromMap(data);
  }

  Future<void> grade(String id, num grade, String? feedback) async {
    await _client.from(SupabaseConfig.tSubmissions).update({
      "grade": grade,
      "feedback": feedback,
      "status": SubmissionStatus.graded.key,
      "graded_at": DateTime.now().toIso8601String(),
    }).eq("id", id);
  }

  // ── Quizzes ──
  Future<List<Quiz>> quizzes(String subjectId) async {
    final data = await _client
        .from(SupabaseConfig.tQuizzes)
        .select("*, quiz_questions(id)")
        .eq("subject_id", subjectId)
        .order("created_at");
    return (data as List).map((e) => Quiz.fromMap(e)).toList();
  }

  Future<Quiz> createQuiz(Quiz q) async {
    final data = await _client
        .from(SupabaseConfig.tQuizzes)
        .insert(q.toMap())
        .select("*, quiz_questions(id)")
        .single();
    return Quiz.fromMap(data);
  }

  Future<void> deleteQuiz(String id) async {
    await _client.from(SupabaseConfig.tQuizzes).delete().eq("id", id);
  }

  // ── Quiz questions ──
  Future<List<QuizQuestion>> questions(String quizId) async {
    final data = await _client
        .from(SupabaseConfig.tQuizQuestions)
        .select()
        .eq("quiz_id", quizId)
        .order("created_at");
    return (data as List).map((e) => QuizQuestion.fromMap(e)).toList();
  }

  Future<QuizQuestion> addQuestion(QuizQuestion q) async {
    final data = await _client
        .from(SupabaseConfig.tQuizQuestions)
        .insert(q.toMap())
        .select()
        .single();
    return QuizQuestion.fromMap(data);
  }

  Future<void> deleteQuestion(String id) async {
    await _client.from(SupabaseConfig.tQuizQuestions).delete().eq("id", id);
  }

  // ── Quiz Results ──
  Future<QuizResult> submitQuizResult(QuizResult result) async {
    final data = await _client
        .from(SupabaseConfig.tQuizResults)
        .upsert(result.toMap(), onConflict: "quiz_id,student_id")
        .select()
        .single();
    return QuizResult.fromMap(data);
  }

  Future<QuizResult?> getQuizResultForStudent(String quizId, String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tQuizResults)
        .select()
        .eq("quiz_id", quizId)
        .eq("student_id", studentId)
        .maybeSingle();
    if (data == null) return null;
    return QuizResult.fromMap(data);
  }

  Future<List<QuizResult>> getQuizResults(String quizId) async {
    final data = await _client
        .from(SupabaseConfig.tQuizResults)
        .select("*, student:student_id(full_name)")
        .eq("quiz_id", quizId)
        .order("submitted_at", ascending: false);
    return (data as List).map((e) => QuizResult.fromMap(e)).toList();
  }

  Future<List<QuizResult>> studentQuizResults(String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tQuizResults)
        .select("*, quiz:quiz_id(title)")
        .eq("student_id", studentId)
        .order("submitted_at", ascending: false);
    return (data as List).map((e) => QuizResult.fromMap(e)).toList();
  }
}
