import "package:get/get.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/app/session/session_controller.dart";

class ShellController extends GetxController {
  final SessionController session;
  ShellController({required this.session});

  final RxInt index = 0.obs;

  void setIndex(int i) => index.value = i;

  Future<void> logout() async {
    await session.signOut();
    Get.offAllNamed(AppRoutes.login);
  }
}
