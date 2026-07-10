import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/domain/entities/parent_link.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen>
    with SingleTickerProviderStateMixin {
  final _repo = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  late final TabController _tab = TabController(length: 3, vsync: this);

  String get _instituteId => _session.instituteId ?? "";

  late Future<List<Profile>> _teachers;
  late Future<List<Profile>> _students;
  late Future<List<Profile>> _parents;

  static const _tabRoles = [
    UserRole.teacher,
    UserRole.student,
    UserRole.parent,
  ];

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _reloadAll() {
    setState(() {
      _teachers = _repo.peopleByRole(_instituteId, "teacher");
      _students = _repo.peopleByRole(_instituteId, "student");
      _parents = _repo.peopleByRole(_instituteId, "parent");
    });
  }

  Future<void> _addMember() async {
    // Load lookups the role-specific fields depend on.
    final classes = await _repo.classes(_instituteId);
    final students = await _repo.peopleByRole(_instituteId, "student");
    if (!mounted) return;

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    var role = _tabRoles[_tab.index];
    String? enrollClassId;
    String? classTeacherOfId;
    String? childStudentId;

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
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Add member to institute",
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    "Create a new account with a name, email and password, then add any role-specific details.",
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: _tabRoles
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setSheet(() => role = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Full name"),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, "Full name"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: "Email"),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: "Password"),
                    obscureText: true,
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration:
                        const InputDecoration(labelText: "Phone (optional)"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  ..._roleFields(
                    ctx,
                    role: role,
                    classes: classes,
                    students: students,
                    rollCtrl: rollCtrl,
                    relationCtrl: relationCtrl,
                    enrollClassId: enrollClassId,
                    classTeacherOfId: classTeacherOfId,
                    childStudentId: childStudentId,
                    onEnrollClass: (v) => setSheet(() => enrollClassId = v),
                    onClassTeacherOf: (v) =>
                        setSheet(() => classTeacherOfId = v),
                    onChildStudent: (v) => setSheet(() => childStudentId = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: const Text("Create member"),
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
        final profile = await _repo.createMember(
          email: emailCtrl.text.trim(),
          password: passwordCtrl.text,
          fullName: nameCtrl.text.trim(),
          role: role,
          instituteId: _instituteId,
          phone: phoneCtrl.text.trim(),
          enrollClassId: role.isStudent ? enrollClassId : null,
          rollNo: role.isStudent ? rollCtrl.text.trim() : null,
          classTeacherOfId: role.isTeacher ? classTeacherOfId : null,
          childStudentId: role.isParent ? childStudentId : null,
          relation: role.isParent ? relationCtrl.text.trim() : null,
        );
        SnackbarUtils.showSuccess("${profile.fullName} added as ${role.label}");
        _reloadAll();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  List<Widget> _roleFields(
    BuildContext ctx, {
    required UserRole role,
    required List<SchoolClass> classes,
    required List<Profile> students,
    required TextEditingController rollCtrl,
    required TextEditingController relationCtrl,
    required String? enrollClassId,
    required String? classTeacherOfId,
    required String? childStudentId,
    required ValueChanged<String?> onEnrollClass,
    required ValueChanged<String?> onClassTeacherOf,
    required ValueChanged<String?> onChildStudent,
  }) {
    if (role.isStudent) {
      return [
        DropdownButtonFormField<String>(
          initialValue: enrollClassId,
          decoration:
              const InputDecoration(labelText: "Enroll in class (optional)"),
          items: classes
              .map((c) =>
                  DropdownMenuItem(value: c.id, child: Text(c.displayName)))
              .toList(),
          onChanged: onEnrollClass,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: rollCtrl,
          decoration: const InputDecoration(labelText: "Roll no (optional)"),
        ),
      ];
    }
    if (role.isTeacher) {
      return [
        DropdownButtonFormField<String>(
          initialValue: classTeacherOfId,
          decoration: const InputDecoration(
              labelText: "Class teacher of (optional)"),
          items: classes
              .map((c) =>
                  DropdownMenuItem(value: c.id, child: Text(c.displayName)))
              .toList(),
          onChanged: onClassTeacherOf,
        ),
      ];
    }
    return [
      DropdownButtonFormField<String>(
        initialValue: childStudentId,
        decoration:
            const InputDecoration(labelText: "Link to child (optional)"),
        items: students
            .map((s) =>
                DropdownMenuItem(value: s.id, child: Text(s.fullName)))
            .toList(),
        onChanged: onChildStudent,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: relationCtrl,
        decoration: const InputDecoration(
            labelText: "Relation (optional, e.g. Father)"),
      ),
    ];
  }

  Future<void> _linkParent(Profile parent) async {
    final students = await _repo.peopleByRole(_instituteId, "student");
    Profile? child;
    final relationCtrl = TextEditingController();
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
              Text("Link ${parent.fullName} to a child",
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<Profile>(
                initialValue: child,
                decoration: const InputDecoration(labelText: "Student"),
                items: students
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.fullName)))
                    .toList(),
                onChanged: (v) => setSheet(() => child = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(
                    labelText: "Relation (e.g. Father, Mother)"),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Link"),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true && child != null) {
      try {
        await _repo.linkParent(ParentLink(
          id: "",
          parentId: parent.id,
          studentId: child!.id,
          relation:
              relationCtrl.text.trim().isEmpty ? null : relationCtrl.text.trim(),
        ));
        SnackbarUtils.showSuccess("Linked successfully");
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("People"),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Teachers"),
            Tab(text: "Students"),
            Tab(text: "Parents"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _addMember,
        icon: const Icon(Iconsax.user_add),
        label: const Text("Add Member"),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _list(_teachers, UserRole.teacher),
          _list(_students, UserRole.student),
          _list(_parents, UserRole.parent),
        ],
      ),
    );
  }

  Widget _list(Future<List<Profile>> future, UserRole role) {
    return FutureBuilder<List<Profile>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        final people = snap.data ?? [];
        if (people.isEmpty) {
          return EmptyState(
            icon: role.icon as IconData,
            title: "No ${role.label.toLowerCase()}s yet",
            subtitle: "Tap Add Member to create one.",
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: people.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = people[i];
            return Card(
              child: ListTile(
                leading: AppAvatar(
                    name: p.fullName, color: AppColors.roleColor(role.key)),
                title: Text(p.fullName),
                subtitle: Text(p.email),
                trailing: role.isParent
                    ? IconButton(
                        icon: const Icon(Iconsax.link, size: 20),
                        tooltip: "Link to child",
                        onPressed: () => _linkParent(p),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
