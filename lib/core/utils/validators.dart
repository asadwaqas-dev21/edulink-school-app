/// Input validators for forms.
abstract class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return "Email is required";
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$");
    if (!regex.hasMatch(value.trim())) return "Invalid email address";
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  static String? required(String? value, [String fieldName = "Field"]) {
    if (value == null || value.trim().isEmpty) return "$fieldName is required";
    return null;
  }

  static String? number(String? value, [String fieldName = "Field"]) {
    if (value == null || value.trim().isEmpty) return "$fieldName is required";
    if (num.tryParse(value.trim()) == null) return "$fieldName must be a number";
    return null;
  }

  static String? positiveAmount(String? value, [String fieldName = "Amount"]) {
    final numberError = number(value, fieldName);
    if (numberError != null) return numberError;
    if (num.parse(value!.trim()) < 0) return "$fieldName must be positive";
    return null;
  }
}
