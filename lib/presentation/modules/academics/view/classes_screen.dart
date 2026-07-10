import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/academics/view/class_details_screen.dart";

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _repo = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();
  late Future<List<SchoolClass>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<SchoolClass>> _load() {
    final role = _session.role;
    if (role.isTeacher) {
      return _repo.classesForTeacher(_session.userId ?? "");
    }
    return _repo.classes(_session.instituteId ?? "");
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _createClass() async {
    final nameCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
              Text("New Class", style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: "Class name (e.g. Grade 8)"),
                validator: (v) => Validators.required(v, "Name"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sectionCtrl,
                decoration:
                    const InputDecoration(labelText: "Section (optional)"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: gradeCtrl,
                decoration:
                    const InputDecoration(labelText: "Grade level (optional)"),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: const Text("Create"),
              ),
            ],
          ),
        ),
      ),
    );

    if (created == true) {
      try {
        await _repo.createClass(SchoolClass(
          id: "",
          instituteId: _session.instituteId ?? "",
          name: nameCtrl.text.trim(),
          section:
              sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
          gradeLevel:
              gradeCtrl.text.trim().isEmpty ? null : gradeCtrl.text.trim(),
        ));
        SnackbarUtils.showSuccess("Class created");
        _reload();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _session.role.canManageClasses;
    return Scaffold(
      appBar: AppBar(title: const Text("Classes")),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _createClass,
              icon: const Icon(Iconsax.add),
              label: const Text("New Class"),
            )
          : null,
      body: FutureBuilder<List<SchoolClass>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Iconsax.warning_2,
              title: "Couldn't load classes",
              subtitle: snapshot.error.toString(),
              action: OutlinedButton(
                  onPressed: _reload, child: const Text("Retry")),
            );
          }
          final classes = snapshot.data ?? [];
          if (classes.isEmpty) {
            return EmptyState(
              icon: Iconsax.teacher,
              title: "No classes yet",
              subtitle: canManage
                  ? "Create your first class to get started."
                  : "You have not been assigned to any class.",
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = classes[i];
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(Iconsax.book_1, color: AppColors.primary),
                    ),
                    title: Text(c.displayName,
                        style: Theme.of(context).textTheme.titleMedium),
                    subtitle: c.gradeLevel != null
                        ? Text("Grade: ${c.gradeLevel}")
                        : null,
                    trailing: const Icon(Iconsax.arrow_right_3, size: 18),
                    onTap: () =>
                        Get.to(() => ClassDetailsScreen(schoolClass: c)),
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
