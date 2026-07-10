import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/theme/app_theme.dart";

/// A selectable brand color option shown in Settings.
class ThemeColorOption {
  final String name;
  final Color color;
  const ThemeColorOption(this.name, this.color);
}

/// Controls dark/light mode, the brand/accent color and the typography, and
/// persists all three so the whole app follows the user's choice.
class ThemeController extends GetxController {
  static const String _darkKey = "is_dark_mode";
  static const String _colorKey = "primary_color";
  static const String _fontKey = "font_family";

  /// Accent colors offered in Settings.
  static const List<ThemeColorOption> colorOptions = [
    ThemeColorOption("Ocean", AppColors.defaultPrimary),
    ThemeColorOption("Indigo", Color(0xFF5B5CE2)),
    ThemeColorOption("Violet", Color(0xFF7C3AED)),
    ThemeColorOption("Emerald", Color(0xFF16A34A)),
    ThemeColorOption("Teal", Color(0xFF0F766E)),
    ThemeColorOption("Amber", Color(0xFFE9A23B)),
    ThemeColorOption("Rose", Color(0xFFE11D63)),
    ThemeColorOption("Slate", Color(0xFF475569)),
  ];

  /// Typography options (all valid Google Fonts families).
  static const List<String> fontOptions = [
    "Inter",
    "Roboto",
    "Poppins",
    "Lato",
    "Nunito",
    "Montserrat",
    "Work Sans",
    "Merriweather",
  ];

  final _isDarkMode = false.obs;
  final _primary = Rx<Color>(AppColors.defaultPrimary);
  final _font = "Inter".obs;

  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  Color get primaryColor => _primary.value;
  String get fontFamily => _font.value;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool(_darkKey) ?? false;

    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) {
      _primary.value = Color(colorValue);
    }
    final font = prefs.getString(_fontKey);
    if (font != null && fontOptions.contains(font)) {
      _font.value = font;
    }

    // Apply the stored preferences to the global palette / typography, then
    // rebuild so they take effect on a cold start.
    AppColors.applyPrimary(_primary.value);
    AppTheme.fontKey = _font.value;
    _rebuild();
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, _isDarkMode.value);
    Get.changeThemeMode(themeMode);
    _rebuild();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primary.value = color;
    AppColors.applyPrimary(color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.toARGB32());
    _rebuild();
  }

  Future<void> setFont(String font) async {
    if (!fontOptions.contains(font)) return;
    _font.value = font;
    AppTheme.fontKey = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font);
    _rebuild();
  }

  /// Rebuilds the root [GetMaterialApp] (new ThemeData: colors + font) and then
  /// forces every already-built page to repaint so widgets that read
  /// `AppColors.*` / `WebTokens` directly also pick up the new palette.
  void _rebuild() {
    update();
    Get.forceAppUpdate();
  }
}
