import "package:flutter/material.dart";
import "package:edulink/app/app.dart";
import "package:edulink/core/config/env.dart";
import "package:edulink/core/config/supabase_config.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.isConfigured) {
    try {
      await SupabaseConfig.initialize();
    } catch (e) {
      debugPrint("Supabase initialization failed: $e");
    }
  } else {
    debugPrint(
      "Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY "
      "in lib/core/config/env.dart or via --dart-define.",
    );
  }
  runApp(const App());
}
