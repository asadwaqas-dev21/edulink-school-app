import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/data/repositories/report_repository.dart";
import "package:edulink/domain/entities/expense.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/global_widgets/stat_card.dart";

class _FinanceData {
  final Map<String, num> income;
  final List<Expense> expenses;
  const _FinanceData(this.income, this.expenses);

  num get collected => income["collected"] ?? 0;
  num get feesOutstanding => income["outstanding"] ?? 0;
  num get paidExpense =>
      expenses.where((e) => e.isPaid).fold<num>(0, (s, e) => s + e.amount);
  num get pendingExpense =>
      expenses.where((e) => !e.isPaid).fold<num>(0, (s, e) => s + e.amount);
  num get net => collected - paidExpense;
}

/// Admin-only (principal) finance & expense management for an institute.
class FinanceManagementScreen extends StatefulWidget {
  const FinanceManagementScreen({super.key});

  @override
  State<FinanceManagementScreen> createState() =>
      _FinanceManagementScreenState();
}

class _FinanceManagementScreenState extends State<FinanceManagementScreen> {
  final _repo = Get.find<FinanceRepository>();
  final _reports = Get.find<ReportRepository>();
  final _session = Get.find<SessionController>();

  late Future<_FinanceData> _future;

  String get _instituteId => _session.instituteId ?? "";

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FinanceData> _load() async {
    final results = await Future.wait([
      _reports.financeSummary(_instituteId),
      _repo.expenses(_instituteId),
    ]);
    return _FinanceData(
      results[0] as Map<String, num>,
      results[1] as List<Expense>,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  static IconData categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.teacherSalary:
        return Iconsax.teacher;
      case ExpenseCategory.staffSalary:
        return Iconsax.profile_2user;
      case ExpenseCategory.rent:
        return Iconsax.buildings;
      case ExpenseCategory.utilities:
        return Iconsax.flash_1;
      case ExpenseCategory.supplies:
        return Iconsax.box;
      case ExpenseCategory.maintenance:
        return Iconsax.setting_2;
      case ExpenseCategory.transport:
        return Iconsax.bus;
      case ExpenseCategory.other:
        return Iconsax.tag;
    }
  }

