import "package:get/get.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/presentation/modules/auth/binding/auth_binding.dart";
import "package:edulink/presentation/modules/auth/view/login_screen.dart";
import "package:edulink/presentation/modules/auth/view/register_screen.dart";
import "package:edulink/presentation/modules/shell/binding/shell_binding.dart";
import "package:edulink/presentation/modules/shell/view/shell_screen.dart";
import "package:edulink/presentation/modules/splash/binding/splash_binding.dart";
import "package:edulink/presentation/modules/splash/view/splash_screen.dart";

abstract class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.shell,
      page: () => const ShellScreen(),
      binding: ShellBinding(),
    ),
  ];
}
