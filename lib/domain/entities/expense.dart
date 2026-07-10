import "package:edulink/core/enums/status_enums.dart";

/// A single institute expense (salary, rent, utilities, etc.).
class Expense {
  final String id;
  final String instituteId;
  final ExpenseCategory category;
  final String title;
  final num amount;
  final String? payee;
  final ExpenseStatus status;
  final DateTime? paidOn;
  final String? note;
  final String? createdBy;
  final DateTime? createdAt;

  const Expense({
    this.id = "",
    required this.instituteId,
    required this.category,
    required this.title,
    required this.amount,
    this.payee,
    this.status = ExpenseStatus.paid,
    this.paidOn,
    this.note,
    this.createdBy,
    this.createdAt,
  });

  bool get isPaid => status == ExpenseStatus.paid;

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: (map["id"] ?? "") as String,
      instituteId: (map["institute_id"] ?? "") as String,
      category: ExpenseCategory.fromKey(map["category"] as String?),
      title: (map["title"] ?? "") as String,
      amount: (map["amount"] ?? 0) as num,
      payee: map["payee"] as String?,
      status: ExpenseStatus.fromKey(map["status"] as String?),
      paidOn: map["paid_on"] == null
          ? null
          : DateTime.tryParse(map["paid_on"].toString()),
      note: map["note"] as String?,
      createdBy: map["created_by"] as String?,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "institute_id": instituteId,
        "category": category.key,
        "title": title,
        "amount": amount,
        "payee": payee,
        "status": status.key,
        "paid_on": paidOn?.toIso8601String().substring(0, 10),
        "note": note,
        "created_by": createdBy,
      };
}
