import "dart:convert";

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

  /// Creates a brand-new account on behalf of a principal (e.g. adding a
  /// teacher/student/parent manually).
  ///
  /// `auth.signUp` signs the newly-created user in on the shared client, which
  /// would otherwise replace (and persist) the principal's session — so after a
  /// restart they'd be logged in as the new member. To avoid that, we snapshot
  /// the principal's session beforehand and restore it immediately afterwards.
  ///
  /// Returns the new user's id. A database trigger creates the matching
  /// `profiles` row from the metadata below.
  Future<String> createMemberAccount({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    final callerSession = _client.auth.currentSession;

    String? newUserId;
    Object? signUpError;
    try {
      final res = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          "full_name": fullName.trim(),
          "role": role.key,
        },
      );
      newUserId = res.user?.id;
    } catch (e) {
      signUpError = e;
    }

    // Restore the principal's session if signUp replaced it (happens when email
    // confirmation is disabled). recoverSession re-applies the saved session
    // locally without a network round-trip while it is still valid, so it can't
    // silently fail and leave the principal signed in as the new member.
    if (callerSession != null &&
        _client.auth.currentSession?.accessToken != callerSession.accessToken) {
      try {
        await _client.auth.recoverSession(jsonEncode(callerSession.toJson()));
      } catch (_) {
        // Fall back to a refresh-token based restore.
        try {
          await _client.auth.setSession(callerSession.refreshToken ?? "");
        } catch (_) {
          // Best effort — if this fails the caller may need to sign in again.
        }
      }
    }

    if (signUpError != null) {
      throw Exception(
          "Could not create the account. The email may already be in use.");
    }
    if (newUserId == null) {
      throw Exception("Could not create the account. Please try again.");
    }
    return newUserId;
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
