import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/data/repositories/course_repository.dart";
import "package:edulink/domain/entities/assignment.dart";
import "package:edulink/domain/entities/lesson.dart";
import "package:edulink/domain/entities/quiz.dart";
import "package:edulink/domain/entities/subject.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/assessments/view/assignment_details_screen.dart";
import "package:edulink/presentation/modules/assessments/view/quiz_details_screen.dart";
import "package:edulink/presentation/modules/courses/view/lesson_details_screen.dart";

class SubjectContentScreen extends StatefulWidget {
  final Subject subject;
  const SubjectContentScreen({super.key, required this.subject});

  @override
  State<SubjectContentScreen> createState() => _SubjectContentScreenState();
}

class _SubjectContentScreenState extends State<SubjectContentScreen> {
  final _courseRepo = Get.find<CourseRepository>();
  final _assessRepo = Get.find<AssessmentRepository>();
  final _session = Get.find<SessionController>();

  Subject get _subject => widget.subject;
  bool get _canEdit => _session.role.canTeach;

  late Future<List<Lesson>> _lessons;
  late Future<List<Assignment>> _assignments;
  late Future<List<Quiz>> _quizzes;

  @override
  void initState() {
    super.initState();
    _reloadLessons();
    _reloadAssignments();
    _reloadQuizzes();
  }

  void _reloadLessons() {
    setState(() {
      _lessons = _courseRepo.lessons(_subject.id);
    });
  }

  void _reloadAssignments() {
    setState(() {
      _assignments = _assessRepo.assignmentsForSubject(_subject.id);
    });
  }

  void _reloadQuizzes() {
    setState(() {
      _quizzes = _assessRepo.quizzes(_subject.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_subject.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Lessons"),
              Tab(text: "Assignments"),
              Tab(text: "Quizzes"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _lessonsTab(),
            _assignmentsTab(),
            _quizzesTab(),
          ],
        ),
      ),
    );
  }

  // ── Lessons ──
  Widget _lessonsTab() {
    return _tabScaffold(
      canAdd: _canEdit,
      onAdd: _addLesson,
      addLabel: "Lesson",
      child: FutureBuilder<List<Lesson>>(
        future: _lessons,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final lessons = snap.data ?? [];
          if (lessons.isEmpty) {
            return const EmptyState(
                icon: Iconsax.book, title: "No lessons yet");
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final l = lessons[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text("${i + 1}",
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(l.title),
                  subtitle: l.description != null
                      ? Text(l.description!,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                  onTap: () => Get.to(() => LessonDetailsScreen(lesson: l)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addLesson() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final videoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await _formSheet(
      title: "New Lesson",
      formKey: formKey,
      fields: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: "Title"),
          validator: (v) => Validators.required(v, "Title"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          decoration:
              const InputDecoration(labelText: "Description (optional)"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: videoCtrl,
          decoration: const InputDecoration(labelText: "Video URL (optional)"),
        ),
      ],
    );
    if (ok) {
      try {
        await _courseRepo.createLesson(Lesson(
          id: "",
          subjectId: _subject.id,
          title: titleCtrl.text.trim(),
          description:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          videoUrl:
              videoCtrl.text.trim().isEmpty ? null : videoCtrl.text.trim(),
        ));
        SnackbarUtils.showSuccess("Lesson added");
        _reloadLessons();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  // ── Assignments ──
  Widget _assignmentsTab() {
    return _tabScaffold(
      canAdd: _canEdit,
      onAdd: _addAssignment,
      addLabel: "Assignment",
      child: FutureBuilder<List<Assignment>>(
        future: _assignments,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
                icon: Iconsax.task_square, title: "No assignments yet");
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = items[i];
              return Card(
                child: ListTile(
                  leading: Icon(Iconsax.task_square, color: AppColors.primary),
                  title: Text(a.title),
                  subtitle: Text(a.dueDate != null
                      ? "Due ${Formatters.date(a.dueDate)}  •  ${a.maxPoints} pts"
                      : "${a.maxPoints} pts"),
                  trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                  onTap: () =>
                      Get.to(() => AssignmentDetailsScreen(assignment: a)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addAssignment() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: "100");
    final formKey = GlobalKey<FormState>();
    DateTime? due;
    final ok = await _formSheet(
      title: "New Assignment",
      formKey: formKey,
      fieldsBuilder: (setSheet) => [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: "Title"),
          validator: (v) => Validators.required(v, "Title"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: "Instructions"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: pointsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Max points"),
          validator: (v) => Validators.number(v, "Points"),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Iconsax.calendar_1),
          label: Text(due == null ? "Pick due date" : Formatters.date(due)),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (picked != null) setSheet(() => due = picked);
          },
        ),
      ],
    );
    if (ok) {
      try {
        await _assessRepo.createAssignment(Assignment(
          id: "",
          subjectId: _subject.id,
          classId: _subject.classId,
          title: titleCtrl.text.trim(),
          description:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          dueDate: due,
          maxPoints: int.tryParse(pointsCtrl.text.trim()) ?? 100,
          createdBy: _session.userId,
        ));
        SnackbarUtils.showSuccess("Assignment created");
        _reloadAssignments();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  // ── Quizzes ──
  Widget _quizzesTab() {
    return _tabScaffold(
      canAdd: _canEdit,
      onAdd: _addQuiz,
      addLabel: "Quiz",
      child: FutureBuilder<List<Quiz>>(
        future: _quizzes,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
                icon: Iconsax.document_text, title: "No quizzes yet");
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final q = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Iconsax.document_text,
                      color: AppColors.accent),
                  title: Text(q.title),
                  subtitle: Text("${q.questionCount} questions"),
                  trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                  onTap: () => Get.to(() => QuizDetailsScreen(quiz: q)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addQuiz() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await _formSheet(
      title: "New Quiz",
      formKey: formKey,
      fields: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: "Title"),
          validator: (v) => Validators.required(v, "Title"),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descCtrl,
          maxLines: 2,
          decoration:
              const InputDecoration(labelText: "Description (optional)"),
        ),
      ],
    );
    if (ok) {
      try {
        await _assessRepo.createQuiz(Quiz(
          id: "",
          subjectId: _subject.id,
          title: titleCtrl.text.trim(),
          description:
              descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          createdBy: _session.userId,
        ));
        SnackbarUtils.showSuccess("Quiz created");
        _reloadQuizzes();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  // ── Shared helpers ──
  Widget _tabScaffold({
    required bool canAdd,
    required VoidCallback onAdd,
    required String addLabel,
    required Widget child,
  }) {
    return Stack(
      children: [
        child,
        if (canAdd)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: addLabel,
              onPressed: onAdd,
              icon: const Icon(Iconsax.add),
              label: Text(addLabel),
            ),
          ),
      ],
    );
  }

  Future<bool> _formSheet({
    required String title,
    required GlobalKey<FormState> formKey,
    List<Widget>? fields,
    List<Widget> Function(void Function(void Function()))? fieldsBuilder,
  }) async {
    final result = await showModalBottomSheet<bool>(
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
                  Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...(fieldsBuilder != null
                      ? fieldsBuilder(setSheet)
                      : (fields ?? [])),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
