import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/data/repositories/institute_repository.dart";
import "package:edulink/domain/entities/institute.dart";
import "package:edulink/domain/entities/message.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/presentation/web/pages/web_overview_pages.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_modals.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

// ══════════════════════════ COMMUNICATION ══════════════════════════
class WebCommunicationPage extends StatefulWidget {
  const WebCommunicationPage({super.key});

  @override
  State<WebCommunicationPage> createState() => _WebCommunicationPageState();
}

class _WebCommunicationPageState extends State<WebCommunicationPage> {
  final _c = Get.find<WebDashboardController>();
  final _comm = Get.find<CommunicationRepository>();
  final _session = Get.find<SessionController>();
  final _msgCtrl = TextEditingController();

  Profile? _contact;
  List<Message> _messages = [];
  bool _loadingMsgs = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChat(Profile p) async {
    setState(() {
      _contact = p;
      _loadingMsgs = true;
      _messages = [];
    });
    final msgs = await _comm.conversation(_session.userId ?? "", p.id);
    if (mounted) {
      setState(() {
        _messages = msgs.reversed.toList();
        _loadingMsgs = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _contact == null) return;
    _msgCtrl.clear();
    try {
      await _comm.send(Message(
        id: "",
        senderId: _session.userId ?? "",
        receiverId: _contact!.id,
        body: text,
      ));
      await _openChat(_contact!);
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final contacts =
          _c.allPeople.where((p) => p.id != _session.userId).toList();
      return WebPageBody(
        children: [
          WebPageHead(
            title: "Communication",
            subtitle: "Publish announcements and message your institute.",
            actions: [
              WebButton(
                  label: "New announcement",
                  icon: Iconsax.send_2,
                  kind: WebBtnKind.primary,
                  onTap: () => showAnnouncementModal(context)),
            ],
          ),
          _layout(context, contacts),
        ],
      );
    });
  }

  Widget _layout(BuildContext context, List<Profile> contacts) {
    final announcements = _announcements(context);
    final chat = _chat(context, contacts);
    if (MediaQuery.of(context).size.width < 980) {
      return Column(children: [announcements, const SizedBox(height: 17), chat]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 10, child: announcements),
        const SizedBox(width: 17),
        Expanded(flex: 11, child: chat),
      ],
    );
  }

