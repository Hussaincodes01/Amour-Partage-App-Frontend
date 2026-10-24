import 'package:flutter/widgets.dart';

import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

/// Small rounded label chip (e.g. "Dual E2EE", "Live Stream", "3 Up Next").
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    this.icon,
    this.dot,
    this.color = AppColors.onSurfaceVariant,
    this.background,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    this.style,
    this.iconSize = 10,
    this.gap = 4,
    this.border,
    this.glow,
    this.trailingDot,
  });

  final String label;
  final IconData? icon;
  final Widget? dot;
  final Color color;
  final Color? background;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;
  final double iconSize;
  final double gap;
  final BoxBorder? border;
  final Color? glow;
  final Color? trailingDot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: border,
        boxShadow: glow != null ? [BoxShadow(color: glow!, blurRadius: 12)] : null,
      ),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[dot!, SizedBox(width: gap + 2)],
            if (icon != null) ...[Sym(icon!, size: iconSize, color: color, fill: true), SizedBox(width: gap)],
            Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: (style ?? AppText.label).copyWith(color: color))),
            if (trailingDot != null) ...[
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(color: trailingDot, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Solid glowing dot.
class Dot extends StatelessWidget {
  const Dot({super.key, required this.color, this.size = 8, this.glow = false});

  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow ? [BoxShadow(color: color, blurRadius: size)] : null,
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}

/// Icon + label action pill ("Send Spark", "Heartbeat", "Paris"...).
class ActionPill extends StatelessWidget {
  const ActionPill({
    super.key,
    required this.label,
    this.icon,
    this.iconColor = AppColors.primary,
    this.onTap,
    this.background,
    this.labelStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.iconSize = 14,
    this.height,
    this.expand = false,
    this.emoji,
    this.border,
    this.gradient,
    this.shadow,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final String? emoji;
  final Color iconColor;
  final VoidCallback? onTap;
  final Color? background;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final double? height;
  final bool expand;
  final BoxBorder? border;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Sym(icon!, size: iconSize, color: iconColor, fill: true), const SizedBox(width: 6)],
        if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 12, height: 16 / 12)), const SizedBox(width: 4)],
        Flexible(
          child: expand
              ? FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: labelStyle ?? AppText.label.copyWith(color: AppColors.onSurface)))
              : Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle ?? AppText.label.copyWith(color: AppColors.onSurface)),
        ),
        if (trailing != null) ...[const SizedBox(width: 6), trailing!],
      ],
    );
    return Pressable(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? (background ?? AppColors.raised(0.8)) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(999),
          border: border,
          boxShadow: shadow,
        ),
        child: row,
      ),
    );
  }
}
