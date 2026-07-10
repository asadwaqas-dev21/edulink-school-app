import "package:get/get.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/data/repositories/auth_repository.dart";
import "package:edulink/domain/entities/profile.dart";

/// Holds the authenticated user's profile for the whole app lifecycle.
class SessionController extends GetxController {
  final AuthRepository authRepository;
  SessionController({required this.authRepository});

  final Rxn<Profile> _profile = Rxn<Profile>();

  Profile? get profile => _profile.value;
  UserRole get role => _profile.value?.role ?? UserRole.student;
  String? get userId => authRepository.currentUserId;
  String? get instituteId => _profile.value?.instituteId;
  bool get isLoggedIn => authRepository.currentSession != null;

  void setProfile(Profile? profile) => _profile.value = profile;

  Future<Profile?> refreshProfile() async {
    final id = authRepository.currentUserId;
    if (id == null) return null;
    final p = await authRepository.fetchProfile(id);
    _profile.value = p;
    return p;
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    _profile.value = null;
  }
}
