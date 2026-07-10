import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/domain/entities/expense.dart";
import "package:edulink/domain/entities/invoice.dart";
import "package:edulink/domain/entities/invoice_item.dart";
import "package:edulink/domain/entities/payment.dart";

/// Invoices and payments (financial module).
class FinanceRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  static const String _select =
      "*, student:student_id(full_name), items:invoice_items(*)";

  Future<List<Invoice>> forInstitute(String instituteId) async {
    final data = await _client
        .from(SupabaseConfig.tInvoices)
        .select(_select)
        .eq("institute_id", instituteId)
        .order("created_at", ascending: false);
    return (data as List).map((e) => Invoice.fromMap(e)).toList();
  }

  Future<List<Invoice>> forStudent(String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tInvoices)
        .select(_select)
        .eq("student_id", studentId)
        .order("created_at", ascending: false);
    return (data as List).map((e) => Invoice.fromMap(e)).toList();
  }

  Future<List<Invoice>> forStudents(List<String> studentIds) async {
    if (studentIds.isEmpty) return [];
    final data = await _client
        .from(SupabaseConfig.tInvoices)
        .select(_select)
        .inFilter("student_id", studentIds)
        .order("created_at", ascending: false);
    return (data as List).map((e) => Invoice.fromMap(e)).toList();
  }

  /// Creates an invoice together with its line items (expenses).
  /// The invoice total is derived from the sum of the items when provided.
  Future<Invoice> create(Invoice invoice, {List<InvoiceItem> items = const []}) async {
    final total =
        items.isEmpty ? invoice.amount : items.fold<num>(0, (s, i) => s + i.amount);
    final payload = invoice.toMap()..["amount"] = total;

    final created = await _client
        .from(SupabaseConfig.tInvoices)
        .insert(payload)
        .select("id")
        .single();
    final invoiceId = created["id"] as String;

    if (items.isNotEmpty) {
      await _client.from(SupabaseConfig.tInvoiceItems).insert(
            items.map((i) => i.copyWith(invoiceId: invoiceId).toMap()).toList(),
          );
    }

    final data = await _client
        .from(SupabaseConfig.tInvoices)
        .select(_select)
        .eq("id", invoiceId)
        .single();
    return Invoice.fromMap(data);
  }

  Future<List<InvoiceItem>> items(String invoiceId) async {
    final data = await _client
        .from(SupabaseConfig.tInvoiceItems)
        .select()
        .eq("invoice_id", invoiceId)
        .order("created_at");
    return (data as List).map((e) => InvoiceItem.fromMap(e)).toList();
  }

  Future<void> deleteInvoice(String id) async {
    await _client.from(SupabaseConfig.tInvoices).delete().eq("id", id);
  }

  Future<List<Payment>> payments(String invoiceId) async {
    final data = await _client
        .from(SupabaseConfig.tPayments)
        .select()
        .eq("invoice_id", invoiceId)
        .order("paid_at", ascending: false);
    return (data as List).map((e) => Payment.fromMap(e)).toList();
  }

  /// Records a payment and updates the parent invoice's paid amount/status.
  Future<void> recordPayment(Payment payment, Invoice invoice) async {
    await _client.from(SupabaseConfig.tPayments).insert(payment.toMap());

    final newPaid = invoice.amountPaid + payment.amount;
    final status = newPaid >= invoice.amount
        ? InvoiceStatus.paid
        : (newPaid > 0 ? InvoiceStatus.partial : InvoiceStatus.pending);

    await _client.from(SupabaseConfig.tInvoices).update({
      "amount_paid": newPaid,
      "status": status.key,
    }).eq("id", invoice.id);
  }

  // ── Institute expenses (admin-only finance management) ──

  Future<List<Expense>> expenses(String instituteId) async {
    final data = await _client
        .from(SupabaseConfig.tExpenses)
        .select()
        .eq("institute_id", instituteId)
        .order("paid_on", ascending: false, nullsFirst: false)
        .order("created_at", ascending: false);
    return (data as List).map((e) => Expense.fromMap(e)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final data = await _client
        .from(SupabaseConfig.tExpenses)
        .insert(expense.toMap())
        .select()
        .single();
    return Expense.fromMap(data);
  }

  Future<Expense> updateExpense(String id, Expense expense) async {
    final data = await _client
        .from(SupabaseConfig.tExpenses)
        .update(expense.toMap())
        .eq("id", id)
        .select()
        .single();
    return Expense.fromMap(data);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from(SupabaseConfig.tExpenses).delete().eq("id", id);
  }
}
