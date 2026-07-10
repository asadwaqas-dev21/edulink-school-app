import "package:edulink/core/enums/status_enums.dart";

class Institute {
  final String id;
  final String name;
  final InstituteType type;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? principalId;
  final DateTime? createdAt;

  const Institute({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.principalId,
    this.createdAt,
  });

  factory Institute.fromMap(Map<String, dynamic> map) {
    return Institute(
      id: map["id"] as String,
      name: (map["name"] ?? "") as String,
      type: InstituteType.fromKey(map["type"] as String?),
      address: map["address"] as String?,
      phone: map["phone"] as String?,
      email: map["email"] as String?,
      logoUrl: map["logo_url"] as String?,
      principalId: map["principal_id"] as String?,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "type": type.key,
        "address": address,
        "phone": phone,
        "email": email,
        "logo_url": logoUrl,
        "principal_id": principalId,
      };
}
