import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/attendance_repository.dart";
import "package:edulink/domain/entities/attendance_record.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/expense.dart";
import "package:edulink/domain/entities/timetable_entry.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_modals.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

// ══════════════════════════ ATTENDANCE ══════════════════════════
class WebAttendancePage extends StatefulWidget {
  const WebAttendancePage({super.key});

  @override
  State<WebAttendancePage> createState() => _WebAttendancePageState();
}

class _WebAttendancePageState extends State<WebAttendancePage> {
  final _c = Get.find<WebDashboardController>();
  final _academics = Get.find<AcademicsRepository>();
  final _attendance = Get.find<AttendanceRepository>();
  final _session = Get.find<SessionController>();

  String? _classId;
  final DateTime _date = DateTime.now();
  List<Enrollment> _students = [];
  final Map<String, AttendanceStatus> _marks = {};
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_c.classes.isNotEmpty) {
      _classId = _c.classes.first.id;
      _loadClass();
    }
  }

  Future<void> _loadClass() async {
    if (_classId == null) return;
    setState(() => _loading = true);
    try {
      final enr = await _academics.enrollments(_classId!);
      final existing = await _attendance.forClassOnDate(_classId!, _date);
      final map = {for (final r in existing) r.studentId: r.status};
      setState(() {
        _students = enr;
        _marks
          ..clear()
          ..addEntries(enr.map((e) => MapEntry(
              e.studentId, map[e.studentId] ?? AttendanceStatus.present)));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_classId == null || _students.isEmpty) return;
    setState(() => _saving = true);
    try {
      final records = _students
          .map((e) => AttendanceRecord(
                id: "",
                classId: _classId!,
                studentId: e.studentId,
                date: _date,
                status: _marks[e.studentId] ?? AttendanceStatus.present,
                markedBy: _session.userId,
              ))
          .toList();
      await _attendance.saveBatch(records);
      SnackbarUtils.showSuccess("Attendance saved");
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _count(AttendanceStatus s) => _marks.values.where((v) => v == s).length;

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return WebPageBody(
      children: [
        WebPageHead(
          title: "Attendance",
          subtitle: "Track daily presence, lateness and absences by class.",
          actions: [
            WebButton(
                label: _saving ? "Saving…" : "Save attendance",
                icon: Iconsax.tick_circle,
                kind: WebBtnKind.primary,
                onTap: _saving ? null : _save),
          ],
        ),
        WebGrid(
          columns: MediaQuery.of(context).size.width < 1180 ? 2 : 4,
          childAspectRatio: 3.1,
          children: [
            _summary(t, Iconsax.tick_circle, "Present",
                "${_count(AttendanceStatus.present)}", Tone.success),
            _summary(t, Iconsax.clock, "Late",
                "${_count(AttendanceStatus.late)}", Tone.warning),
            _summary(t, Iconsax.close_circle, "Absent",
                "${_count(AttendanceStatus.absent)}", Tone.danger),
            _summary(t, Iconsax.people, "Students", "${_students.length}",
                Tone.primary),
          ],
        ),
        const SizedBox(height: 17),
        WebCard(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.line))),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(Formatters.date(_date),
                          style: TextStyle(
                              color: t.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: _classId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: t.panel2,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: t.line)),
                        ),
                        items: _c.classes
                            .map((cls) => DropdownMenuItem(
                                value: cls.id, child: Text(cls.displayName)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _classId = v);
                          _loadClass();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()))
              else if (_students.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                      child: Text("No students enrolled in this class.",
                          style: TextStyle(color: t.muted, fontSize: 11))),
                )
              else
                WebTable(
                  columns: const [
                    WebCol("Student", flex: 4),
                    WebCol("Roll", flex: 2),
                    WebCol("Status", flex: 4),
                  ],
                  rows: [
                    for (final e in _students)
                      [
                        Row(children: [
                          Monogram(Formatters.initials(e.studentName)),
                          const SizedBox(width: 9),
                          Flexible(
                              child: Text(e.studentName ?? "Student",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                        ]),
                        Text(e.rollNo ?? "—"),
                        _markGroup(e.studentId),
                      ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _markGroup(String studentId) {
    final current = _marks[studentId] ?? AttendanceStatus.present;
    return Wrap(
      spacing: 5,
      children: [
        _markBtn("Present", AttendanceStatus.present, current, studentId,
            Tone.success),
        _markBtn(
            "Absent", AttendanceStatus.absent, current, studentId, Tone.danger),
        _markBtn(
            "Late", AttendanceStatus.late, current, studentId, Tone.warning),
      ],
    );
  }

  Widget _markBtn(String label, AttendanceStatus s, AttendanceStatus current,
      String studentId, Tone tone) {
    final t = WebTokens.of(context);
    final active = s == current;
    return InkWell(
      onTap: () => setState(() => _marks[studentId] = s),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: active ? tone.bg(t) : t.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Colors.transparent : t.line),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: active ? tone.fg(t) : t.muted)),
      ),
    );
  }

  Widget _summary(
      WebTokens t, IconData icon, String label, String value, Tone tone) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: t.muted, fontSize: 10)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: t.ink, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════ TIMETABLE ══════════════════════════
class WebTimetablePage extends StatefulWidget {
  const WebTimetablePage({super.key});

  @override
  State<WebTimetablePage> createState() => _WebTimetablePageState();
}

class _WebTimetablePageState extends State<WebTimetablePage> {
  final _c = Get.find<WebDashboardController>();
  final _attendance = Get.find<AttendanceRepository>();
  String? _classId;
  late Future<List<TimetableEntry>> _future;

  @override
  void initState() {
    super.initState();
    if (_c.classes.isNotEmpty) _classId = _c.classes.first.id;
    _future = _load();
  }

  Future<List<TimetableEntry>> _load() async {
    if (_classId == null) return [];
    return _attendance.timetable(_classId!);
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return WebPageBody(
      children: [
        WebPageHead(
          title: "Timetable",
          subtitle: "Weekly schedule for classes and institute events.",
          actions: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _classId,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: t.panel,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: BorderSide(color: t.line)),
                ),
                items: _c.classes
                    .map((cls) => DropdownMenuItem(
                        value: cls.id, child: Text(cls.displayName)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _classId = v;
                  _future = _load();
                }),
              ),
            ),
          ],
        ),
        FutureBuilder<List<TimetableEntry>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const WebCard(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()));
            }
            final entries = snap.data ?? [];
            if (entries.isEmpty) {
              return WebCard(
                padding: const EdgeInsets.all(40),
                child: Center(
                    child: Text("No periods scheduled for this class.",
                        style: TextStyle(color: t.muted, fontSize: 12))),
              );
            }
            return _weekGrid(context, entries);
          },
        ),
      ],
    );
  }

  Widget _weekGrid(BuildContext context, List<TimetableEntry> entries) {
    final days = [1, 2, 3, 4, 5];
    final narrow = MediaQuery.of(context).size.width < 1000;
    final dayCards = days.map((d) {
      final items = entries.where((e) => e.dayOfWeek == d).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      return _dayColumn(context, TimetableEntry.dayNames[d - 1], items);
    }).toList();

    if (narrow) {
      return Column(
        children: [
          for (final card in dayCards) ...[card, const SizedBox(height: 12)]
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < dayCards.length; i++) ...[
            Expanded(child: dayCards[i]),
            if (i != dayCards.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _dayColumn(
      BuildContext context, String day, List<TimetableEntry> items) {
    final t = WebTokens.of(context);
    return WebCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(day,
              style: TextStyle(
                  color: t.ink, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text("—", style: TextStyle(color: t.muted, fontSize: 10))
          else
            ...items.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: t.panel2, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.subjectName ?? "Subject",
                          style: TextStyle(
                              color: t.ink,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text("${e.startTime}–${e.endTime}",
                          style: TextStyle(color: t.primary, fontSize: 9)),
                      if (e.room != null)
                        Text(e.room!,
                            style: TextStyle(color: t.muted, fontSize: 8.5)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

// ══════════════════════════ FINANCE ══════════════════════════
class WebFinancePage extends StatelessWidget {
  const WebFinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WebDashboardController>();
    return Obx(() {
      return WebPageBody(
        children: [
          WebPageHead(
            title: "Finance",
            subtitle:
                "One view for fee income, outstanding balances and expenses.",
            actions: [
              WebButton(
                  label: "Add expense",
                  icon: Iconsax.add,
                  onTap: () => showAddExpenseModal(context)),
              const SizedBox(width: 8),
              WebButton(
                  label: "Create fee slip",
                  icon: Iconsax.receipt_1,
                  kind: WebBtnKind.primary,
                  onTap: () => showCreateInvoiceModal(context)),
            ],
          ),
          _topRow(context, c),
          const SizedBox(height: 17),
          _midRow(context, c),
          const SizedBox(height: 17),
          _expensesTable(context, c),
        ],
      );
    });
  }

  Widget _topRow(BuildContext context, WebDashboardController c) {
    final balance = _balanceCard(context, c);
    final collection = _collectionCard(context, c);
    if (MediaQuery.of(context).size.width < 980) {
      return Column(
          children: [balance, const SizedBox(height: 17), collection]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 15, child: balance),
        const SizedBox(width: 17),
        Expanded(flex: 7, child: collection),
      ],
    );
  }

  Widget _balanceCard(BuildContext context, WebDashboardController c) {
    return Container(
      padding: const EdgeInsets.all(21),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: WebTokens.of(context).brandGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available net balance",
              style: TextStyle(color: Colors.white70, fontSize: 10.5)),
          const SizedBox(height: 5),
          Text(Formatters.money(c.net),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 18),
          Row(
            children: [
              _balCell("Fees collected", Formatters.money(c.collected)),
              const SizedBox(width: 10),
              _balCell("Expenses paid", Formatters.money(c.paidExpense)),
              const SizedBox(width: 10),
              _balCell("Pending payouts", Formatters.money(c.pendingExpense)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balCell(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 9)),
              const SizedBox(height: 3),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );

  Widget _collectionCard(BuildContext context, WebDashboardController c) {
    final t = WebTokens.of(context);
    final pct = (c.collectionRate * 100);
    return WebCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Collection Rate",
              subtitle: "Collected vs billed",
              trailing: Text("${pct.toStringAsFixed(0)}%",
                  style: TextStyle(
                      color: t.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w800))),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 9,
              color: t.panel2,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: c.collectionRate.clamp(0, 1).toDouble(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [t.primary, t.success]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Collected ${Formatters.money(c.collected)}",
                  style: TextStyle(color: t.muted, fontSize: 10)),
              Text("Billed ${Formatters.money(c.billed)}",
                  style: TextStyle(color: t.muted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _mini(t, "Outstanding", Formatters.money(c.outstanding),
                    t.warning),
              ),
              const SizedBox(width: 10),
              Expanded(
                child:
                    _mini(t, "Pending slips", "${c.pendingInvoices}", t.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(WebTokens t, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: t.panel2,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(13)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: t.muted, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _midRow(BuildContext context, WebDashboardController c) {
    final slips = WebCard(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
            child: SectionHead(
                title: "Fee Slips", subtitle: "Invoices, status & payments"),
          ),
          const SizedBox(height: 12),
          if (c.invoices.isEmpty)
            Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text("No invoices yet.",
                        style: TextStyle(
                            color: WebTokens.of(context).muted, fontSize: 11))))
          else
            WebTable(
              columns: const [
                WebCol("Student", flex: 3),
                WebCol("Amount", flex: 2, right: true),
                WebCol("Paid", flex: 2, right: true),
                WebCol("Status", flex: 2, right: true),
                WebCol("", flex: 3, right: true),
              ],
              rows: [
                for (final i in c.invoices)
                  [
                    Text(i.studentName ?? i.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(Formatters.money(i.amount)),
                    Text(Formatters.money(i.amountPaid)),
                    Align(
                        alignment: Alignment.centerRight,
                        child: StatusChip(i.status.label,
                            tone: _invoiceTone(i.status))),
                    Align(
                      alignment: Alignment.centerRight,
                      child: i.balance > 0
                          ? WebButton(
                              label: _canPayFees(context)
                                  ? "Pay now"
                                  : "Record payment",
                              icon: Iconsax.card,
                              kind: WebBtnKind.primary,
                              onTap: () => showRecordPaymentModal(context, i))
                          : Text("Paid in full",
                              style: TextStyle(
                                  color: WebTokens.of(context).muted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ],
              ],
            ),
        ],
      ),
    );

    final breakdown = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(title: "Expense Breakdown", subtitle: "By category"),
          const SizedBox(height: 14),
          ..._breakdownBars(context, c),
        ],
      ),
    );

    if (MediaQuery.of(context).size.width < 980) {
      return Column(children: [slips, const SizedBox(height: 17), breakdown]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 162, child: slips),
        const SizedBox(width: 17),
        Expanded(flex: 78, child: breakdown),
      ],
    );
  }

  List<Widget> _breakdownBars(BuildContext context, WebDashboardController c) {
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
      for (int i = 0; i < entries.length && i < 5; i++) ...[
        HBar(
          label: entries[i].key,
          value: Formatters.money(entries[i].value),
          fraction: max == 0 ? 0 : entries[i].value / max,
          tone: tones[i % tones.length],
        ),
        if (i != entries.length - 1 && i < 4) const SizedBox(height: 14),
      ],
    ];
  }

  Widget _expensesTable(BuildContext context, WebDashboardController c) {
    final t = WebTokens.of(context);
    return WebCard(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
            child: SectionHead(
              title: "Institute Expenses",
              subtitle: "Paid and pending payouts",
              trailing: WebButton(
                  label: "Add expense",
                  icon: Iconsax.add,
                  onTap: () => showAddExpenseModal(context)),
            ),
          ),
          const SizedBox(height: 12),
          if (c.expenses.isEmpty)
            Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text("No expenses yet.",
                        style: TextStyle(color: t.muted, fontSize: 11))))
          else
            WebTable(
              columns: const [
                WebCol("Category", flex: 2),
                WebCol("Payee", flex: 2),
                WebCol("Date", flex: 2),
                WebCol("Amount", flex: 2, right: true),
                WebCol("Status", flex: 2, right: true),
                WebCol("", flex: 2, right: true),
              ],
              rows: [
                for (final e in c.expenses)
                  [
                    Text(e.category.label),
                    Text(e.payee ?? "—",
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(Formatters.date(e.paidOn)),
                    Text(Formatters.money(e.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Align(
                        alignment: Alignment.centerRight,
                        child: StatusChip(e.status.label,
                            tone: e.isPaid ? Tone.success : Tone.warning)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TableAction(Iconsax.edit_2,
                            onTap: () =>
                                showAddExpenseModal(context, existing: e)),
                        const SizedBox(width: 5),
                        TableAction(Iconsax.trash,
                            onTap: () => _confirmDelete(context, c, e)),
                      ],
                    ),
                  ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WebDashboardController c, Expense e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete expense?"),
        content: Text(e.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")),
        ],
      ),
    );
    if (ok == true) {
      try {
        await c.deleteExpense(e.id);
        SnackbarUtils.showSuccess("Expense deleted");
      } catch (err) {
        SnackbarUtils.showError(err.toString());
      }
    }
  }

  Tone _invoiceTone(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.paid:
        return Tone.success;
      case InvoiceStatus.partial:
        return Tone.info;
      case InvoiceStatus.overdue:
        return Tone.danger;
      case InvoiceStatus.cancelled:
        return Tone.primary;
      case InvoiceStatus.pending:
        return Tone.warning;
    }
  }

  bool _canPayFees(BuildContext context) {
    final role = Get.find<SessionController>().role;
    return role.isParent || role.isStudent;
  }
}
