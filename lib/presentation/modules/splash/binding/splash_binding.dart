import "package:get/get.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/presentation/modules/splash/controller/splash_controller.dart";

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController(session: Get.find<SessionController>()));
  }
}
