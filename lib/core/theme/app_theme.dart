import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_fonts/google_fonts.dart";
import "package:edulink/core/theme/app_colors.dart";

/// Complete Material 3 theme data for light and dark modes.
abstract class AppTheme {
  /// Active Google Font family. Changed at runtime by the ThemeController so
  /// typography flows through the whole app. Must be a valid Google Fonts name.
  static String fontKey = "Inter";

  static TextStyle _font({double? fontSize, FontWeight? fontWeight, Color? color}) =>
      GoogleFonts.getFont(fontKey,
          fontSize: fontSize, fontWeight: fontWeight, color: color);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          primaryContainer: AppColors.primarySurface,
          secondary: AppColors.accent,
          secondaryContainer: Color(0xFFD4F6F1),
          surface: AppColors.surfaceLight,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimaryLight,
          onError: Colors.white,
          outline: AppColors.dividerLight,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimaryLight),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: _font(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardLight,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.dividerLight, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: _inputTheme(
          fill: AppColors.surfaceLight,
          border: AppColors.dividerLight,
          focus: AppColors.primary,
          hint: AppColors.textTertiaryLight,
        ),
        elevatedButtonTheme: _elevatedButtonTheme(AppColors.primary),
        outlinedButtonTheme: _outlinedButtonTheme(AppColors.primary),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
        navigationBarTheme: _navBarTheme(AppColors.surfaceLight, AppColors.textTertiaryLight),
        navigationRailTheme: _navRailTheme(AppColors.surfaceLight, AppColors.textSecondaryLight),
        dividerTheme: const DividerThemeData(
          color: AppColors.dividerLight,
          thickness: 1,
          space: 0,
        ),
        chipTheme: _chipTheme(AppColors.primarySurface, AppColors.textSecondaryLight),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryLight,
          primaryContainer: Color(0xFF2A2D66),
          secondary: AppColors.accent,
          secondaryContainer: Color(0xFF0A3D38),
          surface: AppColors.surfaceDark,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimaryDark,
          onError: Colors.white,
          outline: AppColors.dividerDark,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimaryDark),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: _font(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryDark,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.dividerDark, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: _inputTheme(
          fill: AppColors.cardDark,
          border: AppColors.dividerDark,
          focus: AppColors.primaryLight,
          hint: AppColors.textTertiaryDark,
        ),
        elevatedButtonTheme: _elevatedButtonTheme(AppColors.primaryLight),
        outlinedButtonTheme: _outlinedButtonTheme(AppColors.primaryLight),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
        navigationBarTheme: _navBarTheme(AppColors.surfaceDark, AppColors.textTertiaryDark),
        navigationRailTheme: _navRailTheme(AppColors.surfaceDark, AppColors.textSecondaryDark),
        dividerTheme: const DividerThemeData(
          color: AppColors.dividerDark,
          thickness: 1,
          space: 0,
        ),
        chipTheme: _chipTheme(AppColors.cardDark, AppColors.textSecondaryDark),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color focus,
    required Color hint,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: _font(color: hint, fontSize: 14),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(Color bg) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _font(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(Color color) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static NavigationBarThemeData _navBarTheme(Color bg, Color unselected) {
    return NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: AppColors.primarySurface,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return _font(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppColors.primary : unselected,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.primary : unselected);
      }),
    );
  }

  static NavigationRailThemeData _navRailTheme(Color bg, Color unselected) {
    return NavigationRailThemeData(
      backgroundColor: bg,
      indicatorColor: AppColors.primarySurface,
      labelType: NavigationRailLabelType.all,
      selectedLabelTextStyle:
          _font(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
      unselectedLabelTextStyle:
          _font(fontSize: 12, fontWeight: FontWeight.w500, color: unselected),
      selectedIconTheme: IconThemeData(color: AppColors.primary),
      unselectedIconTheme: IconThemeData(color: unselected),
    );
  }

  static ChipThemeData _chipTheme(Color bg, Color label) {
    return ChipThemeData(
      backgroundColor: bg,
      selectedColor: AppColors.primary,
      labelStyle: _font(fontSize: 12, fontWeight: FontWeight.w500, color: label),
      secondaryLabelStyle:
          _font(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
  }

  static TextTheme _buildTextTheme(Color c) {
    return TextTheme(
      displayLarge: _font(fontSize: 32, fontWeight: FontWeight.w800, color: c),
      displayMedium: _font(fontSize: 28, fontWeight: FontWeight.w700, color: c),
      headlineLarge: _font(fontSize: 24, fontWeight: FontWeight.w700, color: c),
      headlineMedium: _font(fontSize: 20, fontWeight: FontWeight.w600, color: c),
      headlineSmall: _font(fontSize: 18, fontWeight: FontWeight.w600, color: c),
      titleLarge: _font(fontSize: 16, fontWeight: FontWeight.w600, color: c),
      titleMedium: _font(fontSize: 14, fontWeight: FontWeight.w600, color: c),
      titleSmall: _font(fontSize: 13, fontWeight: FontWeight.w500, color: c),
      bodyLarge: _font(fontSize: 16, fontWeight: FontWeight.w400, color: c),
      bodyMedium: _font(fontSize: 14, fontWeight: FontWeight.w400, color: c),
      bodySmall: _font(fontSize: 12, fontWeight: FontWeight.w400, color: c),
      labelLarge: _font(fontSize: 14, fontWeight: FontWeight.w500, color: c),
      labelMedium: _font(fontSize: 12, fontWeight: FontWeight.w500, color: c),
      labelSmall: _font(fontSize: 10, fontWeight: FontWeight.w500, color: c),
    );
  }
}
