import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart";
import "package:edulink/core/services/performance_report_service.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/domain/entities/institute.dart";

/// Builds and prints a student performance report PDF with visual charts.
///
/// Works on web, desktop and mobile via the `printing` package which opens the
/// native print / save-as-PDF dialog.
abstract class StudentReportPdfService {
  static const PdfColor _brand = PdfColor.fromInt(0xFF1BA4DF);
  static const PdfColor _ink = PdfColor.fromInt(0xFF172033);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _track = PdfColor.fromInt(0xFFEDF1F6);
  static const PdfColor _success = PdfColor.fromInt(0xFF19A974);
  static const PdfColor _danger = PdfColor.fromInt(0xFFDC2626);

  static Future<void> printReport(
    StudentPerformance perf, {
    Institute? institute,
  }) async {
    final doc = await _build(perf, institute);
    final safeName = perf.student.fullName.replaceAll(RegExp(r"[^\w\s-]"), "").trim();
    await Printing.layoutPdf(
      name: "performance-report-${safeName.isEmpty ? "student" : safeName}.pdf",
      onLayout: (format) async => doc.save(),
    );
  }

  static Future<pw.Document> _build(
    StudentPerformance perf,
    Institute? institute,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(institute),
          pw.SizedBox(height: 18),
          _studentBar(perf),
          pw.SizedBox(height: 18),
          _kpis(perf),
          pw.SizedBox(height: 22),
          if (perf.hasData) ...[
            _sectionTitle("Score trend (oldest to latest)"),
            pw.SizedBox(height: 10),
            _trendChart(perf),
            pw.SizedBox(height: 24),
            _sectionTitle("Average by subject"),
            pw.SizedBox(height: 10),
            _subjectChart(perf),
            pw.SizedBox(height: 24),
            _sectionTitle("All tests"),
            pw.SizedBox(height: 8),
            _testsTable(perf),
          ] else
            pw.Text("No graded tests yet for this student.",
                style: const pw.TextStyle(fontSize: 11, color: _muted)),
          pw.SizedBox(height: 26),
          _footer(),
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _header(Institute? institute) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(institute?.name ?? "Edulink",
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _brand)),
            if (institute?.address != null)
              pw.Text(institute!.address!,
                  style: const pw.TextStyle(fontSize: 10, color: _muted)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
              color: _brand, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Text("PERFORMANCE REPORT",
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _studentBar(StudentPerformance perf) {
    pw.Widget cell(String label, String value) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3F7FB),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          cell("Student", perf.student.fullName),
          cell("Email", perf.student.email),
          cell("Tests taken", "${perf.testCount}"),
          cell("Generated", Formatters.date(DateTime.now())),
        ],
      ),
    );
  }

  static pw.Widget _kpis(StudentPerformance perf) {
    final growth = perf.growthRate;
    final growthText =
        "${growth >= 0 ? "+" : ""}${growth.toStringAsFixed(1)} pts";
    return pw.Row(
      children: [
        _kpiCard("Overall average", "${perf.overallAverage.toStringAsFixed(1)}%",
            _brand),
        pw.SizedBox(width: 10),
        _kpiCard("Growth rate", growthText,
            growth >= 0 ? _success : _danger),
        pw.SizedBox(width: 10),
        _kpiCard("Grade", perf.grade, _ink),
        pw.SizedBox(width: 10),
        _kpiCard("Best subject", perf.bestSubject ?? "-", _ink),
      ],
    );
  }

  static pw.Widget _kpiCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 6),
            pw.Text(value,
                maxLines: 1,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Text(text,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold));

  /// Vertical bar chart of every test percentage, oldest → latest.
  static pw.Widget _trendChart(StudentPerformance perf) {
    const chartHeight = 150.0;
    final tests = perf.tests;
    final showLabels = tests.length <= 16;

    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.SizedBox(
            height: chartHeight,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                for (final t in tests)
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          if (showLabels)
                            pw.Text(t.percentage.toStringAsFixed(0),
                                style: const pw.TextStyle(
                                    fontSize: 7, color: _muted)),
                          pw.SizedBox(height: 2),
                          pw.Container(
                            height: (t.percentage / 100 * (chartHeight - 16))
                                .clamp(1.0, chartHeight - 16),
                            decoration: pw.BoxDecoration(
                              color: _toneFor(t.percentage),
                              borderRadius: const pw.BorderRadius.only(
                                topLeft: pw.Radius.circular(2),
                                topRight: pw.Radius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.Divider(color: _line, height: 8),
          pw.Text("Each bar is one test • ${tests.length} tests total",
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
        ],
      ),
    );
  }

  /// Horizontal bars of per-subject averages.
  static pw.Widget _subjectChart(StudentPerformance perf) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.8),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          for (final s in perf.subjects)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(
                    width: 120,
                    child: pw.Text("${s.subject} (${s.count})",
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 14,
                      decoration: pw.BoxDecoration(
                        color: _track,
                        borderRadius: pw.BorderRadius.circular(7),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: s.average.round().clamp(1, 100),
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                color: _toneFor(s.average),
                                borderRadius: pw.BorderRadius.circular(7),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: (100 - s.average).round().clamp(1, 100),
                            child: pw.SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text("${s.average.toStringAsFixed(0)}%",
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _testsTable(StudentPerformance perf) {
    pw.Widget hCell(String t, {pw.Alignment align = pw.Alignment.centerLeft}) =>
        pw.Container(
          alignment: align,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
        );
    pw.Widget dCell(String t,
            {pw.Alignment align = pw.Alignment.centerLeft, PdfColor? color}) =>
        pw.Container(
          alignment: align,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(t,
              style: pw.TextStyle(fontSize: 9, color: color ?? _ink)),
        );

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(2.4),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(2.2),
        4: pw.FlexColumnWidth(1.6),
        5: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brand),
          children: [
            hCell("Test"),
            hCell("Subject"),
            hCell("Type"),
            hCell("Date"),
            hCell("Score", align: pw.Alignment.centerRight),
            hCell("%", align: pw.Alignment.centerRight),
          ],
        ),
        for (final t in perf.tests)
          pw.TableRow(children: [
            dCell(t.title),
            dCell(t.subject),
            dCell(t.type),
            dCell(Formatters.date(t.date)),
            dCell("${_num(t.score)}/${_num(t.total)}",
                align: pw.Alignment.centerRight),
            dCell("${t.percentage.toStringAsFixed(0)}%",
                align: pw.Alignment.centerRight, color: _toneFor(t.percentage)),
          ]),
      ],
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: _line),
        pw.SizedBox(height: 4),
        pw.Text(
          "Generated on ${Formatters.dateTime(DateTime.now())} • Computer-generated performance report.",
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    );
  }

  static PdfColor _toneFor(double pct) {
    if (pct >= 75) return _success;
    if (pct >= 50) return _brand;
    if (pct >= 40) return const PdfColor.fromInt(0xFFE9A23B);
    return _danger;
  }

  static String _num(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}
