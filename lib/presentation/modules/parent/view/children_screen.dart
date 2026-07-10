import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/domain/entities/parent_link.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/reports/view/student_progress_screen.dart";

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  final _academics = Get.find<AcademicsRepository>();
  final _report = Get.find<ReportRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<ParentLink>> _future;

  @override
  void initState() {
    super.initState();
    _future = _academics.childrenOfParent(_session.userId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Children")),
      body: FutureBuilder<List<ParentLink>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final children = snap.data ?? [];
          if (children.isEmpty) {
            return const EmptyState(
              icon: Iconsax.people,
              title: "No children linked",
              subtitle:
                  "Ask your institute to link your account to your child.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = children[i];
              return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Get.to(() => StudentProgressScreen(
                          studentId: c.studentId,
                          studentName: c.studentName,
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          AppAvatar(
                              name: c.studentName,
                              radius: 26,
                              color: AppColors.roleStudent),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.studentName ?? "Student",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                if (c.relation != null)
                                  Text(c.relation!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                const SizedBox(height: 8),
                                FutureBuilder<double>(
                                  future: _report.attendanceRate(c.studentId),
                                  builder: (context, s) {
                                    final rate = s.data ?? 0;
                                    return Row(
                                      children: [
                                        const Icon(Iconsax.task_square,
                                            size: 16, color: AppColors.accent),
                                        const SizedBox(width: 6),
                                        Text(
                                            "Attendance: ${rate.toStringAsFixed(0)}%",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          );
        },
      ),
    );
  }
}