  Widget _announcements(BuildContext context) {
    final t = WebTokens.of(context);
    return WebCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Announcements", subtitle: "Recent institute broadcasts"),
          const SizedBox(height: 12),
          if (_c.announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                  child: Text("No announcements yet.",
                      style: TextStyle(color: t.muted, fontSize: 11))),
            )
          else
            ..._c.announcements.take(6).map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      border: Border.all(color: t.line),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(a.title,
                                style: TextStyle(
                                    color: t.ink,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                                color: t.primarySoft,
                                borderRadius: BorderRadius.circular(7)),
                            child: Text(
                                a.audience[0].toUpperCase() +
                                    a.audience.substring(1),
                                style: TextStyle(
                                    color: t.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(a.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: t.muted, fontSize: 10, height: 1.5)),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("By ${a.authorName ?? "Staff"}",
                              style: TextStyle(color: t.muted, fontSize: 8.5)),
                          Text(Formatters.dateTime(a.createdAt),
                              style: TextStyle(color: t.muted, fontSize: 8.5)),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _chat(BuildContext context, List<Profile> contacts) {
    final t = WebTokens.of(context);
    return WebCard(
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: 560,
        child: Row(
          children: [
            Container(
              width: 190,
              decoration: BoxDecoration(
                  color: t.panel2,
                  border: Border(right: BorderSide(color: t.line))),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(3, 2, 3, 10),
                    child: Text("Messages",
                        style: TextStyle(
                            color: t.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                  if (contacts.isEmpty)
                    Text("No contacts",
                        style: TextStyle(color: t.muted, fontSize: 10)),
                  ...contacts.map((p) {
                    final active = p.id == _contact?.id;
                    return InkWell(
                      onTap: () => _openChat(p),
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: active ? t.panel : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: active ? t.shadowSm : null,
                        ),
                        child: Row(
                          children: [
                            Monogram(Formatters.initials(p.fullName),
                                tone: roleTone(p.role), size: 30),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: t.ink,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                  Text(p.role.label,
                                      style: TextStyle(
                                          color: t.muted, fontSize: 8)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(child: _chatMain(context)),
          ],
        ),
      ),
    );
  }

  Widget _chatMain(BuildContext context) {
    final t = WebTokens.of(context);
    if (_contact == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.messages_1, size: 34, color: t.muted),
            const SizedBox(height: 10),
            Text("Select a contact to start chatting",
                style: TextStyle(color: t.muted, fontSize: 11)),
          ],
        ),
      );
    }
    return Column(
      children: [
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.line))),
          child: Row(
            children: [
              Monogram(Formatters.initials(_contact!.fullName),
                  tone: roleTone(_contact!.role), size: 32),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_contact!.fullName,
                      style: TextStyle(
                          color: t.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  Text(_contact!.role.label,
                      style: TextStyle(color: t.muted, fontSize: 8.5)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingMsgs
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  color: t.panel2,
                  child: _messages.isEmpty
                      ? Center(
                          child: Text("No messages yet. Say hello!",
                              style:
                                  TextStyle(color: t.muted, fontSize: 10.5)))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            for (final m in _messages)
                              _bubble(context, m,
                                  m.senderId == _session.userId),
                          ],
                        ),
                ),
        ),
        Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: t.line))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: "Write a message…",
                    isDense: true,
                    filled: true,
                    fillColor: t.panel2,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(color: t.line)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(color: t.line)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: t.primary,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  onTap: _send,
                  borderRadius: BorderRadius.circular(11),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Iconsax.send_1, size: 17, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(BuildContext context, Message m, bool me) {
    final t = WebTokens.of(context);
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.32),
        decoration: BoxDecoration(
          color: me ? t.primary : t.panel,
          border: me ? null : Border.all(color: t.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(13),
            topRight: const Radius.circular(13),
            bottomLeft: Radius.circular(me ? 13 : 4),
            bottomRight: Radius.circular(me ? 4 : 13),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.body,
                style: TextStyle(
                    color: me ? Colors.white : t.ink,
                    fontSize: 10.5,
                    height: 1.45)),
            const SizedBox(height: 4),
            Text(Formatters.time(m.createdAt),
                style: TextStyle(
                    color: me ? Colors.white70 : t.muted, fontSize: 7.5)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════ REPORTS ══════════════════════════
class WebReportsPage extends StatelessWidget {
  const WebReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WebDashboardController>();
    return Obx(() {
      return WebPageBody(
        children: [
          WebPageHead(
            title: "Reports",
            subtitle: "Academic, attendance and financial performance.",
            actions: [
              WebButton(
                  label: "Export report",
                  icon: Iconsax.document_download,
                  onTap: () => SnackbarUtils.showInfo("Export coming soon")),
            ],
          ),
          WebGrid(
            columns: MediaQuery.of(context).size.width < 1180 ? 2 : 4,
            childAspectRatio: 3.1,
            children: [
              _summary(context, Iconsax.chart_2, "Collection rate",
                  "${(c.collectionRate * 100).toStringAsFixed(1)}%", Tone.primary),
              _summary(context, Iconsax.money_recive, "Collected",
                  Formatters.money(c.collected), Tone.success),
              _summary(context, Iconsax.receipt_item, "Outstanding",
                  Formatters.money(c.outstanding), Tone.warning),
              _summary(context, Iconsax.people, "Students",
                  "${c.overview["students"] ?? 0}", Tone.info),
            ],
          ),
          const SizedBox(height: 17),
          _reportRow(context, c),
        ],
      );
    });
  }

  Widget _reportRow(BuildContext context, WebDashboardController c) {
    final fees = WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(title: "Fee Overview", subtitle: "Billed vs collected"),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _BarChart(
              bars: [
                _Bar("Billed", c.billed, Tone.info),
                _Bar("Collected", c.collected, Tone.success),
                _Bar("Outstanding", c.outstanding, Tone.warning),
                _Bar("Expenses", c.paidExpense, Tone.danger),
              ],
            ),
          ),
        ],
      ),
    );

    final expenses = WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Expenses by Category", subtitle: "All recorded expenses"),
          const SizedBox(height: 16),
          ..._expenseBars(context, c),
        ],
      ),
    );

    if (MediaQuery.of(context).size.width < 980) {
      return Column(children: [fees, const SizedBox(height: 17), expenses]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: fees),
        const SizedBox(width: 17),
        Expanded(child: expenses),
      ],
    );
  }

  List<Widget> _expenseBars(BuildContext context, WebDashboardController c) {
    final totals = <String, num>{};
    for (final e in c.expenses) {
      totals[e.category.label] = (totals[e.category.label] ?? 0) + e.amount;
    }
    if (totals.isEmpty) {
      return [
        Text("No expenses recorded.",
            style: TextStyle(color: WebTokens.of(context).muted, fontSize: 11))
      ];
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value;
    final tones = [Tone.primary, Tone.success, Tone.warning, Tone.info];
    return [
      for (int i = 0; i < entries.length && i < 6; i++) ...[
        HBar(
          label: entries[i].key,
          value: Formatters.money(entries[i].value),
          fraction: max == 0 ? 0 : entries[i].value / max,
          tone: tones[i % tones.length],
        ),
        if (i < entries.length - 1 && i < 5) const SizedBox(height: 13),
      ],
    ];
  }

  Widget _summary(BuildContext context, IconData icon, String label,
      String value, Tone tone) {
    final t = WebTokens.of(context);
    return WebCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
                color: tone.bg(t), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: tone.fg(t)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.muted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar {
  final String label;
  final num value;
  final Tone tone;
  _Bar(this.label, this.value, this.tone);
}

class _BarChart extends StatelessWidget {
  final List<_Bar> bars;
  const _BarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final max = bars.fold<num>(1, (m, b) => b.value > m ? b.value : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final b in bars)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(Formatters.money(b.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: 1,
                    child: Container(
                      height: (b.value / max * 130).clamp(4, 130).toDouble(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [b.tone.fg(t), b.tone.fg(t).withValues(alpha: 0.55)],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(b.label,
                      style: TextStyle(color: t.muted, fontSize: 8.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════ SETTINGS ══════════════════════════
class WebSettingsPage extends StatefulWidget {
  const WebSettingsPage({super.key});

  @override
  State<WebSettingsPage> createState() => _WebSettingsPageState();
}

class _WebSettingsPageState extends State<WebSettingsPage> {
  final _c = Get.find<WebDashboardController>();
  final _institutes = Get.find<InstituteRepository>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  InstituteType _type = InstituteType.school;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final inst = _c.institute.value;
    _nameCtrl.text = inst?.name ?? "";
    _phoneCtrl.text = inst?.phone ?? "";
    _emailCtrl.text = inst?.email ?? "";
    _addressCtrl.text = inst?.address ?? "";
    _type = inst?.type ?? InstituteType.school;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final inst = _c.institute.value;
    if (inst == null) {
      SnackbarUtils.showWarning("No institute to update");
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      SnackbarUtils.showWarning("Institute name is required");
      return;
    }
    setState(() => _saving = true);
    try {
      await _institutes.update(
        inst.id,
        Institute(
          id: inst.id,
          name: _nameCtrl.text.trim(),
          type: _type,
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          logoUrl: inst.logoUrl,
          principalId: inst.principalId,
        ),
      );
      await _c.load();
      SnackbarUtils.showSuccess("Institute settings updated");
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final profile = WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Institute Profile",
              subtitle: "Public and administrative information"),
          const SizedBox(height: 16),
          _field(t, "Institute name", _nameCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: WebField(
                  label: "Institute type",
                  child: DropdownButtonFormField<InstituteType>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: _decoration(t),
                    items: InstituteType.values
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field(t, "Phone", _phoneCtrl)),
            ],
          ),
          const SizedBox(height: 12),
          _field(t, "Email", _emailCtrl),
          const SizedBox(height: 12),
          _field(t, "Address", _addressCtrl, maxLines: 3),
        ],
      ),
    );

    final defaults = WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Academic & Finance",
              subtitle: "Defaults used throughout Edulink"),
          const SizedBox(height: 16),
          WebField(
              label: "Currency",
              child: InputDecorator(
                  decoration: _decoration(t),
                  child: Text("PKR (Rs)",
                      style: TextStyle(color: t.muted, fontSize: 12)))),
          const SizedBox(height: 12),
          WebField(
              label: "Timezone",
              child: InputDecorator(
                  decoration: _decoration(t),
                  child: Text("Asia/Karachi (PKT)",
                      style: TextStyle(color: t.ink, fontSize: 12)))),
          const SizedBox(height: 12),
          Text(
              "Currency and formatting apply across fees, slips and finance reports.",
              style: TextStyle(color: t.muted, fontSize: 10.5)),
        ],
      ),
    );

    return WebPageBody(
      children: [
        WebPageHead(
          title: "Settings",
          subtitle: "Configure institute identity and system preferences.",
          actions: [
            WebButton(
                label: _saving ? "Saving…" : "Save changes",
                kind: WebBtnKind.primary,
                onTap: _saving ? null : _save),
          ],
        ),
        if (MediaQuery.of(context).size.width < 980)
          Column(children: [profile, const SizedBox(height: 17), defaults])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: profile),
              const SizedBox(width: 17),
              Expanded(child: defaults),
            ],
          ),
      ],
    );
  }

  InputDecoration _decoration(WebTokens t) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: t.panel2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.line)),
      );

  Widget _field(WebTokens t, String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return WebField(
      label: label,
      child: TextField(
          controller: ctrl, maxLines: maxLines, decoration: _decoration(t)),
    );
  }
}
