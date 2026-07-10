import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/domain/entities/quiz.dart";
import "package:edulink/domain/entities/quiz_result.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class QuizResultsScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizResultsScreen({super.key, required this.quiz});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final _repo = Get.find<AssessmentRepository>();
  late Future<List<QuizResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _repo.getQuizResults(widget.quiz.id);
  }

  void _reload() {
    setState(() {
      _resultsFuture = _repo.getQuizResults(widget.quiz.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz Results")),
      body: FutureBuilder<List<QuizResult>>(
        future: _resultsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final results = snap.data ?? [];
          if (results.isEmpty) {
            return const EmptyState(
              icon: Iconsax.document_text,
              title: "No results yet",
              subtitle: "No students have completed this quiz.",
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      const Icon(Iconsax.people, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        "Total Submissions: ${results.length}",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = results[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              AppAvatar(name: r.studentName, radius: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.studentName ?? "Unknown Student",
                                        style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text("Score: ${r.score} / ${r.totalPoints}",
                                        style: Theme.of(context).textTheme.bodyMedium),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
