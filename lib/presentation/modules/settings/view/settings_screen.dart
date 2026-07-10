import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/theme/theme_controller.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/institute_repository.dart";
import "package:edulink/domain/entities/institute.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _session = Get.find<SessionController>();
  final _theme = Get.find<ThemeController>();
  final _instituteRepo = Get.find<InstituteRepository>();
  final _academics = Get.find<AcademicsRepository>();

  Future<void> _createInstitute() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    InstituteType type = InstituteType.school;

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
                Text("Create Institute",
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Institute name"),
                  validator: (v) => Validators.required(v, "Name"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<InstituteType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: "Type"),
                  items: InstituteType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) =>
                      setSheet(() => type = v ?? InstituteType.school),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration:
                      const InputDecoration(labelText: "Address (optional)"),
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
      ),
    );

    if (ok == true) {
      try {
        final institute = await _instituteRepo.create(Institute(
          id: "",
          name: nameCtrl.text.trim(),
          type: type,
          address:
              addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
          principalId: _session.userId,
        ));
        await _academics.assignInstitute(_session.userId ?? "", institute.id);
        await _session.refreshProfile();
        SnackbarUtils.showSuccess("Institute created");
        setState(() {});
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _session.profile;
    final role = _session.role;
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppAvatar(
                      name: profile?.fullName,
                      imageUrl: profile?.avatarUrl,
                      radius: 28,
                      color: AppColors.roleColor(role.key)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.fullName ?? "User",
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(profile?.email ?? "",
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(role.label),
                          backgroundColor:
                              AppColors.roleColor(role.key).withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                              color: AppColors.roleColor(role.key),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (role.canManageInstitute && _session.instituteId == null)
            Card(
              color: AppColors.warning.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(Iconsax.buildings, color: AppColors.warning),
                title: const Text("Set up your institute"),
                subtitle:
                    const Text("Create your school/college to begin."),
                trailing: const Icon(Iconsax.add_circle),
                onTap: _createInstitute,
              ),
            ),
          Card(
            child: Column(
              children: [
                Obx(() => SwitchListTile(
                      secondary: const Icon(Iconsax.moon),
                      title: const Text("Dark mode"),
                      value: _theme.isDarkMode,
                      onChanged: (_) => _theme.toggleTheme(),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Iconsax.logout, color: AppColors.error),
              title: const Text("Sign out",
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await _session.signOut();
                Get.offAllNamed(AppRoutes.login);
              },
            ),
          ),
        ],
      ),
    );
  }
}
