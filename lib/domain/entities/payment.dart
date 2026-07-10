class Payment {
  final String id;
  final String invoiceId;
  final num amount;
  final String? method;
  final String? reference;
  final String? recordedBy;
  final DateTime? paidAt;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.amount,
    this.method,
    this.reference,
    this.recordedBy,
    this.paidAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map["id"] as String,
      invoiceId: (map["invoice_id"] ?? "") as String,
      amount: (map["amount"] ?? 0) as num,
      method: map["method"] as String?,
      reference: map["reference"] as String?,
      recordedBy: map["recorded_by"] as String?,
      paidAt: map["paid_at"] == null
          ? null
          : DateTime.tryParse(map["paid_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "invoice_id": invoiceId,
        "amount": amount,
        "method": method,
        "reference": reference,
        "recorded_by": recordedBy,
      };
}
