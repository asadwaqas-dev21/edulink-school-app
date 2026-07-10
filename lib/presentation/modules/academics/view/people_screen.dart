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
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _repo = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  String get _instituteId => _session.instituteId ?? "";

  late Future<List<Profile>> _teachers;
  late Future<List<Profile>> _students;
  late Future<List<Profile>> _parents;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  void _reloadAll() {
    setState(() {
      _teachers = _repo.peopleByRole(_instituteId, "teacher");
      _students = _repo.peopleByRole(_instituteId, "student");
      _parents = _repo.peopleByRole(_instituteId, "parent");
    });
  }

  Future<void> _addMember() async {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
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
              Text("Add member to institute",
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                "The person must already have an Edulink account. Enter their email to add them to your institute.",
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
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
    );

    if (ok == true) {
      try {
        final profile = await _repo.findByEmail(emailCtrl.text);
        if (profile == null) {
          SnackbarUtils.showError("No account found for that email.");
          return;
        }
        await _repo.assignInstitute(profile.id, _instituteId);
        SnackbarUtils.showSuccess("${profile.fullName} added");
        _reloadAll();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("People"),
          bottom: const TabBar(
            tabs: [
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
          children: [
            _list(_teachers, UserRole.teacher),
            _list(_students, UserRole.student),
            _list(_parents, UserRole.parent),
          ],
        ),
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
            subtitle: "Add members by their account email.",
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
