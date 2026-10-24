import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

const _white = Color(0xFFFFFFFF);

/// Primary call-to-action: brand gradient pill.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52,
    this.expand = true,
    this.busy = false,
    this.gradient = AppGradients.pinkViolet,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool expand;
  final bool busy;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Pressable(
      onTap: enabled ? onTap : null,
      haptic: PressFeedback.medium,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: onTap != null ? 1 : 0.45,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: Brand.pink.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -6)],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const _Spinner(color: _white)
              else ...[
                if (icon != null) ...[Sym(icon!, size: 18, color: _white, fill: true), const SizedBox(width: 8)],
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(color: _white, fontWeight: FontWeight.w700))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Secondary pill: tinted surface, theme text.
class TonalButton extends StatelessWidget {
  const TonalButton({super.key, required this.label, required this.onTap, this.icon, this.height = 48, this.expand = true, this.color});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final bool expand;

  /// Foreground colour (defaults to the text colour).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.text;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Sym(icon!, size: 18, color: fg), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.smallStrong.copyWith(color: fg))),
          ],
        ),
      ),
    );
  }
}

/// Inline accent text action ("See all", "Add").
class TextAction extends StatelessWidget {
  const TextAction({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Sym(icon!, size: 16, color: accent), const SizedBox(width: 4)],
            Text(label, style: AppText.smallStrong.copyWith(color: accent)),
          ],
        ),
      ),
    );
  }
}

/// Round icon button (player controls, call dock, bar actions).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.color,
    this.iconColor,
    this.gradient,
    this.fill = false,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? iconColor;
  final Gradient? gradient;
  final bool fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: gradient == null ? (color ?? c.surfaceHigh) : null, gradient: gradient, shape: BoxShape.circle),
        child: Sym(icon, size: iconSize, color: iconColor ?? (gradient != null ? _white : c.text), fill: fill),
      ),
    );
  }
}

/// Tinted round icon (non-interactive leading badge).
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = 40, this.iconSize = 20});

  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.accent;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fg.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Sym(icon, size: iconSize, color: fg, fill: true),
    );
  }
}

class _Spinner extends StatefulWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: SizedBox.square(
        dimension: 20,
        child: CustomPaint(painter: _ArcPainter(widget.color)),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      (Offset.zero & size).deflate(1.5),
      0,
      4.4,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
