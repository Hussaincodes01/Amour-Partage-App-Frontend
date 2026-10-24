import 'package:flutter/widgets.dart';

import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

/// Full-width gradient call-to-action ("Authorize AI Privacy & Pair Devices").
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = const LinearGradient(colors: [AppColors.hotPink, AppColors.primary]),
    this.icon,
    this.leadingIcon,
    this.height = 52,
    this.textStyle,
    this.expand = true,
    this.glowColor = AppColors.hotPink,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.iconSize = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final IconData? icon;
  final IconData? leadingIcon;
  final double height;
  final TextStyle? textStyle;
  final bool expand;
  final Color glowColor;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      haptic: PressFeedback.medium,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -4)],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[Sym(leadingIcon!, size: iconSize, color: const Color(0xFFFFFFFF), fill: true), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle ?? AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFFFFFFF)),
                ),
              ),
              if (icon != null) ...[const SizedBox(width: 8), Sym(icon!, size: iconSize, color: const Color(0xFFFFFFFF))],
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button (player controls, call dock, header utilities).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.color = AppColors.surfaceHigh,
    this.iconColor = AppColors.onSurface,
    this.gradient,
    this.glow,
    this.fill = false,
    this.semanticLabel,
    this.border,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color color;
  final Color iconColor;
  final Gradient? gradient;
  final Color? glow;
  final bool fill;
  final String? semanticLabel;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: gradient == null ? color : null,
          gradient: gradient,
          shape: BoxShape.circle,
          border: border,
          boxShadow: glow != null ? [BoxShadow(color: glow!, blurRadius: 14)] : null,
        ),
        child: Sym(icon, size: iconSize, color: iconColor, fill: fill),
      ),
    );
  }
}

/// Round icon on a tinted circle — a non-interactive leading badge.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.background, this.size = 40, this.iconSize = 18, this.fill = true, this.glow});

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;
  final double iconSize;
  final bool fill;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: glow != null ? [BoxShadow(color: glow!, blurRadius: 12)] : null,
      ),
      child: Sym(icon, size: iconSize, color: color, fill: fill),
    );
  }
}
