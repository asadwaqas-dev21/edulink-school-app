import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/domain/entities/subject.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/attendance/view/attendance_screen.dart";
import "package:edulink/presentation/modules/attendance/view/timetable_screen.dart";
import "package:edulink/presentation/modules/courses/view/subject_content_screen.dart";

class ClassDetailsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const ClassDetailsScreen({super.key, required this.schoolClass});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  final _repo = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<Subject>> _subjectsFuture;
  late Future<List<Enrollment>> _studentsFuture;

  SchoolClass get _class => widget.schoolClass;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _repo.subjects(_class.id);
    _studentsFuture = _repo.enrollments(_class.id);
  }

  void _reloadSubjects() {
    setState(() {
      _subjectsFuture = _repo.subjects(_class.id);
    });
  }

  void _reloadStudents() {
    setState(() {
      _studentsFuture = _repo.enrollments(_class.id);
    });
  }

  Future<void> _addSubject() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Profile? teacher;

    final teachers =
        await _repo.peopleByRole(_session.instituteId ?? "", "teacher");

    if (!mounted) return;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Add Subject", style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Subject name"),
                  validator: (v) => Validators.required(v, "Name"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  decoration:
                      const InputDecoration(labelText: "Code (optional)"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Profile>(
                  initialValue: teacher,
                  decoration: const InputDecoration(labelText: "Teacher"),
                  items: teachers
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.fullName)))
                      .toList(),
                  onChanged: (v) => setSheet(() => teacher = v),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      try {
        await _repo.createSubject(Subject(
          id: "",
          instituteId: _session.instituteId ?? "",
          classId: _class.id,
          name: nameCtrl.text.trim(),
          code: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
          teacherId: teacher?.id,
        ));
        SnackbarUtils.showSuccess("Subject added");
        _reloadSubjects();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  Future<void> _enrollStudent() async {
    final rollCtrl = TextEditingController();
    Profile? student;
    final students =
        await _repo.peopleByRole(_session.instituteId ?? "", "student");

    if (!mounted) return;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Enroll Student", style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<Profile>(
                initialValue: student,
                decoration: const InputDecoration(labelText: "Student"),
                items: students
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.fullName)))
                    .toList(),
                onChanged: (v) => setSheet(() => student = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rollCtrl,
                decoration:
                    const InputDecoration(labelText: "Roll no (optional)"),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Enroll"),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true && student != null) {
      try {
        await _repo.enroll(Enrollment(
          id: "",
          classId: _class.id,
          studentId: student!.id,
          rollNo: rollCtrl.text.trim().isEmpty ? null : rollCtrl.text.trim(),
        ));
        SnackbarUtils.showSuccess("Student enrolled");
        _reloadStudents();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _session.role.canManageClasses;
    final canTeach = _session.role.canTeach;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_class.displayName),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Subjects"),
              Tab(text: "Students"),
              Tab(text: "Tools"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _subjectsTab(canManage),
            _studentsTab(canManage),
            _toolsTab(canTeach),
          ],
        ),
      ),
    );
  }

  Widget _subjectsTab(bool canManage) {
    return Stack(
      children: [
        FutureBuilder<List<Subject>>(
          future: _subjectsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }
            final subjects = snap.data ?? [];
            if (subjects.isEmpty) {
              return const EmptyState(
                icon: Iconsax.book,
                title: "No subjects",
                subtitle: "Add subjects and assign teachers.",
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = subjects[i];
                return Card(
                  child: ListTile(
                    leading: Icon(Iconsax.book_1, color: AppColors.primary),
                    title: Text(s.name),
                    subtitle: Text([
                      if (s.code != null) s.code!,
                      if (s.teacherName != null) "Teacher: ${s.teacherName}",
                    ].join("  •  ")),
                    trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                    onTap: () => Get.to(() => SubjectContentScreen(subject: s)),
                  ),
                );
              },
            );
          },
        ),
        if (canManage)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: "addSubject",
              onPressed: _addSubject,
              icon: const Icon(Iconsax.add),
              label: const Text("Subject"),
            ),
          ),
      ],
    );
  }

  Widget _studentsTab(bool canManage) {
    return Stack(
      children: [
        FutureBuilder<List<Enrollment>>(
          future: _studentsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingWidget();
            }
            final students = snap.data ?? [];
            if (students.isEmpty) {
              return const EmptyState(
                icon: Iconsax.people,
                title: "No students",
                subtitle: "Enroll students into this class.",
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: students.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = students[i];
                return Card(
                  child: ListTile(
                    leading: AppAvatar(name: e.studentName, radius: 20),
                    title: Text(e.studentName ?? "Student"),
                    subtitle:
                        e.rollNo != null ? Text("Roll: ${e.rollNo}") : null,
                    trailing: canManage
                        ? IconButton(
                            icon: const Icon(Iconsax.trash,
                                color: AppColors.error, size: 20),
                            onPressed: () async {
                              await _repo.unenroll(e.id);
                              _reloadStudents();
                            },
                          )
                        : null,
                  ),
                );
              },
            );
          },
        ),
        if (canManage)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: "enroll",
              onPressed: _enrollStudent,
              icon: const Icon(Iconsax.add),
              label: const Text("Enroll"),
            ),
          ),
      ],
    );
  }

  Widget _toolsTab(bool canTeach) {
    final tools = <Widget>[
      _toolTile(Iconsax.calendar_1, "Timetable", "View & edit class schedule",
          () => Get.to(() => TimetableScreen(schoolClass: _class))),
      if (canTeach)
        _toolTile(Iconsax.task_square, "Attendance", "Mark daily attendance",
            () => Get.to(() => AttendanceScreen(schoolClass: _class))),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: tools,
    );
  }

  Widget _toolTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.14),
          child: Icon(icon, color: AppColors.accent),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Iconsax.arrow_right_3, size: 18),
        onTap: onTap,
      ),
    );
  }
}
