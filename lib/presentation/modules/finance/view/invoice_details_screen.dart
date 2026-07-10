import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/services/fee_slip_service.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/core/utils/validators.dart";
import "package:edulink/data/repositories/finance_repository.dart";
import "package:edulink/data/repositories/institute_repository.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/payment.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/global_widgets/primary_button.dart";

class InvoiceDetailsScreen extends StatefulWidget {
  final Invoice invoice;
  const InvoiceDetailsScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final _repo = Get.find<FinanceRepository>();
  final _institutes = Get.find<InstituteRepository>();
  final _session = Get.find<SessionController>();

  late Invoice _invoice;
  late Future<List<Payment>> _payments;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _payments = _repo.payments(_invoice.id);
  }

  Future<void> _printSlip() async {
    setState(() => _printing = true);
    try {
      final payments = await _repo.payments(_invoice.id);
      final institute = _invoice.instituteId.isEmpty
          ? null
          : await _institutes.getById(_invoice.instituteId);
      await FeeSlipService.printSlip(
        invoice: _invoice,
        payments: payments,
        institute: institute,
        studentName: _invoice.studentName,
      );
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _refresh() async {
    setState(() { _payments = _repo.payments(_invoice.id); });
  }

  Future<void> _pay({required bool online}) async {
    final amountCtrl =
        TextEditingController(text: _invoice.balance.toString());
    final refCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(online ? "Pay Now" : "Record Payment",
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
                validator: (v) => Validators.positiveAmount(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: refCtrl,
                decoration: InputDecoration(
                    labelText: online
                        ? "Card / reference (optional)"
                        : "Reference (optional)"),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: Text(online ? "Pay" : "Record"),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok == true) {
      final amount = num.parse(amountCtrl.text.trim());
      try {
        await _repo.recordPayment(
          Payment(
            id: "",
            invoiceId: _invoice.id,
            amount: amount,
            method: online ? "online" : "cash",
            reference:
                refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
            recordedBy: _session.userId,
          ),
          _invoice,
        );
        SnackbarUtils.showSuccess("Payment recorded");
        setState(() {
          _invoice = Invoice(
            id: _invoice.id,
            instituteId: _invoice.instituteId,
            studentId: _invoice.studentId,
            title: _invoice.title,
            amount: _invoice.amount,
            amountPaid: _invoice.amountPaid + amount,
            dueDate: _invoice.dueDate,
            status: _invoice.status,
            studentName: _invoice.studentName,
            items: _invoice.items,
          );
        });
        _refresh();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _session.role;
    final canRecord = role.canManageFinance;
    final canPay = role.isParent || role.isStudent;
    final hasBalance = _invoice.balance > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice.title),
        actions: [
          IconButton(
            tooltip: "Print fee slip",
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Iconsax.printer),
            onPressed: _printing ? null : _printSlip,
          ),
        ],
      ),
      bottomNavigationBar: (hasBalance && (canRecord || canPay))
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  text: canPay ? "Pay Now" : "Record Payment",
                  icon: Iconsax.card,
                  onPressed: () => _pay(online: canPay),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_invoice.items.isNotEmpty) ...[
            Text("Expenses", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final item in _invoice.items) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge),
                                if (item.quantity != 1)
                                  Text(
                                    "${item.quantity} × ${Formatters.money(item.unitPrice)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          Text(Formatters.money(item.amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (item != _invoice.items.last)
                        const Divider(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row("Total", Formatters.money(_invoice.amount)),
                  const Divider(height: 20),
                  _row("Paid", Formatters.money(_invoice.amountPaid)),
                  const Divider(height: 20),
                  _row("Balance", Formatters.money(_invoice.balance),
                      highlight: true),
                  if (_invoice.dueDate != null) ...[
                    const Divider(height: 20),
                    _row("Due date", Formatters.date(_invoice.dueDate)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("Payment history",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          FutureBuilder<List<Payment>>(
            future: _payments,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                    padding: EdgeInsets.all(24), child: LoadingWidget());
              }
              final payments = snap.data ?? [];
              if (payments.isEmpty) {
                return Text("No payments recorded yet.",
                    style: Theme.of(context).textTheme.bodyMedium);
              }
              return Column(
                children: payments
                    .map((p) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Iconsax.money_recive,
                                color: AppColors.success),
                            title: Text(Formatters.money(p.amount)),
                            subtitle: Text([
                              if (p.method != null) p.method!.toUpperCase(),
                              Formatters.dateTime(p.paidAt),
                            ].join("  •  ")),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: highlight ? AppColors.error : null,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
