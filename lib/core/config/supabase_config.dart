import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/env.dart";

/// Initializes and exposes the Supabase client for the whole app.
abstract class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Table name constants to avoid typos across the data layer.
  static const String tProfiles = "profiles";
  static const String tInstitutes = "institutes";
  static const String tClasses = "classes";
  static const String tSubjects = "subjects";
  static const String tEnrollments = "enrollments";
  static const String tParentLinks = "parent_links";
  static const String tLessons = "lessons";
  static const String tMaterials = "materials";
  static const String tAssignments = "assignments";
  static const String tSubmissions = "submissions";
  static const String tQuizzes = "quizzes";
  static const String tQuizQuestions = "quiz_questions";
  static const String tQuizResults = "quiz_results";
  static const String tAttendance = "attendance";
  static const String tTimetable = "timetable";
  static const String tInvoices = "invoices";
  static const String tInvoiceItems = "invoice_items";
  static const String tPayments = "payments";
  static const String tExpenses = "expenses";
  static const String tAnnouncements = "announcements";
  static const String tMessages = "messages";

  /// Storage bucket names.
  static const String bucketMaterials = "materials";
  static const String bucketSubmissions = "submissions";
  static const String bucketAvatars = "avatars";
}
