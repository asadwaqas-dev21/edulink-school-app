import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/communication/view/chat_screen.dart";

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repo = Get.find<CommunicationRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<Profile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.contacts(
        _session.instituteId ?? "", _session.userId ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: FutureBuilder<List<Profile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final contacts = snap.data ?? [];
          if (contacts.isEmpty) {
            return const EmptyState(
              icon: Iconsax.messages_1,
              title: "No contacts",
              subtitle: "People in your institute will appear here.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = contacts[i];
              return Card(
                child: ListTile(
                  leading: AppAvatar(
                      name: c.fullName,
                      color: AppColors.roleColor(c.role.key)),
                  title: Text(c.fullName),
                  subtitle: Text(c.role.label),
                  trailing: const Icon(Iconsax.message, size: 18),
                  onTap: () => Get.to(() => ChatScreen(contact: c)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
