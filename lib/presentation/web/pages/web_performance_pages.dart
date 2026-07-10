import "dart:math" as math;

import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/core/services/performance_report_service.dart";
import "package:edulink/core/services/student_report_pdf_service.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

/// Lists every student so a principal/teacher can open a downloadable
/// performance report for any of them.
class WebPerformancePage extends StatefulWidget {
  const WebPerformancePage({super.key});

  @override
  State<WebPerformancePage> createState() => _WebPerformancePageState();
}

class _WebPerformancePageState extends State<WebPerformancePage> {
  final _c = Get.find<WebDashboardController>();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return WebPageBody(
      children: [
        const WebPageHead(
          title: "Performance",
          subtitle:
              "Track every student's marks, percentage and growth across tests — open a student to view charts and download the report.",
        ),
        WebCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHead(
                title: "Students",
                subtitle: "Select a student to view their performance sheet.",
                trailing: SizedBox(
                  width: 260,
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    style: TextStyle(color: t.ink, fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Search students…",
                      hintStyle: TextStyle(color: t.muted, fontSize: 12.5),
                      prefixIcon:
                          Icon(Iconsax.search_normal_1, size: 16, color: t.muted),
                      filled: true,
                      fillColor: t.panel2,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: t.line),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final all = _c.students.toList()
                  ..sort((a, b) => a.fullName
                      .toLowerCase()
                      .compareTo(b.fullName.toLowerCase()));
                final list = _query.isEmpty
                    ? all
                    : all
                        .where((s) =>
                            s.fullName
                                .toLowerCase()
                                .contains(_query.toLowerCase()) ||
                            s.email
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                        .toList();
                if (list.isEmpty) {
                  return _empty(t,
                      _c.students.isEmpty ? "No students yet." : "No matches.");
                }
                return WebGrid(
                  columns: 3,
                  children: [for (final s in list) _studentCard(t, s)],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _studentCard(WebTokens t, Profile s) {
    return WebCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Get.to(() => WebStudentReportScreen(student: s)),
      child: Row(
        children: [
          Monogram(Formatters.initials(s.fullName)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(s.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.muted, fontSize: 10.5)),
              ],
            ),
          ),
          Icon(Iconsax.arrow_right_3, size: 16, color: t.muted),
        ],
      ),
    );
  }

  Widget _empty(WebTokens t, String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Iconsax.chart_success, size: 34, color: t.muted),
              const SizedBox(height: 10),
              Text(msg, style: TextStyle(color: t.muted, fontSize: 12.5)),
            ],
          ),
        ),
      );
}

/// Full performance sheet for a single student: KPIs, trend chart, per-subject
/// averages and a table of all tests — with a PDF download.
class WebStudentReportScreen extends StatefulWidget {
  final Profile student;
  const WebStudentReportScreen({super.key, required this.student});

  @override
  State<WebStudentReportScreen> createState() => _WebStudentReportScreenState();
}

