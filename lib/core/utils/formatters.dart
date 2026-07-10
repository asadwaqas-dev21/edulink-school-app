import "package:intl/intl.dart";

/// Shared date/currency/text formatting helpers.
abstract class Formatters {
  static final _date = DateFormat("MMM d, yyyy");
  static final _dateTime = DateFormat("MMM d, yyyy • h:mm a");
  static final _time = DateFormat("h:mm a");
  static final _day = DateFormat("EEEE");

  static String date(DateTime? d) => d == null ? "-" : _date.format(d.toLocal());
  static String dateTime(DateTime? d) => d == null ? "-" : _dateTime.format(d.toLocal());
  static String time(DateTime? d) => d == null ? "-" : _time.format(d.toLocal());
  static String dayName(DateTime? d) => d == null ? "-" : _day.format(d.toLocal());

  static String money(num? amount, {String symbol = "Rs ", int decimalDigits = 0}) {
    final f = NumberFormat.currency(
      locale: "en_PK",
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return f.format(amount ?? 0);
  }

  static String initials(String? name) {
    if (name == null || name.trim().isEmpty) return "?";
    final parts = name.trim().split(RegExp(r"\s+"));
    String firstChar(String s) => s.isEmpty ? "" : s.substring(0, 1);
    if (parts.length == 1) return firstChar(parts.first).toUpperCase();
    return (firstChar(parts.first) + firstChar(parts.last)).toUpperCase();
  }
}
