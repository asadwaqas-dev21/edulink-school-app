import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/domain/entities/subject.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_modals.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

Tone roleTone(UserRole r) {
  if (r.isTeacher) return Tone.success;
  if (r.isParent) return Tone.warning;
  if (r.isPrincipal) return Tone.info;
  return Tone.primary;
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return "Good morning";
  if (h < 17) return "Good afternoon";
  return "Good evening";
}

// ══════════════════════════ DASHBOARD ══════════════════════════
class WebDashboardPage extends StatelessWidget {
  final void Function(String pageId) onNavigate;
  const WebDashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final c = Get.find<WebDashboardController>();
    final session = Get.find<SessionController>();
    final name = session.profile?.fullName.split(" ").first ?? "there";

    return Obx(() {
      if (session.role.isParent) {
        return _parentDashboard(context, c, name);
      }
      final cols = _cols(context);
      return WebPageBody(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${_greeting()}, $name 👋",
                        style: TextStyle(
                            color: t.ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8)),
                    const SizedBox(height: 6),
                    Text(
                        "Here is what is happening at ${c.institute.value?.name ?? "your institute"} today.",
                        style: TextStyle(color: t.muted, fontSize: 13)),
                  ],
                ),
              ),
              _dateChip(t),
            ],
          ),
          const SizedBox(height: 22),
          WebGrid(
            columns: cols,
            childAspectRatio: cols == 4 ? 1.7 : 2.3,
            children: [
              Kpi(
                  label: "Total Students",
                  value: "${c.overview["students"] ?? 0}",
                  icon: Iconsax.people,
                  foot: "Enrolled learners"),
              Kpi(
                  label: "Teachers",
                  value: "${c.overview["teachers"] ?? 0}",
                  icon: Iconsax.teacher,
                  tone: Tone.success,
                  foot: "Active faculty"),
              session.role.isPrincipal
                  ? Kpi(
                      label: "Fees Collected",
                      value: Formatters.money(c.collected),
                      icon: Iconsax.wallet_3,
                      tone: Tone.warning,
                      foot:
                          "${(c.collectionRate * 100).toStringAsFixed(0)}% of billed")
                  : Kpi(
                      label: "Announcements",
                      value: "${c.announcements.length}",
                      icon: Iconsax.notification,
                      tone: Tone.warning,
                      foot: "Institute updates"),
              Kpi(
                  label: "Active Classes",
                  value: "${c.overview["classes"] ?? 0}",
                  icon: Iconsax.book_1,
                  tone: Tone.info,
                  foot: "This session"),
            ],
          ),
          if (session.role.isPrincipal) ...[
            const SizedBox(height: 17),
            _twoCol(
              context,
              left: _financeOverview(context, c),
              right: _collectionDonut(context, c),
              leftFlex: 162,
              rightFlex: 78,
            ),
          ],
          const SizedBox(height: 17),
          _bottomRow(context, c),
        ],
      );
    });
  }

  int _cols(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 1180) return 2;
    return 4;
  }

  Widget _dateChip(WebTokens t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
            color: t.panel,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Iconsax.calendar_1, size: 15, color: t.muted),
          const SizedBox(width: 9),
          Text(Formatters.date(DateTime.now()),
              style: TextStyle(
                  color: t.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _twoCol(BuildContext context,
      {required Widget left,
      required Widget right,
      required int leftFlex,
      required int rightFlex}) {
    if (MediaQuery.of(context).size.width < 980) {
      return Column(children: [left, const SizedBox(height: 17), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 17),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }

  Widget _financeOverview(BuildContext context, WebDashboardController c) {
    final t = WebTokens.of(context);
    return WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Financial Overview",
              subtitle: "Fee collection and institute expenses"),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Net cash position",
                        style: TextStyle(color: t.muted, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(Formatters.money(c.net),
                        style: TextStyle(
                            color: t.ink,
                            fontSize: 21,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              _legendDot(t, t.primary, "Income"),
              const SizedBox(width: 14),
              _legendDot(t, const Color(0xFFFFAC69), "Expenses"),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(painter: _SparklinePainter(t)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _miniStat(t, "Total fees collected",
                      Formatters.money(c.collected))),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniStat(
                      t, "Expenses paid", Formatters.money(c.paidExpense))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(WebTokens t, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: t.muted, fontSize: 10)),
        ],
      );

  Widget _miniStat(WebTokens t, String label, String value) => Container(
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
                    color: t.ink, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _collectionDonut(BuildContext context, WebDashboardController c) {
    final t = WebTokens.of(context);
    final pct = (c.collectionRate * 100);
    return WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Fee Collection", subtitle: "Collected vs billed"),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _DonutPainter(
                    t, (c.collectionRate).clamp(0, 1).toDouble()),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${pct.toStringAsFixed(0)}%",
                          style: TextStyle(
                              color: t.ink,
                              fontSize: 23,
                              fontWeight: FontWeight.w800)),
                      Text("Collected",
                          style: TextStyle(color: t.muted, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _miniStat(
                      t, "Collected", Formatters.money(c.collected))),
              const SizedBox(width: 10),
              Expanded(
                  child: _miniStat(
                      t, "Outstanding", Formatters.money(c.outstanding))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _parentDashboard(
      BuildContext context, WebDashboardController c, String name) {
    final t = WebTokens.of(context);
    final cols = MediaQuery.of(context).size.width < 1180 ? 2 : 4;
    return WebPageBody(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${_greeting()}, $name 👋",
                      style: TextStyle(
                          color: t.ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8)),
                  const SizedBox(height: 6),
                  Text(
                      "Here is how your ${c.childrenCount == 1 ? "child" : "children"} ${c.childrenCount == 1 ? "is" : "are"} doing at ${c.institute.value?.name ?? "school"}.",
                      style: TextStyle(color: t.muted, fontSize: 13)),
                ],
              ),
            ),
            _dateChip(t),
          ],
        ),
        const SizedBox(height: 22),
        WebGrid(
          columns: cols,
          childAspectRatio: cols == 4 ? 1.7 : 2.3,
          children: [
            Kpi(
                label: "Children",
                value: "${c.childrenCount}",
                icon: Iconsax.people,
                foot: "Linked to you"),
            Kpi(
                label: "Fees Due",
                value: Formatters.money(c.childrenFeesDue),
                icon: Iconsax.wallet_3,
                tone: Tone.warning,
                foot: "${c.childrenUnpaidSlips} unpaid slip(s)"),
            Kpi(
                label: "Fees Paid",
                value: Formatters.money(c.childrenFeesPaid),
                icon: Iconsax.tick_circle,
                tone: Tone.success,
                foot: "Total settled"),
            Kpi(
                label: "Announcements",
                value: "${c.announcements.length}",
                icon: Iconsax.notification,
                tone: Tone.info,
                foot: "Institute updates"),
          ],
        ),
        const SizedBox(height: 17),
        _parentBottomRow(context, c),
      ],
    );
  }

  Widget _parentBottomRow(BuildContext context, WebDashboardController c) {
    final quickItems = [
      _quick(context, Iconsax.people, "My Children",
          "Subjects & performance", () => onNavigate("children")),
      _quick(context, Iconsax.receipt_1, "Fees",
          "View & pay fee slips", () => onNavigate("fees")),
      _quick(context, Iconsax.calendar_1, "Timetable",
          "Weekly schedule", () => onNavigate("timetable")),
      _quick(context, Iconsax.messages_1, "Messages",
          "Announcements & chat", () => onNavigate("communication")),
    ];

    final quick = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(title: "Quick Actions", subtitle: "Shortcuts for you"),
          const SizedBox(height: 14),
          WebGrid(
              columns: 2, gap: 10, childAspectRatio: 1.9, children: quickItems),
        ],
      ),
    );

    final announcements = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Announcements",
              subtitle: "Latest broadcasts",
              trailing: MoreButton("View all",
                  onTap: () => onNavigate("communication"))),
          const SizedBox(height: 10),
          if (c.announcements.isEmpty)
            _emptyMini(context, "No announcements yet")
          else
            ...c.announcements.take(4).map((a) => _activityRow(
                context,
                Iconsax.notification,
                a.title,
                a.authorName ?? "Announcement",
                Formatters.date(a.createdAt))),
        ],
      ),
    );

    final fees = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Recent Fee Slips",
              subtitle: "Your children's invoices",
              trailing: MoreButton("View all", onTap: () => onNavigate("fees"))),
          const SizedBox(height: 10),
          if (c.childrenInvoices.isEmpty)
            _emptyMini(context, "No fee slips yet")
          else
            ...c.childrenInvoices.take(4).map((i) => _activityRow(
                context,
                Iconsax.money_recive,
                i.title,
                "${i.studentName ?? "Student"} · ${Formatters.money(i.balance)} due",
                i.status.label)),
        ],
      ),
    );

    final w = MediaQuery.of(context).size.width;
    if (w < 1180) {
      return Column(children: [
        quick,
        const SizedBox(height: 17),
        announcements,
        const SizedBox(height: 17),
        fees,
      ]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: quick),
        const SizedBox(width: 17),
        Expanded(child: announcements),
        const SizedBox(width: 17),
        Expanded(child: fees),
      ],
    );
  }

  Widget _bottomRow(BuildContext context, WebDashboardController c) {
    final role = Get.find<SessionController>().role;
    final List<Widget> quickItems = role.isPrincipal
        ? [
            _quick(context, Iconsax.user_add, "Add member",
                "Link a teacher, student or parent",
                () => showAddMemberModal(context)),
            _quick(context, Iconsax.receipt_1, "Create fee slip",
                "Issue a multi-item invoice",
                () => showCreateInvoiceModal(context)),
            _quick(context, Iconsax.wallet_3, "Add expense",
                "Log a salary, rent or utility",
                () => showAddExpenseModal(context)),
            _quick(context, Iconsax.send_2, "New announcement",
                "Broadcast to your institute",
                () => showAnnouncementModal(context)),
          ]
        : [
            if (role.canTeach || role.isStudent)
              _quick(context, Iconsax.teacher, "Academics",
                  "View classes & subjects", () => onNavigate("academics")),
            if (role.canMarkAttendance)
              _quick(context, Iconsax.task_square, "Attendance",
                  "Mark today's attendance", () => onNavigate("attendance")),
            _quick(context, Iconsax.calendar_1, "Timetable",
                "See the weekly schedule", () => onNavigate("timetable")),
            _quick(context, Iconsax.messages_1, "Messages",
                "Open announcements & chat", () => onNavigate("communication")),
          ];

    final quick = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Quick Actions",
              subtitle: role.isPrincipal
                  ? "Common administrative tasks"
                  : "Shortcuts for you"),
          const SizedBox(height: 14),
          WebGrid(columns: 2, gap: 10, childAspectRatio: 1.9, children: quickItems),
        ],
      ),
    );

    final announcements = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Announcements",
              subtitle: "Latest broadcasts",
              trailing:
                  MoreButton("View all", onTap: () => onNavigate("communication"))),
          const SizedBox(height: 10),
          if (c.announcements.isEmpty)
            _emptyMini(context, "No announcements yet")
          else
            ...c.announcements.take(4).map((a) => _activityRow(
                context, Iconsax.notification, a.title,
                a.authorName ?? "Announcement", Formatters.date(a.createdAt))),
        ],
      ),
    );

    final activity = WebCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(
              title: "Recent Fee Activity", subtitle: "Latest invoices"),
          const SizedBox(height: 10),
          if (c.invoices.isEmpty)
            _emptyMini(context, "No invoices yet")
          else
            ...c.invoices.take(4).map((i) => _activityRow(
                context,
                Iconsax.money_recive,
                i.title,
                "${i.studentName ?? "Student"} · ${Formatters.money(i.amount)}",
                i.status.label)),
        ],
      ),
    );

    final w = MediaQuery.of(context).size.width;
    if (w < 1180) {
      return Column(children: [
        quick,
        const SizedBox(height: 17),
        announcements,
        const SizedBox(height: 17),
        activity,
      ]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: quick),
        const SizedBox(width: 17),
        Expanded(child: announcements),
        const SizedBox(width: 17),
        Expanded(child: activity),
      ],
    );
  }

  Widget _quick(BuildContext context, IconData icon, String title,
      String sub, VoidCallback onTap) {
    final t = WebTokens.of(context);
    return WebCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: t.primarySoft, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: t.primary),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  color: t.ink, fontSize: 11.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.muted, fontSize: 9.5, height: 1.4)),
        ],
      ),
    );
  }

  Widget _activityRow(BuildContext context, IconData icon, String title,
      String sub, String trailing) {
    final t = WebTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: t.successSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 15, color: t.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.muted, fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(trailing, style: TextStyle(color: t.muted, fontSize: 8.5)),
        ],
      ),
    );
  }

  Widget _emptyMini(BuildContext context, String text) {
    final t = WebTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
          child: Text(text, style: TextStyle(color: t.muted, fontSize: 11))),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final WebTokens t;
  _SparklinePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = t.line
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final incomePts = _points(size, [0.30, 0.42, 0.38, 0.55, 0.62, 0.58, 0.74, 0.82]);
    final expensePts = _points(size, [0.18, 0.24, 0.22, 0.32, 0.30, 0.40, 0.44, 0.50]);

    final area = Path()..moveTo(incomePts.first.dx, size.height);
    for (final p in incomePts) {
      area.lineTo(p.dx, p.dy);
    }
    area.lineTo(incomePts.last.dx, size.height);
    area.close();
    canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.primary.withValues(alpha: 0.25),
              t.primary.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size));

    _drawLine(canvas, incomePts, t.primary, 3);
    _drawLine(canvas, expensePts, const Color(0xFFFFAC69), 2.5);
  }

  List<Offset> _points(Size size, List<double> vals) {
    final dx = size.width / (vals.length - 1);
    return [
      for (int i = 0; i < vals.length; i++)
        Offset(dx * i, size.height * (1 - vals[i]))
    ];
  }

  void _drawLine(Canvas canvas, List<Offset> pts, Color color, double w) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final midX = (prev.dx + cur.dx) / 2;
      path.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.t.dark != t.dark;
}

