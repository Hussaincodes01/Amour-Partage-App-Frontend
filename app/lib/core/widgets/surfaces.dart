import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Soft ambient glow drawn with a radial gradient (no blur pass).
class GlowBlob extends StatelessWidget {
  const GlowBlob({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: color.a * 0.5), color.withValues(alpha: 0)], stops: const [0, 0.45, 1]),
          ),
        ),
      ),
    );
  }
}

/// Two faint brand glows behind a screen. Subtle in the light theme.
class AmbientGlow extends StatelessWidget {
  const AmbientGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final strength = context.colors.isDark ? 1.0 : 0.45;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(left: -120, top: -120, child: GlowBlob(color: Brand.pink.withValues(alpha: 0.13 * strength), size: 360)),
          Positioned(right: -140, top: 260, child: GlowBlob(color: Brand.violet.withValues(alpha: 0.16 * strength), size: 380)),
        ],
      ),
    );
  }
}

/// Card soft shadow for the current theme.
List<BoxShadow> cardShadow(AppColors c) => c.isDark
    ? const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -8)]
    : [BoxShadow(color: c.shadow.withValues(alpha: 0.07), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -6)];

/// Rounded card: the one container used for every section.
class AmourCard extends StatelessWidget {
  const AmourCard({
    super.key,
    required this.child,
    this.color,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.border = false,
  });

  final Widget child;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: r,
        border: border || !c.isDark ? Border.all(color: c.border) : null,
        boxShadow: cardShadow(c),
      ),
      child: ClipRRect(borderRadius: r, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Real backdrop blur, only where content scrolls underneath (bars).
class FrostedBox extends StatelessWidget {
  const FrostedBox({super.key, required this.child, this.sigma = 16, this.opacity = 0.82, this.borderRadius = BorderRadius.zero});

  final Widget child;
  final double sigma;
  final double opacity;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter.grouped(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(color: context.colors.bgA(opacity), child: child),
      ),
    );
  }
}
