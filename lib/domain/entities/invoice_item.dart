/// A single expense line on an invoice / fee slip.
class InvoiceItem {
  final String id;
  final String invoiceId;
  final String description;
  final num quantity;
  final num unitPrice;

  const InvoiceItem({
    this.id = "",
    this.invoiceId = "",
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  num get amount => quantity * unitPrice;

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? description,
    num? quantity,
    num? unitPrice,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: (map["id"] ?? "") as String,
      invoiceId: (map["invoice_id"] ?? "") as String,
      description: (map["description"] ?? "") as String,
      quantity: (map["quantity"] ?? 1) as num,
      unitPrice: (map["unit_price"] ?? 0) as num,
    );
  }

  Map<String, dynamic> toMap() => {
        "invoice_id": invoiceId,
        "description": description,
        "quantity": quantity,
        "unit_price": unitPrice,
        "amount": amount,
      };
}
