import "package:edulink/core/enums/user_role.dart";

class Profile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? instituteId;
  final String? avatarUrl;
  final String? phone;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.instituteId,
    this.avatarUrl,
    this.phone,
    this.createdAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map["id"] as String,
      email: (map["email"] ?? "") as String,
      fullName: (map["full_name"] ?? "") as String,
      role: UserRole.fromKey(map["role"] as String?),
      instituteId: map["institute_id"] as String?,
      avatarUrl: map["avatar_url"] as String?,
      phone: map["phone"] as String?,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "email": email,
        "full_name": fullName,
        "role": role.key,
        "institute_id": instituteId,
        "avatar_url": avatarUrl,
        "phone": phone,
      };

  Profile copyWith({
    String? fullName,
    String? instituteId,
    String? avatarUrl,
    String? phone,
    UserRole? role,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      instituteId: instituteId ?? this.instituteId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }
}
