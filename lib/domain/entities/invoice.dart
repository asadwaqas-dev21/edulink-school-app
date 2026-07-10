import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/domain/entities/invoice_item.dart";

class Invoice {
  final String id;
  final String instituteId;
  final String studentId;
  final String title;
  final num amount;
  final num amountPaid;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final String? createdBy;
  final String? studentName;
  final DateTime? createdAt;
  final List<InvoiceItem> items;

  const Invoice({
    required this.id,
    required this.instituteId,
    required this.studentId,
    required this.title,
    required this.amount,
    this.amountPaid = 0,
    this.dueDate,
    this.status = InvoiceStatus.pending,
    this.createdBy,
    this.studentName,
    this.createdAt,
    this.items = const [],
  });

  num get balance => amount - amountPaid;
  bool get isFullyPaid => balance <= 0;

  factory Invoice.fromMap(Map<String, dynamic> map) {
    final student = map["student"];
    final rawItems = map["items"];
    return Invoice(
      id: map["id"] as String,
      instituteId: (map["institute_id"] ?? "") as String,
      studentId: (map["student_id"] ?? "") as String,
      title: (map["title"] ?? "") as String,
      amount: (map["amount"] ?? 0) as num,
      amountPaid: (map["amount_paid"] ?? 0) as num,
      dueDate: map["due_date"] == null
          ? null
          : DateTime.tryParse(map["due_date"].toString()),
      status: InvoiceStatus.fromKey(map["status"] as String?),
      createdBy: map["created_by"] as String?,
      studentName: student is Map ? student["full_name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
      items: rawItems is List
          ? rawItems
              .map((e) => InvoiceItem.fromMap(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
        "institute_id": instituteId,
        "student_id": studentId,
        "title": title,
        "amount": amount,
        "amount_paid": amountPaid,
        "due_date": dueDate?.toIso8601String().substring(0, 10),
        "status": status.key,
        "created_by": createdBy,
      };
}
