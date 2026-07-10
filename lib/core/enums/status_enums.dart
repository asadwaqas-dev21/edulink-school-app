/// Attendance state for a student on a given day.
enum AttendanceStatus {
  present("Present", "present"),
  absent("Absent", "absent"),
  late("Late", "late"),
  excused("Excused", "excused");

  final String label;
  final String key;
  const AttendanceStatus(this.label, this.key);

  static AttendanceStatus fromKey(String? key) => AttendanceStatus.values
      .firstWhere((e) => e.key == key, orElse: () => AttendanceStatus.present);
}

/// Lifecycle of an invoice.
enum InvoiceStatus {
  pending("Pending", "pending"),
  partial("Partially Paid", "partial"),
  paid("Paid", "paid"),
  overdue("Overdue", "overdue"),
  cancelled("Cancelled", "cancelled");

  final String label;
  final String key;
  const InvoiceStatus(this.label, this.key);

  static InvoiceStatus fromKey(String? key) => InvoiceStatus.values
      .firstWhere((e) => e.key == key, orElse: () => InvoiceStatus.pending);
}

/// State of an assignment submission.
enum SubmissionStatus {
  submitted("Submitted", "submitted"),
  graded("Graded", "graded"),
  returned("Returned", "returned"),
  late("Late", "late");

  final String label;
  final String key;
  const SubmissionStatus(this.label, this.key);

  static SubmissionStatus fromKey(String? key) => SubmissionStatus.values
      .firstWhere((e) => e.key == key, orElse: () => SubmissionStatus.submitted);
}

/// Category of an institute expense (for the admin finance module).
enum ExpenseCategory {
  teacherSalary("Teacher Salary", "teacher_salary"),
  staffSalary("Staff Salary", "staff_salary"),
  rent("Building Rent", "rent"),
  utilities("Utilities", "utilities"),
  supplies("Supplies", "supplies"),
  maintenance("Maintenance", "maintenance"),
  transport("Transport", "transport"),
  other("Other", "other");

  final String label;
  final String key;
  const ExpenseCategory(this.label, this.key);

  static ExpenseCategory fromKey(String? key) => ExpenseCategory.values
      .firstWhere((e) => e.key == key, orElse: () => ExpenseCategory.other);
}

/// Whether an expense has been paid out or is still pending.
enum ExpenseStatus {
  paid("Paid", "paid"),
  pending("Pending", "pending");

  final String label;
  final String key;
  const ExpenseStatus(this.label, this.key);

  static ExpenseStatus fromKey(String? key) => ExpenseStatus.values
      .firstWhere((e) => e.key == key, orElse: () => ExpenseStatus.paid);
}

/// Institute type.
enum InstituteType {
  school("School", "school"),
  college("College", "college"),
  university("University", "university"),
  academy("Academy", "academy");

  final String label;
  final String key;
  const InstituteType(this.label, this.key);

  static InstituteType fromKey(String? key) => InstituteType.values
      .firstWhere((e) => e.key == key, orElse: () => InstituteType.school);
}
