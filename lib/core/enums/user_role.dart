import "package:iconsax/iconsax.dart";

/// The four LMS roles supported by Edulink.
enum UserRole {
  principal("Principal", "principal", Iconsax.crown_1),
  teacher("Teacher", "teacher", Iconsax.teacher),
  student("Student", "student", Iconsax.book_1),
  parent("Parent", "parent", Iconsax.people);

  final String label;
  final String key;
  final dynamic icon;

  const UserRole(this.label, this.key, this.icon);

  static UserRole fromKey(String? key) {
    return UserRole.values.firstWhere(
      (e) => e.key == key,
      orElse: () => UserRole.student,
    );
  }

  bool get isPrincipal => this == UserRole.principal;
  bool get isTeacher => this == UserRole.teacher;
  bool get isStudent => this == UserRole.student;
  bool get isParent => this == UserRole.parent;

  // Capability helpers used to gate UI and actions.
  bool get canManageInstitute => isPrincipal;
  bool get canManageClasses => isPrincipal;
  bool get canManagePeople => isPrincipal;
  bool get canTeach => isPrincipal || isTeacher;
  bool get canGrade => isPrincipal || isTeacher;
  bool get canMarkAttendance => isPrincipal || isTeacher;
  bool get canManageFinance => isPrincipal;
  bool get canPayFees => isParent || isPrincipal;
  bool get canBroadcast => isPrincipal || isTeacher;

  /// Parents get a dedicated view of their linked children (subjects,
  /// performance and fees) instead of the institute-wide admin views.
  bool get canViewChildren => isParent;
}
