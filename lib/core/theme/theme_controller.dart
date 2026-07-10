import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Controls dark/light mode and persists preference.
class ThemeController extends GetxController {
  static const String _key = "is_dark_mode";

  final _isDarkMode = false.obs;

  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool(_key) ?? false;
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode.value);
    Get.changeThemeMode(themeMode);
  }
}
