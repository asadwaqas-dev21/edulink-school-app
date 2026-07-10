import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:edulink/app/bindings/app_binding.dart";
import "package:edulink/app/routes/app_pages.dart";
import "package:edulink/app/routes/app_routes.dart";
import "package:edulink/core/theme/app_theme.dart";
import "package:edulink/core/theme/theme_controller.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      init: ThemeController(),
      builder: (themeController) {
        return GetMaterialApp(
          title: "Edulink",
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.themeMode,
          initialBinding: AppBinding(),
          initialRoute: AppRoutes.splash,
          getPages: AppPages.pages,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
