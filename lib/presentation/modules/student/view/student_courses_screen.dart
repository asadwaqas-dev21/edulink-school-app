import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/academics/view/class_details_screen.dart";

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _repo = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<Enrollment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.enrollmentsForStudent(_session.userId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Courses")),
      body: FutureBuilder<List<Enrollment>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final enrollments = snap.data ?? [];
          if (enrollments.isEmpty) {
            return const EmptyState(
              icon: Iconsax.book_1,
              title: "Not enrolled yet",
              subtitle: "You'll see your classes once enrolled.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: enrollments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = enrollments[i];
              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(Iconsax.book_1, color: AppColors.primary),
                  ),
                  title: Text(e.className ?? "My Class"),
                  subtitle: e.rollNo != null ? Text("Roll: ${e.rollNo}") : null,
                  trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                  onTap: () => Get.to(() => ClassDetailsScreen(
                        schoolClass: SchoolClass(
                          id: e.classId,
                          instituteId: _session.instituteId ?? "",
                          name: e.className ?? "My Class",
                        ),
                      )),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
