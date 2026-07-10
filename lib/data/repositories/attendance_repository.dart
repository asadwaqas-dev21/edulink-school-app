import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/domain/entities/attendance_record.dart";
import "package:edulink/domain/entities/timetable_entry.dart";

/// Attendance records and class timetable.
class AttendanceRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  String _dateKey(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<List<AttendanceRecord>> forClassOnDate(
      String classId, DateTime date) async {
    final data = await _client
        .from(SupabaseConfig.tAttendance)
        .select("*, student:student_id(full_name)")
        .eq("class_id", classId)
        .eq("date", _dateKey(date));
    return (data as List).map((e) => AttendanceRecord.fromMap(e)).toList();
  }

  Future<List<AttendanceRecord>> forStudent(String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tAttendance)
        .select()
        .eq("student_id", studentId)
        .order("date", ascending: false);
    return (data as List).map((e) => AttendanceRecord.fromMap(e)).toList();
  }

  /// Upserts a batch of attendance records for a class/date.
  Future<void> saveBatch(List<AttendanceRecord> records) async {
    if (records.isEmpty) return;
    final rows = records.map((r) => r.toMap()).toList();
    await _client
        .from(SupabaseConfig.tAttendance)
        .upsert(rows, onConflict: "class_id,student_id,date");
  }

  // ── Timetable ──
  Future<List<TimetableEntry>> timetable(String classId) async {
    final data = await _client
        .from(SupabaseConfig.tTimetable)
        .select("*, subject:subject_id(name)")
        .eq("class_id", classId)
        .order("day_of_week")
        .order("start_time");
    return (data as List).map((e) => TimetableEntry.fromMap(e)).toList();
  }

  Future<TimetableEntry> addEntry(TimetableEntry e) async {
    final data = await _client
        .from(SupabaseConfig.tTimetable)
        .insert(e.toMap())
        .select("*, subject:subject_id(name)")
        .single();
    return TimetableEntry.fromMap(data);
  }

  Future<void> deleteEntry(String id) async {
    await _client.from(SupabaseConfig.tTimetable).delete().eq("id", id);
  }
}
