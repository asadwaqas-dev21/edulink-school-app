import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/core/theme/app_colors.dart";

/// Utility class for showing styled snackbars.
abstract class SnackbarUtils {
  static void _show(String message, Color color, IconData icon, int seconds) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.rawSnackbar(
      message: message,
      backgroundColor: color,
      snackPosition: SnackPosition.TOP,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: Icon(icon, color: Colors.white),
      duration: Duration(seconds: seconds),
      snackStyle: SnackStyle.FLOATING,
      isDismissible: true,
    );
  }

  static void showSuccess(String message) =>
      _show(message, AppColors.success, Iconsax.tick_circle, 2);

  static void showError(String message) =>
      _show(message, AppColors.error, Iconsax.close_circle, 3);

  static void showWarning(String message) =>
      _show(message, AppColors.warning, Iconsax.warning_2, 3);

  static void showInfo(String message) =>
      _show(message, AppColors.info, Iconsax.info_circle, 2);
}
