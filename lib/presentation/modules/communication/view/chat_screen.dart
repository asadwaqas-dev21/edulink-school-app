import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/domain/entities/message.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class ChatScreen extends StatefulWidget {
  final Profile contact;
  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repo = Get.find<CommunicationRepository>();
  final _session = Get.find<SessionController>();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late Future<List<Message>> _future;
  bool _sending = false;

  String get _uid => _session.userId ?? "";

  @override
  void initState() {
    super.initState();
    _future = _repo.conversation(_uid, widget.contact.id);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() { _future = _repo.conversation(_uid, widget.contact.id); });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _repo.send(Message(
        id: "",
        senderId: _uid,
        receiverId: widget.contact.id,
        body: text,
      ));
      _textCtrl.clear();
      _reload();
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contact.fullName)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }
                final messages = snap.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text("Say hello 👋",
                        style: Theme.of(context).textTheme.bodyMedium),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.senderId == _uid;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: mine
                              ? AppColors.primary
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(mine ? 16 : 4),
                            bottomRight: Radius.circular(mine ? 4 : 16),
                          ),
                          border: mine
                              ? null
                              : Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.body,
                                style: TextStyle(
                                    color: mine ? Colors.white : null)),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.time(m.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: mine ? Colors.white70 : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          hintText: "Type a message..."),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Iconsax.send_1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
