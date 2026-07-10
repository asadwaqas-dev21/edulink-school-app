import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/domain/entities/parent_link.dart";
import "package:edulink/domain/entities/subject.dart";
import "package:edulink/domain/entities/submission.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_modals.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

// ══════════════════════════ CHILDREN ══════════════════════════
class WebChildrenPage extends StatelessWidget {
  const WebChildrenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WebDashboardController>();
    return Obx(() {
      final children = c.children.toList();
      return WebPageBody(
        children: [
          const WebPageHead(
            title: "My Children",
            subtitle:
                "Track each child's subjects, performance and attendance.",
          ),
          if (children.isEmpty)
            WebCard(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Center(
                child: Column(
                  children: [
                    Icon(Iconsax.people,
                        size: 34, color: WebTokens.of(context).muted),
                    const SizedBox(height: 10),
                    Text("No children linked",
                        style: TextStyle(
                            color: WebTokens.of(context).ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        "Ask your institute to link your account to your child.",
                        style: TextStyle(
                            color: WebTokens.of(context).muted, fontSize: 11)),
                  ],
                ),
              ),
            )
          else
            for (final child in children) ...[
              _ChildCard(child: child),
              const SizedBox(height: 17),
            ],
        ],
      );
    });
  }
}

class _ChildCard extends StatefulWidget {
  final ParentLink child;
  const _ChildCard({required this.child});

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> {
  final _academics = Get.find<AcademicsRepository>();
  final _assess = Get.find<AssessmentRepository>();
  final _report = Get.find<ReportRepository>();

  late Future<_ChildData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ChildData> _load() async {
    final id = widget.child.studentId;
    final subjects = await _academics.subjectsForStudent(id);
    final subs = await _assess.studentSubmissions(id);
    final attendance = await _report.attendanceRate(id);
    return _ChildData(subjects: subjects, submissions: subs, attendance: attendance);
  }

  double? _avgForSubject(List<Submission> subs, String subjectId) {
    final graded =
        subs.where((s) => s.subjectId == subjectId && s.grade != null).toList();
    if (graded.isEmpty) return null;
    double sum = 0;
    for (final s in graded) {
      final max = (s.maxPoints ?? 100);
      sum += max == 0 ? 0 : (s.grade! / max * 100);
    }
    return sum / graded.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return WebCard(
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
            child: FutureBuilder<_ChildData>(
              future: _future,
              builder: (context, snap) {
                final att = snap.data?.attendance;
                return Row(
                  children: [
                    Monogram(Formatters.initials(widget.child.studentName),
                        tone: Tone.primary, size: 42, radius: 13),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.child.studentName ?? "Student",
                              style: TextStyle(
                                  color: t.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(widget.child.relation ?? "Student",
                              style: TextStyle(color: t.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (att != null)
                      StatusChip("Attendance ${att.toStringAsFixed(0)}%",
                          tone: att >= 75
                              ? Tone.success
                              : (att >= 50 ? Tone.warning : Tone.danger)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<_ChildData>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snap.data;
              final subjects = data?.subjects ?? [];
              if (subjects.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                  child: Text("Not enrolled in any subjects yet.",
                      style: TextStyle(color: t.muted, fontSize: 11)),
                );
              }
              return WebTable(
                columns: const [
                  WebCol("Subject", flex: 3),
                  WebCol("Teacher", flex: 3),
                  WebCol("Performance", flex: 3, right: true),
                ],
                rows: [
                  for (final s in subjects)
                    _subjectRow(t, s, _avgForSubject(data!.submissions, s.id)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _subjectRow(WebTokens t, Subject s, double? avg) {
    return [
      Text(s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(s.teacherName ?? "Unassigned",
          maxLines: 1, overflow: TextOverflow.ellipsis),
      Align(
        alignment: Alignment.centerRight,
        child: avg == null
            ? Text("No grades yet",
                style: TextStyle(color: t.muted, fontSize: 10.5))
            : StatusChip("${avg.toStringAsFixed(0)}%",
                tone: avg >= 75
                    ? Tone.success
                    : (avg >= 40 ? Tone.warning : Tone.danger)),
      ),
    ];
  }
}

class _ChildData {
  final List<Subject> subjects;
  final List<Submission> submissions;
  final double attendance;
  _ChildData(
      {required this.subjects,
      required this.submissions,
      required this.attendance});
}

// ══════════════════════════ FEES (parent) ══════════════════════════
class WebParentFeesPage extends StatelessWidget {
  const WebParentFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final c = Get.find<WebDashboardController>();
    return Obx(() {
      final invoices = c.childrenInvoices.toList();
      return WebPageBody(
        children: [
          const WebPageHead(
            title: "Fees",
            subtitle: "Your children's fee slips and payments.",
          ),
          WebGrid(
            columns: MediaQuery.of(context).size.width < 1180 ? 1 : 3,
            childAspectRatio: 3.1,
            children: [
              _summary(context, Iconsax.wallet_3, "Total due",
                  Formatters.money(c.childrenFeesDue), Tone.warning),
              _summary(context, Iconsax.tick_circle, "Total paid",
                  Formatters.money(c.childrenFeesPaid), Tone.success),
              _summary(context, Iconsax.receipt_1, "Unpaid slips",
                  "${c.childrenUnpaidSlips}", Tone.danger),
            ],
          ),
          const SizedBox(height: 17),
          WebCard(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(17, 17, 17, 0),
                  child: SectionHead(
                      title: "Fee Slips", subtitle: "Tap Pay to settle a slip"),
                ),
                const SizedBox(height: 12),
                if (invoices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                        child: Text("No fee slips yet.",
                            style: TextStyle(color: t.muted, fontSize: 11))),
                  )
                else
                  WebTable(
                    columns: const [
                      WebCol("Student", flex: 3),
                      WebCol("Slip", flex: 3),
                      WebCol("Amount", flex: 2, right: true),
                      WebCol("Balance", flex: 2, right: true),
                      WebCol("Status", flex: 2, right: true),
                      WebCol("", flex: 2, right: true),
                    ],
                    rows: [
                      for (final i in invoices)
                        [
                          Text(i.studentName ?? "—",
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(i.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(Formatters.money(i.amount)),
                          Text(Formatters.money(i.balance)),
                          Align(
                              alignment: Alignment.centerRight,
                              child: StatusChip(i.status.label,
                                  tone: _invoiceTone(i.status))),
                          Align(
                            alignment: Alignment.centerRight,
                            child: i.balance > 0
                                ? WebButton(
                                    label: "Pay now",
                                    icon: Iconsax.card,
                                    kind: WebBtnKind.primary,
                                    onTap: () =>
                                        showRecordPaymentModal(context, i))
                                : Text("Paid",
                                    style: TextStyle(
                                        color: t.muted,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    });
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
}
