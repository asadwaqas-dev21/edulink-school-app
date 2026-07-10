class Announcement {
  final String id;
  final String instituteId;
  final String? classId;
  final String title;
  final String body;
  final String? authorId;
  final String audience; // all | students | parents | teachers | class
  final String? authorName;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.instituteId,
    this.classId,
    required this.title,
    required this.body,
    this.authorId,
    this.audience = "all",
    this.authorName,
    this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    final author = map["author"];
    return Announcement(
      id: map["id"] as String,
      instituteId: (map["institute_id"] ?? "") as String,
      classId: map["class_id"] as String?,
      title: (map["title"] ?? "") as String,
      body: (map["body"] ?? "") as String,
      authorId: map["author_id"] as String?,
      audience: (map["audience"] ?? "all") as String,
      authorName: author is Map ? author["full_name"] as String? : null,
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "institute_id": instituteId,
        "class_id": classId,
        "title": title,
        "body": body,
        "author_id": authorId,
        "audience": audience,
      };
}
