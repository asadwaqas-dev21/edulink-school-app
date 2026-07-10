import "package:get/get.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/config/env.dart";
import "package:edulink/core/utils/snackbar_utils.dart";

class SplashController extends GetxController {
  final SessionController session;
  SplashController({required this.session});

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (!Env.isConfigured) {
      SnackbarUtils.showWarning(
          "Supabase not configured. Add your keys in env.dart.");
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    // Wait for the initial auth state to be emitted to ensure local session is restored
    final authEvent = await session.authRepository.authChanges.first;
    
    if (authEvent.session != null || session.isLoggedIn) {
      try {
        final profile = await session.refreshProfile();
        if (profile != null) {
          Get.offAllNamed(AppRoutes.shell);
          return;
        }
      } catch (e) {
        // If there is a network error fetching the profile but the user has a session,
        // we should let them proceed to the shell rather than logging them out.
        Get.offAllNamed(AppRoutes.shell);
        return;
      }
    }
    Get.offAllNamed(AppRoutes.login);
  }
}
