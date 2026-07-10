import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/domain/entities/profile.dart";

/// Handles authentication and the current user's profile via Supabase.
class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<Profile> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final userId = res.user?.id;
    if (userId == null) {
      throw Exception("Sign in failed. Please try again.");
    }
    final profile = await fetchProfile(userId);
    if (profile == null) {
      throw Exception("No profile found for this account.");
    }
    return profile;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        "full_name": fullName.trim(),
        "role": role.key,
      },
    );
  }

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .select()
        .eq("id", userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .update(profile.toMap())
        .eq("id", profile.id)
        .select()
        .single();
    return Profile.fromMap(data);
  }

  Future<void> signOut() => _client.auth.signOut();
}
