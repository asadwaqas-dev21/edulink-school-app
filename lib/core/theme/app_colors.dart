import "package:flutter/material.dart";

/// Indigo & Teal color palette for Edulink LMS.
abstract class AppColors {
  // Primary (Indigo)
  static const Color primary = Color(0xFF3538CD);
  static const Color primaryLight = Color(0xFF5D5FEF);
  static const Color primaryDark = Color(0xFF2426A0);
  static const Color primarySurface = Color(0xFFEEF0FF);

  // Accent (Teal)
  static const Color accent = Color(0xFF12B5A5);
  static const Color accentLight = Color(0xFF3ED0C1);
  static const Color accentDark = Color(0xFF0C877B);

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

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Role accent colors used across dashboards.
  static const Color roleStudent = Color(0xFF3538CD);
  static const Color roleTeacher = Color(0xFF12B5A5);
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
