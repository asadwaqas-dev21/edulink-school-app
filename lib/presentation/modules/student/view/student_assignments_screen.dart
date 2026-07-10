import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/domain/entities/assignment.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/assessments/view/assignment_details_screen.dart";

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  final _academics = Get.find<AcademicsRepository>();
  final _assess = Get.find<AssessmentRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<Assignment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Assignment>> _load() async {
    final enrollments =
        await _academics.enrollmentsForStudent(_session.userId ?? "");
    final all = <Assignment>[];
    for (final e in enrollments) {
      all.addAll(await _assess.assignmentsForClass(e.classId));
    }
    all.sort((a, b) => (a.dueDate ?? DateTime(2100))
        .compareTo(b.dueDate ?? DateTime(2100)));
    return all;
  }

  void _reload() { setState(() { _future = _load(); }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignments")),
      body: FutureBuilder<List<Assignment>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Iconsax.task_square,
              title: "No assignments",
              subtitle: "New assignments will show up here.",
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (a.isOverdue
                              ? AppColors.error
                              : AppColors.primary)
                          .withValues(alpha: 0.12),
                      child: Icon(Iconsax.task_square,
                          color:
                              a.isOverdue ? AppColors.error : AppColors.primary),
                    ),
                    title: Text(a.title),
                    subtitle: Text([
                      if (a.subjectName != null) a.subjectName!,
                      if (a.dueDate != null) "Due ${Formatters.date(a.dueDate)}",
                    ].join("  •  ")),
                    trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                    onTap: () async {
                      await Get.to(
                          () => AssignmentDetailsScreen(assignment: a));
                      _reload();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
