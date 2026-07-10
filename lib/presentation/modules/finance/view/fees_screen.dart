import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/invoice_item.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/modules/finance/view/invoice_details_screen.dart";

/// Holds the editing controllers for a single expense line in the create sheet.
class _LineDraft {
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: "1");
  final TextEditingController priceCtrl = TextEditingController();

  num get quantity => num.tryParse(qtyCtrl.text.trim()) ?? 0;
  num get unitPrice => num.tryParse(priceCtrl.text.trim()) ?? 0;
  num get amount => quantity * unitPrice;
  bool get isValid => descCtrl.text.trim().isNotEmpty && amount > 0;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final _repo = Get.find<FinanceRepository>();
  final _academics = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  late Future<List<Invoice>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Invoice>> _load() async {
    final role = _session.role;
    final uid = _session.userId ?? "";
    if (role.isPrincipal) {
      return _repo.forInstitute(_session.instituteId ?? "");
    } else if (role.isStudent) {
      return _repo.forStudent(uid);
    } else if (role.isParent) {
      final children = await _academics.childrenOfParent(uid);
      return _repo.forStudents(children.map((c) => c.studentId).toList());
    }
    return _repo.forInstitute(_session.instituteId ?? "");
  }

  void _reload() { setState(() { _future = _load(); }); }

  Future<void> _createInvoice() async {
    final students =
        await _academics.peopleByRole(_session.instituteId ?? "", "student");
    Profile? student;
    final titleCtrl = TextEditingController(text: "Fee Slip");
    final formKey = GlobalKey<FormState>();
    final rows = <_LineDraft>[_LineDraft()];
    DateTime? due;

    if (!mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final total = rows.fold<num>(0, (s, r) => s + r.amount);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("New Fee Slip",
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Profile>(
                      initialValue: student,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Student"),
                      items: students
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.fullName)))
                          .toList(),
                      onChanged: (v) => setSheet(() => student = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                          labelText: "Slip title (e.g. Term 1 Dues)"),
                      validator: (v) => Validators.required(v, "Title"),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Expenses",
                            style: Theme.of(ctx).textTheme.titleMedium),
                        TextButton.icon(
                          onPressed: () =>
                              setSheet(() => rows.add(_LineDraft())),
                          icon: const Icon(Iconsax.add, size: 18),
                          label: const Text("Add item"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (int i = 0; i < rows.length; i++)
                      _lineItemField(ctx, setSheet, rows, i),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Iconsax.calendar_1),
                      label: Text(due == null
                          ? "Pick due date"
                          : "Due ${Formatters.date(due)}"),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) setSheet(() => due = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total",
                              style: Theme.of(ctx).textTheme.titleMedium),
                          Text(Formatters.money(total),
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (student == null) {
                          SnackbarUtils.showWarning("Select a student");
                          return;
                        }
                        if (!formKey.currentState!.validate()) return;
                        final valid = rows.where((r) => r.isValid).toList();
                        if (valid.isEmpty) {
                          SnackbarUtils.showWarning(
                              "Add at least one expense with an amount");
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text("Create Fee Slip"),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (ok == true && student != null) {
      final items = rows
          .where((r) => r.isValid)
          .map((r) => InvoiceItem(
                description: r.descCtrl.text.trim(),
                quantity: num.tryParse(r.qtyCtrl.text.trim()) ?? 1,
                unitPrice: num.tryParse(r.priceCtrl.text.trim()) ?? 0,
              ))
          .toList();
      try {
        await _repo.create(
          Invoice(
            id: "",
            instituteId: _session.instituteId ?? "",
            studentId: student!.id,
            title: titleCtrl.text.trim(),
            amount: items.fold<num>(0, (s, i) => s + i.amount),
            dueDate: due,
            createdBy: _session.userId,
          ),
          items: items,
        );
        SnackbarUtils.showSuccess("Fee slip created");
        _reload();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
    for (final r in rows) {
      r.dispose();
    }
    titleCtrl.dispose();
  }

  Widget _lineItemField(BuildContext ctx, StateSetter setSheet,
      List<_LineDraft> rows, int i) {
    final r = rows[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: r.descCtrl,
              decoration: const InputDecoration(
                labelText: "Description",
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: r.qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(labelText: "Qty", isDense: true),
              onChanged: (_) => setSheet(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: r.priceCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Price", isDense: true),
              onChanged: (_) => setSheet(() {}),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, size: 18, color: AppColors.error),
            onPressed: rows.length == 1
                ? null
                : () => setSheet(() {
                      rows.removeAt(i).dispose();
                    }),
          ),
        ],
      ),
    );
  }

  Color _statusColor(InvoiceStatus s) {
    switch (s) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.partial:
        return AppColors.warning;
      case InvoiceStatus.overdue:
        return AppColors.error;
      case InvoiceStatus.cancelled:
        return AppColors.textTertiaryLight;
      case InvoiceStatus.pending:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _session.role.canManageFinance;
    return Scaffold(
      appBar: AppBar(title: const Text("Fees & Invoices")),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _createInvoice,
              icon: const Icon(Iconsax.add),
              label: const Text("New Invoice"),
            )
          : null,
      body: FutureBuilder<List<Invoice>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Iconsax.warning_2,
              title: "Couldn't load invoices",
              subtitle: snap.error.toString(),
            );
          }
          final invoices = snap.data ?? [];
          if (invoices.isEmpty) {
            return const EmptyState(
              icon: Iconsax.receipt_1,
              title: "No invoices",
              subtitle: "Invoices will appear here.",
            );
          }
          final total = invoices.fold<num>(0, (s, i) => s + i.balance);
          return Column(
            children: [
              if (total > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Outstanding balance",
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(Formatters.money(total),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final inv = invoices[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                _statusColor(inv.status).withValues(alpha: 0.15),
                            child: Icon(Iconsax.receipt_1,
                                color: _statusColor(inv.status)),
                          ),
                          title: Text(inv.title),
                          subtitle: Text([
                            if (canManage && inv.studentName != null)
                              inv.studentName!,
                            inv.status.label,
                          ].join("  •  ")),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(Formatters.money(inv.amount),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              if (inv.balance > 0)
                                Text("Due ${Formatters.money(inv.balance)}",
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 12)),
                            ],
                          ),
                          onTap: () async {
                            await Get.to(
                                () => InvoiceDetailsScreen(invoice: inv));
                            _reload();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
