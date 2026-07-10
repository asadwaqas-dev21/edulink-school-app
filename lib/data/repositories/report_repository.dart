import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/enums/status_enums.dart";

/// Aggregated figures for dashboards and reports.
class ReportRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<int> _count(String table, String col, String value) async {
    final data = await _client.from(table).select("id").eq(col, value);
    return (data as List).length;
  }

  Future<Map<String, int>> instituteOverview(String instituteId) async {
    final students = await _count(SupabaseConfig.tProfiles, "institute_id", instituteId);
    // Reuse profiles table filtered by role for granular counts.
    final studentRows = await _client
        .from(SupabaseConfig.tProfiles)
        .select("role")
        .eq("institute_id", instituteId);
    final roleCounts = <String, int>{};
    for (final r in (studentRows as List)) {
      final role = (r["role"] ?? "").toString();
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }
    final classes = await _count(SupabaseConfig.tClasses, "institute_id", instituteId);

    return {
      "people": students,
      "students": roleCounts["student"] ?? 0,
      "teachers": roleCounts["teacher"] ?? 0,
      "parents": roleCounts["parent"] ?? 0,
      "classes": classes,
    };
  }

  Future<Map<String, num>> financeSummary(String instituteId) async {
    final data = await _client
        .from(SupabaseConfig.tInvoices)
        .select("amount, amount_paid, status")
        .eq("institute_id", instituteId);
    num billed = 0;
    num collected = 0;
    int pending = 0;
    for (final row in (data as List)) {
      billed += (row["amount"] ?? 0) as num;
      collected += (row["amount_paid"] ?? 0) as num;
      final status = InvoiceStatus.fromKey(row["status"] as String?);
      if (status != InvoiceStatus.paid && status != InvoiceStatus.cancelled) {
        pending += 1;
      }
    }
    return {
      "billed": billed,
      "collected": collected,
      "outstanding": billed - collected,
      "pendingInvoices": pending,
    };
  }

  /// Attendance percentage for a student across all recorded days.
  Future<double> attendanceRate(String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tAttendance)
        .select("status")
        .eq("student_id", studentId);
    final list = data as List;
    if (list.isEmpty) return 0;
    final present = list
        .where((r) =>
            r["status"] == AttendanceStatus.present.key ||
            r["status"] == AttendanceStatus.late.key)
        .length;
    return present / list.length * 100;
  }
}
