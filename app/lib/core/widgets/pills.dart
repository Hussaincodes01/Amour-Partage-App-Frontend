import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

/// Small rounded chip ("Live", "Soon", "3 up next").
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.icon, this.color, this.background, this.dot = false});

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  /// Leading status dot in [color].
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.textMuted;
    return DecoratedBox(
      decoration: BoxDecoration(color: background ?? fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[Dot(color: fg, size: 6), const SizedBox(width: 6)],
            if (icon != null) ...[Sym(icon!, size: 13, color: fg, fill: true), const SizedBox(width: 4)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.copyWith(color: fg, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

/// Solid status dot.
class Dot extends StatelessWidget {
  const Dot({super.key, required this.color, this.size = 8, this.border});

  final Color color;
  final double size;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border != null ? Border.all(color: border!, width: 2) : null,
      ),
    );
  }
}
