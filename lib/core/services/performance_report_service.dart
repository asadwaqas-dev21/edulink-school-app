import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/domain/entities/profile.dart";

/// A single graded test (assignment submission or quiz result) reduced to a
/// comparable percentage for performance tracking.
class TestScore {
  final String title;
  final String subject;
  final String type; // "Assignment" | "Quiz"
  final DateTime date;
  final double percentage; // 0..100
  final num score;
  final num total;

  const TestScore({
    required this.title,
    required this.subject,
    required this.type,
    required this.date,
    required this.percentage,
    required this.score,
    required this.total,
  });
}

/// Average performance for a single subject.
class SubjectStat {
  final String subject;
  final double average; // 0..100
  final int count;

  const SubjectStat({
    required this.subject,
    required this.average,
    required this.count,
  });
}

/// Aggregated performance report for one student, derived from all their
/// graded assignments and quiz results.
class StudentPerformance {
  final Profile student;

  /// All graded tests, sorted oldest → latest.
  final List<TestScore> tests;
  final double overallAverage;

  /// Growth = average of the latest half minus average of the earliest half,
  /// expressed in percentage points. Positive means improving.
  final double growthRate;
  final double firstHalfAverage;
  final double lastHalfAverage;

  /// Per-subject averages, sorted best → worst.
  final List<SubjectStat> subjects;
  final double bestPercentage;
  final double lowestPercentage;

  const StudentPerformance({
    required this.student,
    required this.tests,
    required this.overallAverage,
    required this.growthRate,
    required this.firstHalfAverage,
    required this.lastHalfAverage,
    required this.subjects,
    required this.bestPercentage,
    required this.lowestPercentage,
  });

  bool get hasData => tests.isNotEmpty;
  int get testCount => tests.length;
  bool get improving => growthRate >= 0;

  String? get bestSubject => subjects.isEmpty ? null : subjects.first.subject;

  /// A simple letter grade for the overall average.
  String get grade {
    final p = overallAverage;
    if (p >= 90) return "A+";
    if (p >= 80) return "A";
    if (p >= 70) return "B";
    if (p >= 60) return "C";
    if (p >= 50) return "D";
    return "F";
  }

  factory StudentPerformance.fromTests(Profile student, List<TestScore> raw) {
    final tests = [...raw]..sort((a, b) => a.date.compareTo(b.date));

    if (tests.isEmpty) {
      return StudentPerformance(
        student: student,
        tests: const [],
        overallAverage: 0,
        growthRate: 0,
        firstHalfAverage: 0,
        lastHalfAverage: 0,
        subjects: const [],
        bestPercentage: 0,
        lowestPercentage: 0,
      );
    }

    double avg(Iterable<TestScore> xs) {
      if (xs.isEmpty) return 0;
      final sum = xs.fold<double>(0, (s, t) => s + t.percentage);
      return sum / xs.length;
    }

    final overall = avg(tests);

    double firstHalf = overall;
    double lastHalf = overall;
    double growth = 0;
    if (tests.length >= 2) {
      final half = tests.length ~/ 2;
      firstHalf = avg(tests.sublist(0, half));
      lastHalf = avg(tests.sublist(tests.length - half));
      growth = lastHalf - firstHalf;
    }

    // Per-subject aggregation.
    final grouped = <String, List<TestScore>>{};
    for (final t in tests) {
      grouped.putIfAbsent(t.subject, () => []).add(t);
    }
    final subjects = grouped.entries
        .map((e) => SubjectStat(
              subject: e.key,
              average: avg(e.value),
              count: e.value.length,
            ))
        .toList()
      ..sort((a, b) => b.average.compareTo(a.average));

    final percentages = tests.map((t) => t.percentage);

    return StudentPerformance(
      student: student,
      tests: tests,
      overallAverage: overall,
      growthRate: growth,
      firstHalfAverage: firstHalf,
      lastHalfAverage: lastHalf,
      subjects: subjects,
      bestPercentage: percentages.reduce((a, b) => a > b ? a : b),
      lowestPercentage: percentages.reduce((a, b) => a < b ? a : b),
    );
  }
}

/// Fetches and computes a [StudentPerformance] from the assessment data.
abstract class PerformanceReportService {
  static Future<StudentPerformance> build(
    Profile student,
    AssessmentRepository repo,
  ) async {
    final submissions = await repo.studentSubmissions(student.id);
    final quizzes = await repo.studentQuizResults(student.id);

    final tests = <TestScore>[];

    for (final s in submissions) {
      final grade = s.grade;
      final max = s.maxPoints;
      if (grade == null || max == null || max == 0) continue;
      tests.add(TestScore(
        title: s.assignmentTitle ?? "Assignment",
        subject: s.subjectName ?? "General",
        type: "Assignment",
        date: s.gradedAt ?? s.submittedAt ?? DateTime.now(),
        percentage: ((grade / max) * 100).clamp(0.0, 100.0),
        score: grade,
        total: max,
      ));
    }

    for (final q in quizzes) {
      if (q.totalPoints == 0) continue;
      tests.add(TestScore(
        title: q.quizTitle ?? "Quiz",
        subject: "Quizzes",
        type: "Quiz",
        date: q.submittedAt ?? DateTime.now(),
        percentage: q.percentage.clamp(0.0, 100.0),
        score: q.score,
        total: q.totalPoints,
      ));
    }

    return StudentPerformance.fromTests(student, tests);
  }
}