class _DonutPainter extends CustomPainter {
  final WebTokens t;
  final double fraction;
  _DonutPainter(this.t, this.fraction);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final stroke = 20.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    canvas.drawArc(
        rect,
        0,
        6.2832,
        false,
        Paint()
          ..color = t.panel2
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    canvas.drawArc(
        rect,
        -1.5708,
        6.2832 * fraction,
        false,
        Paint()
          ..color = t.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fraction != fraction || old.t.dark != t.dark;
}

// ══════════════════════════ PEOPLE ══════════════════════════
class WebPeoplePage extends StatelessWidget {
  const WebPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<WebDashboardController>();
    return Obx(() {
      final people = c.allPeople;
      return WebPageBody(
        children: [
          WebPageHead(
            title: "People",
            subtitle:
                "Manage students, teachers, parents and their institute access.",
            actions: [
              WebButton(
                  label: "Add member",
                  icon: Iconsax.add,
                  kind: WebBtnKind.primary,
                  onTap: () => showAddMemberModal(context)),
            ],
          ),
          WebGrid(
            columns: _summaryCols(context),
            childAspectRatio: 3.1,
            children: [
              _summary(context, Iconsax.people, "Students",
                  "${c.students.length}", Tone.primary),
              _summary(context, Iconsax.teacher, "Teachers",
                  "${c.teachers.length}", Tone.success),
              _summary(context, Iconsax.profile_2user, "Parents",
                  "${c.parents.length}", Tone.warning),
              _summary(context, Iconsax.book_1, "Classes",
                  "${c.classes.length}", Tone.info),
            ],
          ),
          const SizedBox(height: 17),
          WebCard(
            clipBehavior: Clip.hardEdge,
            child: people.isEmpty
                ? _empty(context, "No members yet",
                    "Add teachers, students and parents to your institute.")
                : WebTable(
                    columns: const [
                      WebCol("Member", flex: 3),
                      WebCol("Role", flex: 2),
                      WebCol("Contact", flex: 3),
                      WebCol("Status", flex: 2),
                      WebCol("", flex: 2, right: true),
                    ],
                    rows: [
                      for (final p in people)
                        [
                          _person(context, p),
                          Text(p.role.label),
                          Text(p.email,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const StatusChip("Active", tone: Tone.success),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TableAction(Iconsax.edit_2,
                                  onTap: () => _editPerson(context, c, p)),
                              if (!p.role.isPrincipal) ...[
                                const SizedBox(width: 5),
                                TableAction(Iconsax.trash,
                                    onTap: () => _confirmRemove(context, c, p)),
                              ],
                            ],
                          ),
                        ],
                    ],
                  ),
          ),
        ],
      );
    });
  }

