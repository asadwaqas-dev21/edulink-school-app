import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/domain/entities/announcement.dart";
import "package:edulink/domain/entities/expense.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/invoice_item.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_tokens.dart";
import "package:edulink/presentation/web/web_widgets.dart";

WebDashboardController get _c => Get.find<WebDashboardController>();
SessionController get _session => Get.find<SessionController>();

Future<void> showWebModal({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext, void Function(void Function())) body,
  required Future<bool> Function() onSave,
  String saveLabel = "Save",
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final t = WebTokens.of(ctx);
      bool saving = false;
      return StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: t.panel,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(19, 16, 12, 16),
                  decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: t.line))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                                color: t.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: t.muted, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: body(ctx, setState),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(19, 14, 19, 15),
                  decoration:
                      BoxDecoration(border: Border(top: BorderSide(color: t.line))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      WebButton(
                          label: "Cancel",
                          onTap: () => Navigator.pop(ctx)),
                      const SizedBox(width: 8),
                      WebButton(
                        label: saving ? "Saving…" : saveLabel,
                        kind: WebBtnKind.primary,
                        onTap: saving
                            ? null
                            : () async {
                                setState(() => saving = true);
                                final ok = await onSave();
                                if (ok && ctx.mounted) {
                                  Navigator.pop(ctx);
                                } else {
                                  setState(() => saving = false);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class WebField extends StatelessWidget {
  final String label;
  final Widget child;
  const WebField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                color: t.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

InputDecoration _dec(WebTokens t, {String? hint}) => InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: t.panel2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: t.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: t.line),
      ),
    );

// ── Add expense ──
Future<void> showAddExpenseModal(BuildContext context, {Expense? existing}) async {
  final t = WebTokens.of(context);
  final titleCtrl = TextEditingController(text: existing?.title ?? "");
  final payeeCtrl = TextEditingController(text: existing?.payee ?? "");
  final amountCtrl = TextEditingController(
      text: existing == null ? "" : existing.amount.toString());
  final noteCtrl = TextEditingController(text: existing?.note ?? "");
  var category = existing?.category ?? ExpenseCategory.teacherSalary;
  var status = existing?.status ?? ExpenseStatus.paid;
  var date = existing?.paidOn ?? DateTime.now();

  await showWebModal(
    context: context,
    title: existing == null ? "Add institute expense" : "Edit expense",
    saveLabel: existing == null ? "Save expense" : "Save changes",
    body: (ctx, setState) => Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WebField(
                label: "Category",
                child: DropdownButtonFormField<ExpenseCategory>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: _dec(t),
                  items: ExpenseCategory.values
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WebField(
                label: "Status",
                child: DropdownButtonFormField<ExpenseStatus>(
                  initialValue: status,
                  isExpanded: true,
                  decoration: _dec(t),
                  items: ExpenseStatus.values
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  onChanged: (v) => setState(() => status = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WebField(
            label: "Title",
            child: TextField(
                controller: titleCtrl,
                decoration: _dec(t, hint: "e.g. July payroll"))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: WebField(
                  label: "Payee",
                  child: TextField(
                      controller: payeeCtrl,
                      decoration: _dec(t, hint: "Payee name"))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WebField(
                  label: "Amount (PKR)",
                  child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dec(t, hint: "0"))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WebField(
          label: "Date",
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: ctx,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDate: date,
              );
              if (picked != null) setState(() => date = picked);
            },
            child: InputDecorator(
                decoration: _dec(t), child: Text(Formatters.date(date))),
          ),
        ),
        const SizedBox(height: 12),
        WebField(
            label: "Note",
            child: TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: _dec(t, hint: "Expense details…"))),
      ],
    ),
    onSave: () async {
      final amount = num.tryParse(amountCtrl.text.trim());
      if (titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
        SnackbarUtils.showWarning("Enter a title and a valid amount");
        return false;
      }
      final expense = Expense(
        id: existing?.id ?? "",
        instituteId: _c.instituteId,
        category: category,
        title: titleCtrl.text.trim(),
        amount: amount,
        payee: payeeCtrl.text.trim().isEmpty ? null : payeeCtrl.text.trim(),
        status: status,
        paidOn: date,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        createdBy: existing?.createdBy ?? _session.userId,
      );
      try {
        if (existing != null) {
          await _c.updateExpense(existing.id, expense);
        } else {
          await _c.addExpense(expense);
        }
        SnackbarUtils.showSuccess("Expense saved");
        return true;
      } catch (e) {
        SnackbarUtils.showError(e.toString());
        return false;
      }
    },
  );
}

// ── Create fee slip (multi-item) ──
class _Line {
  final descCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: "1");
  final priceCtrl = TextEditingController();
  num get amount =>
      (num.tryParse(qtyCtrl.text.trim()) ?? 0) *
      (num.tryParse(priceCtrl.text.trim()) ?? 0);
  bool get valid => descCtrl.text.trim().isNotEmpty && amount > 0;
}

Future<void> showCreateInvoiceModal(BuildContext context) async {
  final t = WebTokens.of(context);
  final titleCtrl = TextEditingController(text: "Fee Slip");
  Profile? student;
  final rows = <_Line>[_Line()];
  var due = DateTime.now().add(const Duration(days: 5));

  await showWebModal(
    context: context,
    title: "Create fee slip",
    saveLabel: "Create fee slip",
    body: (ctx, setState) {
      final total = rows.fold<num>(0, (s, r) => s + r.amount);
      return Column(
        children: [
          WebField(
            label: "Student",
            child: DropdownButtonFormField<Profile>(
              initialValue: student,
              isExpanded: true,
              decoration: _dec(t, hint: "Select student"),
              items: _c.students
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.fullName)))
                  .toList(),
              onChanged: (v) => setState(() => student = v),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: WebField(
                    label: "Slip title",
                    child: TextField(
                        controller: titleCtrl, decoration: _dec(t))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WebField(
                  label: "Due date",
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        initialDate: due,
                      );
                      if (picked != null) setState(() => due = picked);
                    },
                    child: InputDecorator(
                        decoration: _dec(t),
                        child: Text(Formatters.date(due))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: Text("Line items",
                      style: TextStyle(
                          color: t.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800))),
              WebButton(
                  label: "Add item",
                  icon: Icons.add,
                  onTap: () => setState(() => rows.add(_Line()))),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: TextField(
                          controller: rows[i].descCtrl,
                          decoration: _dec(t, hint: "Description"))),
                  const SizedBox(width: 6),
                  Expanded(
                      flex: 2,
                      child: TextField(
                          controller: rows[i].qtyCtrl,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: _dec(t, hint: "Qty"))),
                  const SizedBox(width: 6),
                  Expanded(
                      flex: 3,
                      child: TextField(
                          controller: rows[i].priceCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: _dec(t, hint: "Price"))),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: t.danger),
                    onPressed: rows.length == 1
                        ? null
                        : () => setState(() => rows.removeAt(i)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: t.primarySoft, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total",
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Text(Formatters.money(total),
                    style: TextStyle(
                        color: t.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      );
    },
    onSave: () async {
      if (student == null) {
        SnackbarUtils.showWarning("Select a student");
        return false;
      }
      final items = rows
          .where((r) => r.valid)
          .map((r) => InvoiceItem(
                description: r.descCtrl.text.trim(),
                quantity: num.tryParse(r.qtyCtrl.text.trim()) ?? 1,
                unitPrice: num.tryParse(r.priceCtrl.text.trim()) ?? 0,
              ))
          .toList();
      if (items.isEmpty) {
        SnackbarUtils.showWarning("Add at least one line item with an amount");
        return false;
      }
      try {
        await _c.createInvoice(
          Invoice(
            id: "",
            instituteId: _c.instituteId,
            studentId: student!.id,
            title: titleCtrl.text.trim(),
            amount: items.fold<num>(0, (s, i) => s + i.amount),
            dueDate: due,
            createdBy: _session.userId,
          ),
          items,
        );
        SnackbarUtils.showSuccess("Fee slip created");
        return true;
      } catch (e) {
        SnackbarUtils.showError(e.toString());
        return false;
      }
    },
  );
}

// ── Add member ──
Future<void> showAddMemberModal(BuildContext context) async {
  final t = WebTokens.of(context);
  final emailCtrl = TextEditingController();

  await showWebModal(
    context: context,
    title: "Add institute member",
    saveLabel: "Add member",
    body: (ctx, setState) => Column(
      children: [
        WebField(
            label: "Account email",
            child: TextField(
                controller: emailCtrl,
                decoration: _dec(t, hint: "member@email.com"))),
        const SizedBox(height: 12),
        Text(
          "The person must already have an Edulink account. They will be linked to this institute.",
          style: TextStyle(color: t.muted, fontSize: 10.5),
        ),
      ],
    ),
    onSave: () async {
      if (emailCtrl.text.trim().isEmpty) {
        SnackbarUtils.showWarning("Enter an email");
        return false;
      }
      try {
        await _c.addMember(emailCtrl.text.trim(), _c.instituteId);
        SnackbarUtils.showSuccess("Member added");
        return true;
      } catch (e) {
        SnackbarUtils.showError(e.toString());
        return false;
      }
    },
  );
}

// ── Announcement ──
Future<void> showAnnouncementModal(BuildContext context) async {
  final t = WebTokens.of(context);
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  var audience = "all";
  const audiences = ["all", "teachers", "students", "parents"];

  await showWebModal(
    context: context,
    title: "Create announcement",
    saveLabel: "Publish",
    body: (ctx, setState) => Column(
      children: [
        WebField(
            label: "Title",
            child: TextField(
                controller: titleCtrl,
                decoration: _dec(t, hint: "Announcement title"))),
        const SizedBox(height: 12),
        WebField(
          label: "Audience",
          child: DropdownButtonFormField<String>(
            initialValue: audience,
            isExpanded: true,
            decoration: _dec(t),
            items: audiences
                .map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(a[0].toUpperCase() + a.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => audience = v!),
          ),
        ),
        const SizedBox(height: 12),
        WebField(
            label: "Message",
            child: TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: _dec(t, hint: "Write your announcement…"))),
      ],
    ),
    onSave: () async {
      if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
        SnackbarUtils.showWarning("Enter a title and message");
        return false;
      }
      try {
        await _c.postAnnouncement(Announcement(
          id: "",
          instituteId: _c.instituteId,
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          authorId: _session.userId,
          audience: audience,
        ));
        SnackbarUtils.showSuccess("Announcement published");
        return true;
      } catch (e) {
        SnackbarUtils.showError(e.toString());
        return false;
      }
    },
  );
}
