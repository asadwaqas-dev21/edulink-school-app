/// Environment configuration for Supabase.
///
/// Replace these values with your Supabase project's URL and anon key.
/// You can find them in your Supabase dashboard under:
///   Project Settings -> API
///
/// For production, prefer passing these via --dart-define:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract class Env {
  static const String supabaseUrl = String.fromEnvironment(
    "SUPABASE_URL",
    defaultValue: "https://tzecaoufpgntiubtmaqh.supabase.co",
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    "SUPABASE_ANON_KEY",
    defaultValue: "sb_publishable_y045ZgfkPdrwdCNKPjXJng_FlyYbsJQ",
  );

  static bool get isConfigured =>
      !supabaseUrl.contains("YOUR_PROJECT_REF") &&
      !supabaseAnonKey.contains("YOUR_SUPABASE_ANON_KEY");
}
