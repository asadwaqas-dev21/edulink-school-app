class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String body;
  final String? senderName;
  final DateTime? readAt;
  final DateTime? createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.body,
    this.senderName,
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  factory Message.fromMap(Map<String, dynamic> map) {
    final sender = map["sender"];
    return Message(
      id: map["id"] as String,
      senderId: (map["sender_id"] ?? "") as String,
      receiverId: (map["receiver_id"] ?? "") as String,
      body: (map["body"] ?? "") as String,
      senderName: sender is Map ? sender["full_name"] as String? : null,
      readAt: map["read_at"] == null
          ? null
          : DateTime.tryParse(map["read_at"].toString()),
      createdAt: map["created_at"] == null
          ? null
          : DateTime.tryParse(map["created_at"].toString()),
    );
  }

  Map<String, dynamic> toMap() => {
        "sender_id": senderId,
        "receiver_id": receiverId,
        "body": body,
      };
}