  int _summaryCols(BuildContext context) =>
      MediaQuery.of(context).size.width < 1180 ? 2 : 4;

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

  Widget _person(BuildContext context, Profile p) {
    final t = WebTokens.of(context);
    return Row(
      children: [
        Monogram(Formatters.initials(p.fullName), tone: roleTone(p.role)),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: t.ink, fontSize: 11, fontWeight: FontWeight.w700)),
              Text(p.role.label,
                  style: TextStyle(color: t.muted, fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, String title, String sub) {
    final t = WebTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Column(
          children: [
            Icon(Iconsax.people, size: 34, color: t.muted),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    color: t.ink, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: t.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _editPerson(
      BuildContext context, WebDashboardController c, Profile p) async {
    await showEditPersonModal(context, p);
  }

  Future<void> _confirmRemove(
      BuildContext context, WebDashboardController c, Profile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove member?"),
        content: Text(
            "${p.fullName} will be removed from your institute (their login account is kept). Enrollments and parent links will be cleared."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Remove")),
        ],
      ),
    );
    if (ok == true) {
      try {
        await c.removePerson(p.id);
        SnackbarUtils.showSuccess("${p.fullName} removed");
      } catch (err) {
        SnackbarUtils.showError(err.toString());
      }
    }
  }
}

// ══════════════════════════ ACADEMICS ══════════════════════════
class WebAcademicsPage extends StatefulWidget {
  const WebAcademicsPage({super.key});

  @override
  State<WebAcademicsPage> createState() => _WebAcademicsPageState();
}

class _WebAcademicsPageState extends State<WebAcademicsPage> {
  final _c = Get.find<WebDashboardController>();
  final _academics = Get.find<AcademicsRepository>();
  late Future<List<Subject>> _subjects;

  @override
  void initState() {
    super.initState();
    _subjects = _loadSubjects();
  }

  Future<List<Subject>> _loadSubjects() async {
    final all = <Subject>[];
    for (final cls in _c.classes) {
      all.addAll(await _academics.subjects(cls.id));
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final classes = _c.classes.toList();
      return WebPageBody(
        children: [
          WebPageHead(
            title: "Academics",
            subtitle:
                "Manage classes, sections, subjects and teacher assignments.",
            actions: [
              WebButton(
                  label: "Create class",
                  icon: Iconsax.add,
                  kind: WebBtnKind.primary,
                  onTap: _createClass),
            ],
          ),
          if (classes.isEmpty)
            WebCard(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Center(
                  child: Text("No classes yet — create your first class.",
                      style: TextStyle(
                          color: WebTokens.of(context).muted, fontSize: 12))),
            )
          else
            WebGrid(
              columns: _cardCols(context),
              childAspectRatio: 1.7,
              children: [for (final cls in classes) _classCard(context, cls)],
            ),
          const SizedBox(height: 17),
          WebCard(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 17, 17, 0),
                  child: SectionHead(
                      title: "Subjects & Teacher Assignments",
                      subtitle: "Current academic session"),
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<Subject>>(
                  future: _subjects,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final subjects = snap.data ?? [];
                    if (subjects.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(28),
                        child: Center(
                            child: Text("No subjects added yet.",
                                style: TextStyle(
                                    color: WebTokens.of(context).muted,
                                    fontSize: 11))),
                      );
                    }
                    return WebTable(
                      columns: const [
                        WebCol("Subject", flex: 3),
                        WebCol("Code", flex: 2),
                        WebCol("Teacher", flex: 3),
                      ],
                      rows: [
                        for (final s in subjects)
                          [
                            Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(s.code ?? "—"),
                            Text(s.teacherName ?? "Unassigned"),
                          ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  int _cardCols(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 900) return 1;
    if (w < 1180) return 2;
    return 3;
  }

  Widget _classCard(BuildContext context, SchoolClass cls) {
    final t = WebTokens.of(context);
    return WebCard(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
              left: 0, top: 0, bottom: 0, width: 4,
              child: Container(color: t.primary)),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cls.displayName,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(cls.gradeLevel ?? "Class",
                    style: TextStyle(color: t.muted, fontSize: 9.5)),
                const SizedBox(height: 16),
                Text("Section ${cls.section ?? "—"}",
                    style: TextStyle(color: t.muted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createClass() async {
    final t = WebTokens.of(context);
    final nameCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final gradeCtrl = TextEditingController();
    await showWebModal(
      context: context,
      title: "Create class",
      saveLabel: "Create",
      body: (ctx, setState) => Column(
        children: [
          WebField(
              label: "Class name",
              child: TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: t.panel2,
                      hintText: "e.g. Grade 10",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: t.line))))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: WebField(
                    label: "Section",
                    child: TextField(
                        controller: sectionCtrl,
                        decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: t.panel2,
                            hintText: "A",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: t.line))))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebField(
                    label: "Grade level",
                    child: TextField(
                        controller: gradeCtrl,
                        decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: t.panel2,
                            hintText: "Science",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: t.line))))),
              ),
            ],
          ),
        ],
      ),
      onSave: () async {
        if (nameCtrl.text.trim().isEmpty) {
          SnackbarUtils.showWarning("Enter a class name");
          return false;
        }
        try {
          await _academics.createClass(SchoolClass(
            id: "",
            instituteId: _c.instituteId,
            name: nameCtrl.text.trim(),
            section: sectionCtrl.text.trim().isEmpty
                ? null
                : sectionCtrl.text.trim(),
            gradeLevel:
                gradeCtrl.text.trim().isEmpty ? null : gradeCtrl.text.trim(),
          ));
          await _c.load();
          SnackbarUtils.showSuccess("Class created");
          return true;
        } catch (e) {
          SnackbarUtils.showError(e.toString());
          return false;
        }
      },
    );
  }
}