  Future<void> _expenseSheet({Expense? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? "");
    final payeeCtrl = TextEditingController(text: existing?.payee ?? "");
    final amountCtrl = TextEditingController(
        text: existing == null ? "" : existing.amount.toString());
    final noteCtrl = TextEditingController(text: existing?.note ?? "");
    final formKey = GlobalKey<FormState>();
    var category = existing?.category ?? ExpenseCategory.teacherSalary;
    var status = existing?.status ?? ExpenseStatus.paid;
    DateTime date = existing?.paidOn ?? DateTime.now();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
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
                  Text(isEdit ? "Edit Expense" : "Add Expense",
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: "Category"),
                    items: ExpenseCategory.values
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(categoryIcon(c),
                                      size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text(c.label),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                        labelText: "Title (e.g. July salary - Mr. Khan)"),
                    validator: (v) => Validators.required(v, "Title"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: payeeCtrl,
                    decoration: const InputDecoration(
                        labelText: "Paid to (optional)"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount"),
                    validator: (v) => Validators.positiveAmount(v),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ExpenseStatus>(
                    segments: const [
                      ButtonSegment(
                          value: ExpenseStatus.paid,
                          label: Text("Paid"),
                          icon: Icon(Iconsax.tick_circle)),
                      ButtonSegment(
                          value: ExpenseStatus.pending,
                          label: Text("Pending"),
                          icon: Icon(Iconsax.clock)),
                    ],
                    selected: {status},
                    onSelectionChanged: (s) =>
                        setSheet(() => status = s.first),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Iconsax.calendar_1),
                    label: Text("Date: ${Formatters.date(date)}"),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        initialDate: date,
                      );
                      if (picked != null) setSheet(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration:
                        const InputDecoration(labelText: "Note (optional)"),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(ctx, true);
                      }
                    },
                    child: Text(isEdit ? "Save Changes" : "Save Expense"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      final expense = Expense(
        id: existing?.id ?? "",
        instituteId: _instituteId,
        category: category,
        title: titleCtrl.text.trim(),
        amount: num.parse(amountCtrl.text.trim()),
        payee: payeeCtrl.text.trim().isEmpty ? null : payeeCtrl.text.trim(),
        status: status,
        paidOn: date,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        createdBy: existing?.createdBy ?? _session.userId,
      );
      try {
        if (existing != null) {
          await _repo.updateExpense(existing.id, expense);
          SnackbarUtils.showSuccess("Expense updated");
        } else {
          await _repo.createExpense(expense);
          SnackbarUtils.showSuccess("Expense added");
        }
        _reload();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
    titleCtrl.dispose();
    payeeCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _deleteExpense(Expense e) async {
    final confirm = await showDialog<bool>(
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
    if (confirm == true) {
      try {
        await _repo.deleteExpense(e.id);
        SnackbarUtils.showSuccess("Expense deleted");
        _reload();
      } catch (err) {
        SnackbarUtils.showError(err.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_session.role.isPrincipal) {
      return const Scaffold(
        body: EmptyState(
          icon: Iconsax.lock,
          title: "Admins only",
          subtitle: "Finance management is available to the principal.",
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Finance Management")),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _expenseSheet(),
        icon: const Icon(Iconsax.add),
        label: const Text("Add Expense"),
      ),
      body: FutureBuilder<_FinanceData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          if (snap.hasError) {
            return EmptyState(
              icon: Iconsax.warning_2,
              title: "Couldn't load finances",
              subtitle: snap.error.toString(),
            );
          }
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    _netCard(context, data),
                    const SizedBox(height: 16),
                    _summaryGrid(context, data),
                    const SizedBox(height: 24),
                    Text("Expenses",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (data.expenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: EmptyState(
                          icon: Iconsax.wallet_3,
                          title: "No expenses yet",
                          subtitle:
                              "Add salaries, rent and other costs to track spending.",
                        ),
                      )
                    else
                      ...data.expenses.map((e) => _expenseTile(context, e)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _netCard(BuildContext context, _FinanceData d) {
    final positive = d.net >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.wallet_money, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text("Net balance (in hand)",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 8),
          Text(Formatters.money(d.net),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            positive
                ? "Collected ${Formatters.money(d.collected)} − Spent ${Formatters.money(d.paidExpense)}"
                : "Spending exceeds collection",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid(BuildContext context, _FinanceData d) {
    final cards = [
      StatCard(
          icon: Iconsax.money_recive,
          label: "Fees Collected",
          value: Formatters.money(d.collected),
          color: AppColors.success),
      StatCard(
          icon: Iconsax.receipt_item,
          label: "Fees Pending",
          value: Formatters.money(d.feesOutstanding),
          color: AppColors.warning),
      StatCard(
          icon: Iconsax.money_send,
          label: "Total Spent",
          value: Formatters.money(d.paidExpense),
          color: AppColors.error),
      StatCard(
          icon: Iconsax.clock,
          label: "Pending Payouts",
          value: Formatters.money(d.pendingExpense),
          color: AppColors.info),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: w >= 900 ? 1.35 : 1.5,
          children: cards,
        );
      },
    );
  }

  Widget _expenseTile(BuildContext context, Expense e) {
    final color = e.isPaid ? AppColors.success : AppColors.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _expenseSheet(existing: e),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(categoryIcon(e.category), color: AppColors.primary),
        ),
        title: Text(e.title),
        subtitle: Text([
          e.category.label,
          if (e.payee != null && e.payee!.isNotEmpty) e.payee!,
          Formatters.date(e.paidOn),
        ].join("  •  ")),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(Formatters.money(e.amount),
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e.status.label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Iconsax.trash,
                  size: 18, color: AppColors.error),
              onPressed: () => _deleteExpense(e),
            ),
          ],
        ),
      ),
    );
  }
}
