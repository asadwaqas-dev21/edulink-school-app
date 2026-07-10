import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/domain/entities/quiz_result.dart";
import "package:edulink/domain/entities/submission.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class StudentProgressScreen extends StatefulWidget {
  final String studentId;
  final String? studentName;

  const StudentProgressScreen({
    super.key,
    required this.studentId,
    this.studentName,
  });

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final _repo = Get.find<AssessmentRepository>();

  late Future<List<Submission>> _submissionsFuture;
  late Future<List<QuizResult>> _quizzesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _submissionsFuture = _repo.studentSubmissions(widget.studentId);
    _quizzesFuture = _repo.studentQuizResults(widget.studentId);
  }

  void _reload() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.studentName != null
              ? "${widget.studentName}'s Progress"
              : "My Progress"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Assignments"),
              Tab(text: "Quizzes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAssignmentsTab(),
            _buildQuizzesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return FutureBuilder<List<Submission>>(
      future: _submissionsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const EmptyState(
            icon: Iconsax.task_square,
            title: "No assignments",
            subtitle: "No assignment grades available yet.",
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sub = list[index];
              final gradeText =
                  sub.grade != null ? "${sub.grade}" : "Not Graded";
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sub.assignmentTitle ?? "Assignment",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: sub.grade != null
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              gradeText,
                              style: TextStyle(
                                color: sub.grade != null
                                    ? AppColors.primary
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Submitted: ${Formatters.dateTime(sub.submittedAt)}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Feedback: ${sub.feedback}",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuizzesTab() {
    return FutureBuilder<List<QuizResult>>(
      future: _quizzesFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const EmptyState(
            icon: Iconsax.chart,
            title: "No quizzes",
            subtitle: "No quiz scores available yet.",
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = list[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.quizTitle ?? "Quiz",
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text("Score: ${r.score} / ${r.totalPoints}",
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(
                                "Taken: ${Formatters.dateTime(r.submittedAt)}",
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${r.percentage.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
