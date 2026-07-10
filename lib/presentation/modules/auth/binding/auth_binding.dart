import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/data/repositories/auth_repository.dart";
import "package:edulink/presentation/modules/auth/controller/auth_controller.dart";

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<SessionController>(),
      ),
      fenix: true,
    );
  }
}
