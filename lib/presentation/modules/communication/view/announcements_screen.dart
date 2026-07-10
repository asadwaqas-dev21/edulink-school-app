import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/domain/entities/announcement.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _repo = Get.find<CommunicationRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.announcements(_session.instituteId ?? "");
  }

  void _reload() {
    setState(() {
      _future = _repo.announcements(_session.instituteId ?? "");
    });
  }

  Future<void> _post() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String audience = "all";

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
                  Text("New Announcement",
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                    validator: (v) => Validators.required(v, "Title"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Message"),
                    validator: (v) => Validators.required(v, "Message"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: audience,
                    decoration: const InputDecoration(labelText: "Audience"),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("Everyone")),
                      DropdownMenuItem(
                          value: "students", child: Text("Students")),
                      DropdownMenuItem(
                          value: "parents", child: Text("Parents")),
                      DropdownMenuItem(
                          value: "teachers", child: Text("Teachers")),
                    ],
                    onChanged: (v) => setSheet(() => audience = v ?? "all"),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: const Text("Post"),
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
        await _repo.post(Announcement(
          id: "",
          instituteId: _session.instituteId ?? "",
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          authorId: _session.userId,
          audience: audience,
        ));
        SnackbarUtils.showSuccess("Announcement posted");
        _reload();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _session.role.canBroadcast;
    return Scaffold(
      appBar: AppBar(title: const Text("Announcements")),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _post,
              icon: const Icon(Iconsax.add),
              label: const Text("Post"),
            )
          : null,
      body: FutureBuilder<List<Announcement>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Iconsax.notification,
              title: "No announcements",
              subtitle: "Institute updates will appear here.",
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final a = items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(name: a.authorName, radius: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.authorName ?? "Institute",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall),
                                  Text(Formatters.dateTime(a.createdAt),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(a.audience),
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(a.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(a.body,
                            style: Theme.of(context).textTheme.bodyMedium),
                        if (canPost) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Iconsax.trash,
                                  size: 16, color: AppColors.error),
                              label: const Text("Delete",
                                  style: TextStyle(color: AppColors.error)),
                              onPressed: () async {
                                await _repo.deleteAnnouncement(a.id);
                                _reload();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
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
