import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/domain/entities/quiz.dart";
import "package:edulink/domain/entities/quiz_question.dart";
import "package:edulink/domain/entities/quiz_result.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/assessments/view/quiz_results_screen.dart";

class QuizDetailsScreen extends StatefulWidget {
  final Quiz quiz;
  const QuizDetailsScreen({super.key, required this.quiz});

  @override
  State<QuizDetailsScreen> createState() => _QuizDetailsScreenState();
}

class _QuizDetailsScreenState extends State<QuizDetailsScreen> {
  final _repo = Get.find<AssessmentRepository>();
  final _session = Get.find<SessionController>();

  Quiz get _quiz => widget.quiz;
  bool get _canEdit => _session.role.canTeach;

  late Future<List<QuizQuestion>> _questions;
  bool _loadingResult = true;
  QuizResult? _existingResult;
  final Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _questions = _repo.questions(_quiz.id);
    if (!_canEdit) {
      _existingResult =
          await _repo.getQuizResultForStudent(_quiz.id, _session.userId!);
      if (_existingResult != null) {}
    }
    if (mounted) setState(() => _loadingResult = false);
  }

  void _reload() {
    setState(() {
      _loadData();
    });
  }

  Future<void> _addQuestion() async {
    final qCtrl = TextEditingController();
    final optCtrls = List.generate(4, (_) => TextEditingController());
    final formKey = GlobalKey<FormState>();
    int correct = 0;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("New Question",
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: qCtrl,
                    decoration: const InputDecoration(labelText: "Question"),
                    validator: (v) => Validators.required(v, "Question"),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: i,
                            // ignore: deprecated_member_use
                            groupValue: correct,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setSheet(() => correct = v ?? 0),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: optCtrls[i],
                              decoration:
                                  InputDecoration(labelText: "Option ${i + 1}"),
                              validator: (v) =>
                                  Validators.required(v, "Option"),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text("Select the radio next to the correct option.",
                      style: Theme.of(ctx).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: const Text("Add Question"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      try {
        await _repo.addQuestion(QuizQuestion(
          id: "",
          quizId: _quiz.id,
          question: qCtrl.text.trim(),
          options: optCtrls.map((c) => c.text.trim()).toList(),
          correctIndex: correct,
        ));
        SnackbarUtils.showSuccess("Question added");
        _reload();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  bool _isSubmitting = false;

  Future<void> _grade(List<QuizQuestion> questions) async {
    int score = 0;
    int totalPoints = 0;
    for (final q in questions) {
      totalPoints += q.points;
      if (_answers[q.id] == q.correctIndex) score += q.points;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final res = await _repo.submitQuizResult(QuizResult(
        id: "",
        quizId: _quiz.id,
        studentId: _session.userId!,
        score: score,
        totalPoints: totalPoints,
      ));
      if (mounted) {
        setState(() {
          _existingResult = res;
        });
        SnackbarUtils.showSuccess("Quiz submitted successfully");
      }
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz.title),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Iconsax.chart),
              tooltip: "View Results",
              onPressed: () => Get.to(() => QuizResultsScreen(quiz: _quiz)),
            ),
        ],
      ),
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _addQuestion,
              icon: const Icon(Iconsax.add),
              label: const Text("Question"),
            )
          : null,
      body: _loadingResult
          ? const LoadingWidget()
          : FutureBuilder<List<QuizQuestion>>(
              future: _questions,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                final questions = snap.data ?? [];
                if (questions.isEmpty) {
                  return const EmptyState(
                      icon: Iconsax.document_text, title: "No questions yet");
                }
                final totalPoints =
                    questions.fold<int>(0, (sum, q) => sum + q.points);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    ...questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Q${i + 1}. ${q.question}",
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 10),
                              ...q.options.asMap().entries.map((opt) {
                                final optIndex = opt.key;
                                final isCorrect = optIndex == q.correctIndex;
                                final showAnswer =
                                    _canEdit || _existingResult != null;
                                final disableRadio =
                                    _canEdit || _existingResult != null;
                                return RadioListTile<int>(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  value: optIndex,
                                  // ignore: deprecated_member_use
                                  groupValue: _canEdit
                                      ? q.correctIndex
                                      : _answers[q.id],
                                  // ignore: deprecated_member_use
                                  onChanged: disableRadio
                                      ? null
                                      : (v) {
                                          setState(() {
                                            _answers[q.id] = v ?? 0;
                                          });
                                        },
                                  title: Text(opt.value),
                                  secondary: showAnswer && isCorrect
                                      ? const Icon(Iconsax.tick_circle,
                                          color: AppColors.success, size: 18)
                                      : null,
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (!_canEdit) ...[
                      const SizedBox(height: 8),
                      if (_existingResult != null)
                        Card(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "Your score: ${_existingResult!.score} / $totalPoints\n(${_existingResult!.percentage.toStringAsFixed(1)}%)",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppColors.primary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      if (_existingResult == null) const SizedBox(height: 12),
                      if (_existingResult == null)
                        FilledButton(
                          onPressed:
                              _isSubmitting ? null : () => _grade(questions),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text("Submit answers"),
                        ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
