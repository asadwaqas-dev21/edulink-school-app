class TimetableEntry {
  final String id;
  final String classId;
  final String? subjectId;
  final int dayOfWeek; // 1 = Monday ... 7 = Sunday
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String? room;
  final String? subjectName;
  final String? teacherName;

  const TimetableEntry({
    required this.id,
    required this.classId,
    this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.subjectName,
    this.teacherName,
  });

  static const List<String> dayNames = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  String get dayLabel =>
      (dayOfWeek >= 1 && dayOfWeek <= 7) ? dayNames[dayOfWeek - 1] : "-";

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    final subject = map["subject"];
    return TimetableEntry(
      id: map["id"] as String,
      classId: (map["class_id"] ?? "") as String,
      subjectId: map["subject_id"] as String?,
      dayOfWeek: (map["day_of_week"] ?? 1) as int,
      startTime: (map["start_time"] ?? "").toString(),
      endTime: (map["end_time"] ?? "").toString(),
      room: map["room"] as String?,
      subjectName: subject is Map ? subject["name"] as String? : null,
    );
  }

  Map<String, dynamic> toMap() => {
        "class_id": classId,
        "subject_id": subjectId,
        "day_of_week": dayOfWeek,
        "start_time": startTime,
        "end_time": endTime,
        "room": room,
      };
}
