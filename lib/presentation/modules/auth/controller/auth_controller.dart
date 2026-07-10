import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/auth_repository.dart";

class AuthController extends GetxController {
  final AuthRepository authRepository;
  final SessionController session;
  AuthController({required this.authRepository, required this.session});

  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final Rx<UserRole> selectedRole = UserRole.student.obs;

  @override
  void onClose() {
    // We intentionally do not call .dispose() on TextEditingControllers here.
    // Since AuthController can be reused by GetX (fenix: true) across rapid route changes,
    // disposing them manually can lead to "A TextEditingController was used after being disposed" crashes.
    super.onClose();
  }

  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final profile = await authRepository.signIn(
        emailController.text.trim(),
        passwordController.text,
      );
      session.setProfile(profile);
      SnackbarUtils.showSuccess("Welcome back, ${profile.fullName}");
      Get.offAllNamed(AppRoutes.shell);
    } catch (e) {
      SnackbarUtils.showError(_clean(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      await authRepository.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: nameController.text.trim(),
        role: selectedRole.value,
      );

      // If email confirmation is disabled, a session already exists.
      if (session.isLoggedIn) {
        final profile = await session.refreshProfile();
        if (profile != null) {
          SnackbarUtils.showSuccess("Account created. Welcome!");
          Get.offAllNamed(AppRoutes.shell);
          return;
        }
      }
      SnackbarUtils.showInfo(
          "Account created. Please check your email to confirm, then sign in.");
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      SnackbarUtils.showError(_clean(e));
    } finally {
      isLoading.value = false;
    }
  }

  String _clean(Object e) =>
      e.toString().replaceFirst("Exception: ", "").trim();
}
