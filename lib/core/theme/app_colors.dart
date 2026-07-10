import "package:flutter/material.dart";

/// Custom color palette based on Kurchu logo.
///
/// The primary/brand family is intentionally NOT `const`: it can be re-skinned
/// at runtime via [applyPrimary] so a user-chosen accent color flows through the
/// whole app (mobile + web). All references stay `AppColors.primary`, etc.
abstract class AppColors {
  /// Default brand color, used when no preference is stored.
  static const Color defaultPrimary = Color(0xFF1BA4DF);

  // Primary (dynamic — see [applyPrimary])
  static Color primary = defaultPrimary;
  static Color primaryLight = const Color(0xFF4FC1F0);
  static Color primaryDark = const Color(0xFF107AAB);
  static Color primarySurface = const Color(0xFFE4F5FD);

  /// Re-skins the primary family from a single [base] color, deriving the
  /// light / dark / surface variants so the whole palette stays coherent.
  static void applyPrimary(Color base) {
    primary = base;
    primaryLight = _lighten(base, 0.12);
    primaryDark = _darken(base, 0.16);
    primarySurface = Color.lerp(base, Colors.white, 0.88)!;
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  // Accent (Steel Blue)
  static const Color accent = Color(0xFF397BB0);
  static const Color accentLight = Color(0xFF629AC9);
  static const Color accentDark = Color(0xFF24537A);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2563EB);

  // Neutral - Light Mode
  static const Color backgroundLight = Color(0xFFF6F7FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE7E9F2);
  static const Color textPrimaryLight = Color(0xFF15182B);
  static const Color textSecondaryLight = Color(0xFF667085);
  static const Color textTertiaryLight = Color(0xFFA5ACC0);

  // Neutral - Dark Mode
  static const Color backgroundDark = Color(0xFF0B0D1A);
  static const Color surfaceDark = Color(0xFF141728);
  static const Color cardDark = Color(0xFF1C2036);
  static const Color dividerDark = Color(0xFF2C3150);
  static const Color textPrimaryDark = Color(0xFFF6F7FB);
  static const Color textSecondaryDark = Color(0xFFA5ACC0);
  static const Color textTertiaryDark = Color(0xFF667085);

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Role accent colors used across dashboards.
  static const Color roleStudent = Color(0xFF1BA4DF);
  static const Color roleTeacher = Color(0xFF397BB0);
  static const Color roleParent = Color(0xFFF59E0B);
  static const Color rolePrincipal = Color(0xFF7C3AED);

  static Color roleColor(String roleKey) {
    switch (roleKey) {
      case "student":
        return roleStudent;
      case "teacher":
        return roleTeacher;
      case "parent":
        return roleParent;
      case "principal":
        return rolePrincipal;
      default:
        return primary;
    }
  }
}