class _WebStudentReportScreenState extends State<WebStudentReportScreen> {
  final _assessment = Get.find<AssessmentRepository>();
  final _c = Get.find<WebDashboardController>();
  late Future<StudentPerformance> _future;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = PerformanceReportService.build(widget.student, _assessment);
  }

  Future<void> _download(StudentPerformance perf) async {
    setState(() => _downloading = true);
    try {
      await StudentReportPdfService.printReport(perf,
          institute: _c.institute.value);
    } catch (e) {
      SnackbarUtils.showError("Could not generate report: $e");
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: FutureBuilder<StudentPerformance>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return _errorState(t);
            }
            return _content(t, snap.data!);
          },
        ),
      ),
    );
  }

  Widget _content(WebTokens t, StudentPerformance perf) {
    return WebPageBody(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _backButton(t),
              const SizedBox(width: 12),
              Monogram(Formatters.initials(widget.student.fullName), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.student.fullName,
                        style: TextStyle(
                            color: t.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(widget.student.email,
                        style: TextStyle(color: t.muted, fontSize: 11.5)),
                  ],
                ),
              ),
              WebButton(
                label: _downloading ? "Preparing…" : "Download PDF",
                icon: Iconsax.document_download,
                kind: WebBtnKind.primary,
                onTap: (_downloading || !perf.hasData)
                    ? null
                    : () => _download(perf),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!perf.hasData)
          _noData(t)
        else ...[
          _kpis(t, perf),
          const SizedBox(height: 18),
          _trendCard(t, perf),
          const SizedBox(height: 18),
          _subjectsCard(t, perf),
          const SizedBox(height: 18),
          _testsCard(t, perf),
        ],
      ],
    );
  }

  Widget _kpis(WebTokens t, StudentPerformance perf) {
    final growth = perf.growthRate;
    final growthText =
        "${growth >= 0 ? "+" : ""}${growth.toStringAsFixed(1)} pts";
    return WebGrid(
      columns: 4,
      children: [
        Kpi(
          label: "Overall average",
          value: "${perf.overallAverage.toStringAsFixed(1)}%",
          icon: Iconsax.chart_21,
          tone: _tone(perf.overallAverage),
          foot: "Grade ${perf.grade}",
        ),
        Kpi(
          label: "Growth rate",
          value: growthText,
          icon: growth >= 0 ? Iconsax.trend_up : Iconsax.trend_down,
          tone: growth >= 0 ? Tone.success : Tone.danger,
          trend:
              "${perf.firstHalfAverage.toStringAsFixed(0)}% → ${perf.lastHalfAverage.toStringAsFixed(0)}%",
          trendDown: growth < 0,
          foot: "earliest vs latest tests",
        ),
        Kpi(
          label: "Tests taken",
          value: "${perf.testCount}",
          icon: Iconsax.task_square,
          tone: Tone.info,
          foot: "assignments + quizzes",
        ),
        Kpi(
          label: "Best subject",
          value: perf.bestSubject ?? "-",
          icon: Iconsax.medal_star,
          tone: Tone.primary,
          foot: perf.subjects.isEmpty
              ? null
              : "${perf.subjects.first.average.toStringAsFixed(0)}% average",
        ),
      ],
    );
  }

  Widget _trendCard(WebTokens t, StudentPerformance perf) {
    return WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHead(
            title: "Performance trend",
            subtitle: "Percentage per test, oldest to latest.",
            trailing: _legendDot(t),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: CustomPaint(
              painter: _TrendChartPainter(
                values: perf.tests.map((e) => e.percentage).toList(),
                line: t.primary,
                fill: t.primary.withValues(alpha: 0.12),
                grid: t.line,
                muted: t.muted,
                dot: t.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(WebTokens t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: t.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text("Score %", style: TextStyle(color: t.muted, fontSize: 10.5)),
        ],
      );

  Widget _subjectsCard(WebTokens t, StudentPerformance perf) {
    return WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead(
            title: "Average by subject",
            subtitle: "How the student is doing in each subject.",
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < perf.subjects.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            HBar(
              label: "${perf.subjects[i].subject} (${perf.subjects[i].count})",
              value: "${perf.subjects[i].average.toStringAsFixed(0)}%",
              fraction: perf.subjects[i].average / 100,
              tone: _tone(perf.subjects[i].average),
            ),
          ],
        ],
      ),
    );
  }

  Widget _testsCard(WebTokens t, StudentPerformance perf) {
    return WebCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHead(
            title: "All tests",
            subtitle: "Every graded assignment and quiz.",
          ),
          const SizedBox(height: 14),
          WebTable(
            columns: const [
              WebCol("Test", flex: 4),
              WebCol("Subject", flex: 3),
              WebCol("Type", flex: 2),
              WebCol("Date", flex: 3),
              WebCol("Score", flex: 2, right: true),
              WebCol("%", flex: 2, right: true),
            ],
            rows: [
              for (final test in perf.tests)
                [
                  Text(test.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(test.subject,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  StatusChip(test.type,
                      tone: test.type == "Quiz" ? Tone.info : Tone.primary),
                  Text(Formatters.date(test.date)),
                  Text("${_num(test.score)}/${_num(test.total)}"),
                  Text("${test.percentage.toStringAsFixed(0)}%",
                      style: TextStyle(
                          color: _tone(test.percentage).fg(t),
                          fontWeight: FontWeight.w800)),
                ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton(WebTokens t) => Material(
        color: t.panel,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => Get.back<void>(),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Iconsax.arrow_left_2, size: 18, color: t.ink),
          ),
        ),
      );

  Widget _noData(WebTokens t) => WebCard(
        padding: const EdgeInsets.symmetric(vertical: 54),
        child: Center(
          child: Column(
            children: [
              Icon(Iconsax.chart, size: 40, color: t.muted),
              const SizedBox(height: 12),
              Text("No graded tests yet",
                  style: TextStyle(
                      color: t.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  "This student has no graded assignments or quizzes to report on.",
                  style: TextStyle(color: t.muted, fontSize: 11.5)),
            ],
          ),
        ),
      );

  Widget _errorState(WebTokens t) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.warning_2, size: 40, color: t.danger),
            const SizedBox(height: 12),
            Text("Could not load performance data",
                style: TextStyle(color: t.ink, fontSize: 14)),
            const SizedBox(height: 12),
            WebButton(
              label: "Back",
              icon: Iconsax.arrow_left_2,
              onTap: () => Get.back<void>(),
            ),
          ],
        ),
      );

  Tone _tone(double pct) {
    if (pct >= 75) return Tone.success;
    if (pct >= 50) return Tone.primary;
    if (pct >= 40) return Tone.warning;
    return Tone.danger;
  }

  String _num(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}

/// A smooth line chart with grid, area fill and point markers.
class _TrendChartPainter extends CustomPainter {
  final List<double> values; // 0..100
  final Color line;
  final Color fill;
  final Color grid;
  final Color muted;
  final Color dot;

  _TrendChartPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
    required this.muted,
    required this.dot,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const bottomPad = 22.0;
    const topPad = 8.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: muted, fontSize: 9);

    double yFor(double pct) => topPad + chartH * (1 - pct / 100);

    // Horizontal gridlines + y labels at 0/25/50/75/100.
    for (final g in [0, 25, 50, 75, 100]) {
      final y = yFor(g.toDouble());
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: "$g", style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    if (values.isEmpty) return;

    double xFor(int i) {
      if (values.length == 1) return leftPad + chartW / 2;
      return leftPad + chartW * (i / (values.length - 1));
    }

    final points = [
      for (int i = 0; i < values.length; i++)
        Offset(xFor(i), yFor(values[i])),
    ];

    // Area fill under the line.
    if (points.length > 1) {
      final area = Path()..moveTo(points.first.dx, topPad + chartH);
      for (final p in points) {
        area.lineTo(p.dx, p.dy);
      }
      area.lineTo(points.last.dx, topPad + chartH);
      area.close();
      canvas.drawPath(area, Paint()..color = fill);
    }

    // The line.
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Point markers.
    final dotFill = Paint()..color = dot;
    final dotRing = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = math.min(4.0, chartW / (values.length * 2)).clamp(2.0, 4.0);
    for (final p in points) {
      canvas.drawCircle(p, r, dotFill);
      canvas.drawCircle(p, r, dotRing);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) =>
      old.values != values ||
      old.line != line ||
      old.fill != fill ||
      old.grid != grid;
}
