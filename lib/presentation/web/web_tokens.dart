import "package:flutter/material.dart";

/// Design tokens for the professional web/desktop dashboard, mirroring the
/// approved HTML prototype (light + dark palettes).
class WebTokens {
  final bool dark;
  const WebTokens(this.dark);

  factory WebTokens.of(BuildContext context) =>
      WebTokens(Theme.of(context).brightness == Brightness.dark);

  Color get bg => dark ? const Color(0xFF0F1420) : const Color(0xFFF4F7FB);
  Color get panel => dark ? const Color(0xFF171D2A) : const Color(0xFFFFFFFF);
  Color get panel2 => dark ? const Color(0xFF121823) : const Color(0xFFF8FAFC);
  Color get ink => dark ? const Color(0xFFEEF2FF) : const Color(0xFF172033);
  Color get muted => dark ? const Color(0xFF95A1B8) : const Color(0xFF718096);
  Color get line => dark ? const Color(0xFF273044) : const Color(0xFFE7ECF3);

  Color get primary => const Color(0xFF5B5CE2);
  Color get primary2 => const Color(0xFF7B7CF0);
  Color get primarySoft =>
      dark ? const Color(0xFF282953) : const Color(0xFFEEEFFF);

  Color get success => const Color(0xFF19A974);
  Color get successSoft =>
      dark ? const Color(0xFF173A31) : const Color(0xFFE8F8F1);
  Color get warning => const Color(0xFFE9A23B);
  Color get warningSoft =>
      dark ? const Color(0xFF3B2F1B) : const Color(0xFFFFF6E6);
  Color get danger => const Color(0xFFE45656);
  Color get dangerSoft =>
      dark ? const Color(0xFF3F2429) : const Color(0xFFFFEDED);
  Color get info => const Color(0xFF3994FF);
  Color get infoSoft => dark ? const Color(0xFF1B3047) : const Color(0xFFEAF4FF);

  LinearGradient get brandGradient => const LinearGradient(
        colors: [Color(0xFF6264ED), Color(0xFF4C4ED1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  BorderRadius get radius => BorderRadius.circular(18);
  BorderRadius get radiusSm => BorderRadius.circular(12);

  List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.16 : 0.06),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Semantic tone used by chips, KPIs and icons.
enum Tone { primary, success, warning, danger, info }

extension ToneColors on Tone {
  Color fg(WebTokens t) {
    switch (this) {
      case Tone.primary:
        return t.primary;
      case Tone.success:
        return t.success;
      case Tone.warning:
        return t.warning;
      case Tone.danger:
        return t.danger;
      case Tone.info:
        return t.info;
    }
  }

  Color bg(WebTokens t) {
    switch (this) {
      case Tone.primary:
        return t.primarySoft;
      case Tone.success:
        return t.successSoft;
      case Tone.warning:
        return t.warningSoft;
      case Tone.danger:
        return t.dangerSoft;
      case Tone.info:
        return t.infoSoft;
    }
  }
}
