import "package:flutter/material.dart";
import "package:edulink/presentation/web/web_tokens.dart";

/// A surface card matching the prototype (.card).
class WebCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  const WebCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final card = Container(
      clipBehavior: clipBehavior,
      padding: padding,
      decoration: BoxDecoration(
        color: t.panel,
        border: Border.all(color: t.line),
        borderRadius: t.radius,
        boxShadow: t.shadowSm,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

/// Section header with a title, optional subtitle and trailing widget.
class SectionHead extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHead({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: t.ink, fontSize: 14.5, fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: TextStyle(color: t.muted, fontSize: 11)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Small link-style button ("View all", "Details").
class MoreButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const MoreButton(this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: t.primary,
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}

/// KPI stat card.
class Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Tone tone;
  final String? trend;
  final bool trendDown;
  final String? foot;
  const Kpi({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tone = Tone.primary,
    this.trend,
    this.trendDown = false,
    this.foot,
  });

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return WebCard(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: tone.bg(t), borderRadius: BorderRadius.circular(40)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              color: t.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: tone.bg(t),
                          borderRadius: BorderRadius.circular(11)),
                      child: Icon(icon, size: 18, color: tone.fg(t)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(value,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (trend != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: (trendDown ? t.danger : t.success)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(trend!,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: trendDown ? t.danger : t.success)),
                      ),
                    if (trend != null && foot != null) const SizedBox(width: 7),
                    if (foot != null)
                      Flexible(
                        child: Text(foot!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: t.muted, fontSize: 10)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A colored status pill.
class StatusChip extends StatelessWidget {
  final String label;
  final Tone tone;
  const StatusChip(this.label, {super.key, this.tone = Tone.primary});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: tone.bg(t), borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: tone.fg(t), fontSize: 9.5, fontWeight: FontWeight.w800)),
    );
  }
}

enum WebBtnKind { primary, plain, success, danger, secondary }

/// Prototype button (.btn / .btn.primary / .btn.success).
class WebButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final WebBtnKind kind;
  final VoidCallback? onTap;
  const WebButton(
      {super.key,
      required this.label,
      this.icon,
      this.kind = WebBtnKind.plain,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final bool filled = kind != WebBtnKind.plain && kind != WebBtnKind.secondary;
    Color base = t.primary;
    if (kind == WebBtnKind.success) base = t.success;
    if (kind == WebBtnKind.danger) base = t.danger;
    return Material(
      color: filled ? base : t.panel,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 39,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: filled ? null : Border.all(color: t.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 15, color: filled ? Colors.white : t.ink),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : t.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular/rounded monogram avatar.
class Monogram extends StatelessWidget {
  final String text;
  final Tone tone;
  final double size;
  final double radius;
  const Monogram(this.text,
      {super.key, this.tone = Tone.primary, this.size = 33, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: tone.bg(t), borderRadius: BorderRadius.circular(radius)),
      child: Text(text,
          style: TextStyle(
              color: tone.fg(t),
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800)),
    );
  }
}

/// A lightweight table matching the prototype's .data-table.
class WebTable extends StatelessWidget {
  final List<WebCol> columns;
  final List<List<Widget>> rows;
  const WebTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    final totalFlex = columns.fold<int>(0, (s, c) => s + c.flex);
    final minWidth = (totalFlex * 90).toDouble();

    Widget headerCell(WebCol c) => Expanded(
          flex: c.flex,
          child: Align(
            alignment: c.right ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(c.label.toUpperCase(),
                style: TextStyle(
                    color: t.muted,
                    fontSize: 9,
                    letterSpacing: 0.65,
                    fontWeight: FontWeight.w800)),
          ),
        );

    return LayoutBuilder(builder: (context, c) {
      final content = ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: t.panel2,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(children: columns.map(headerCell).toList()),
            ),
            for (int i = 0; i < rows.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: i == rows.length - 1
                            ? Colors.transparent
                            : t.line),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                child: Row(
                  children: [
                    for (int j = 0; j < columns.length; j++)
                      Expanded(
                        flex: columns[j].flex,
                        child: Align(
                          alignment: columns[j].right
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: DefaultTextStyle.merge(
                            style: TextStyle(color: t.ink, fontSize: 11),
                            child: rows[i][j],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
      if (c.maxWidth >= minWidth) return content;
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal, child: SizedBox(width: minWidth, child: content));
    });
  }
}

class WebCol {
  final String label;
  final int flex;
  final bool right;
  const WebCol(this.label, {this.flex = 1, this.right = false});
}

/// Scrollable, padded, max-width page body used by every web page.
class WebPageBody extends StatelessWidget {
  final List<Widget> children;
  const WebPageBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Page header (big title + subtitle) with optional trailing actions.
class WebPageHead extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  const WebPageHead(
      {super.key,
      required this.title,
      required this.subtitle,
      this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: t.muted, fontSize: 11.5)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Small square icon action used inside tables.
class TableAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const TableAction(this.icon, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Material(
      color: t.panel,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.line),
          ),
          child: Icon(icon, size: 15, color: t.muted),
        ),
      ),
    );
  }
}

/// Horizontal progress bar row (label + value + track).
class HBar extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Tone tone;
  const HBar(
      {super.key,
      required this.label,
      required this.value,
      required this.fraction,
      this.tone = Tone.primary});

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: t.ink, fontSize: 11)),
            Text(value,
                style: TextStyle(
                    color: t.ink, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 7,
            color: t.panel2,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0, 1),
              child: Container(color: tone.fg(t)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Responsive grid that lays children into [columns] equal-width tracks.
///
/// Uses a width-computed [Wrap] so each cell sizes to its natural height,
/// avoiding vertical overflow from fixed aspect ratios. [childAspectRatio]
/// and [shrinkWrap] are kept for call-site compatibility and ignored.
class WebGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final double childAspectRatio;
  final List<Widget> children;
  final bool shrinkWrap;
  const WebGrid({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 17,
    this.childAspectRatio = 1.6,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = columns < 1 ? 1 : columns;
      final totalGap = gap * (cols - 1);
      final available = c.maxWidth.isFinite ? c.maxWidth : 0.0;
      final itemWidth = ((available - totalGap) / cols).floorToDouble();
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children)
            SizedBox(width: itemWidth > 0 ? itemWidth : null, child: child),
        ],
      );
    });
  }
}
