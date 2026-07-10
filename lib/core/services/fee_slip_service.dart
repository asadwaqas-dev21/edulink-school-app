import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/domain/entities/institute.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/payment.dart";

/// Builds and prints a professional fee slip (invoice) PDF.
///
/// Works on web, desktop and mobile via the `printing` package which opens
/// the native print / save-as-PDF dialog.
abstract class FeeSlipService {
  static const PdfColor _brand = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _danger = PdfColor.fromInt(0xFFDC2626);

  static Future<void> printSlip({
    required Invoice invoice,
    List<Payment> payments = const [],
    Institute? institute,
    String? studentName,
  }) async {
    final doc = await _build(
      invoice: invoice,
      payments: payments,
      institute: institute,
      studentName: studentName,
    );
    await Printing.layoutPdf(
      name: "fee-slip-${invoice.title}.pdf",
      onLayout: (format) async => doc.save(),
    );
  }

  static Future<pw.Document> _build({
    required Invoice invoice,
    required List<Payment> payments,
    Institute? institute,
    String? studentName,
  }) async {
    final doc = pw.Document();
    final items = invoice.items;
    final subtotal = items.isEmpty
        ? invoice.amount
        : items.fold<num>(0, (s, i) => s + i.amount);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(institute),
              pw.SizedBox(height: 20),
              _titleBar(invoice),
              pw.SizedBox(height: 16),
              _meta(invoice, studentName),
              pw.SizedBox(height: 20),
              _itemsTable(invoice),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: _totals(invoice, subtotal),
              ),
              if (payments.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                _paymentsTable(payments),
              ],
              pw.Spacer(),
              _footer(),
            ],
          );
        },
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
            pw.Text(
              institute?.name ?? "Edulink",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _brand,
              ),
            ),
            if (institute?.address != null)
              pw.Text(institute!.address!,
                  style: const pw.TextStyle(fontSize: 10, color: _muted)),
            pw.Text(
              [
                if (institute?.phone != null) "Tel: ${institute!.phone}",
                if (institute?.email != null) institute!.email!,
              ].join("   "),
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _brand,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text("FEE SLIP",
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _titleBar(Invoice invoice) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3F4F6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        invoice.title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _meta(Invoice invoice, String? studentName) {
    pw.Widget cell(String label, String value) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(),
              style: const pw.TextStyle(fontSize: 8, color: _muted)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        cell("Billed to", studentName ?? invoice.studentName ?? "-"),
        cell("Issue date", Formatters.date(invoice.createdAt ?? DateTime.now())),
        cell("Due date", Formatters.date(invoice.dueDate)),
        cell("Status", invoice.status.label.toUpperCase()),
      ],
    );
  }

  static pw.Widget _itemsTable(Invoice invoice) {
    final items = invoice.items;

    pw.Widget headerCell(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      );
    }

    pw.Widget dataCell(String text,
        {pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Container(
        alignment: align,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _brand),
        children: [
          headerCell("Description"),
          headerCell("Qty", align: pw.Alignment.center),
          headerCell("Unit Price", align: pw.Alignment.centerRight),
          headerCell("Amount", align: pw.Alignment.centerRight),
        ],
      ),
    ];

    if (items.isEmpty) {
      rows.add(pw.TableRow(children: [
        dataCell(invoice.title),
        dataCell("1", align: pw.Alignment.center),
        dataCell(Formatters.money(invoice.amount),
            align: pw.Alignment.centerRight),
        dataCell(Formatters.money(invoice.amount),
            align: pw.Alignment.centerRight),
      ]));
    } else {
      for (final it in items) {
        rows.add(pw.TableRow(children: [
          dataCell(it.description),
          dataCell(_qty(it.quantity), align: pw.Alignment.center),
          dataCell(Formatters.money(it.unitPrice),
              align: pw.Alignment.centerRight),
          dataCell(Formatters.money(it.amount),
              align: pw.Alignment.centerRight),
        ]));
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  static pw.Widget _totals(Invoice invoice, num subtotal) {
    pw.Widget line(String label, String value, {bool danger = false, bool bold = false}) {
      return pw.Container(
        width: 220,
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: danger ? _danger : null)),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        line("Subtotal", Formatters.money(subtotal)),
        line("Paid", Formatters.money(invoice.amountPaid)),
        pw.Divider(color: _line, height: 8),
        line("Balance Due", Formatters.money(invoice.balance),
            danger: invoice.balance > 0, bold: true),
      ],
    );
  }

  static pw.Widget _paymentsTable(List<Payment> payments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Payment history",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: _line, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(2),
          },
          children: [
            for (final p in payments)
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(Formatters.dateTime(p.paidAt),
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text((p.method ?? "-").toUpperCase(),
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(Formatters.money(p.amount),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ),
              ]),
          ],
        ),
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
          "Generated on ${Formatters.dateTime(DateTime.now())} • This is a computer-generated fee slip.",
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    );
  }

  static String _qty(num q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}
