class ParentLink {
  final String id;
  final String parentId;
  final String studentId;
  final String? relation;
  final String? parentName;
  final String? studentName;
  final DateTime? createdAt;

  const ParentLink({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.relation,
    this.parentName,
    this.studentName,
    this.createdAt,
  });

  factory ParentLink.fromMap(Map<String, dynamic> map) {
    final parent = map["parent"];
    final student = map["student"];
    return ParentLink(
      id: map["id"] as String,
      parentId: (map["parent_id"] ?? "") as String,
      studentId: (map["student_id"] ?? "") as String,
      relation: map["relation"] as String?,
      parentName: parent is Map ? parent["full_name"] as String? : null,
      studentName: student is Map ? student["full_name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "parent_id": parentId,
        "student_id": studentId,
        "relation": relation,
      };
}
