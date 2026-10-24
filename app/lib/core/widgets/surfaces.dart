import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Soft ambient bloom. The design uses CSS `blur(32px)` on solid circles; a
/// radial gradient gives the same look without an expensive blur pass.
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
            gradient: RadialGradient(colors: [color, color.withValues(alpha: color.a * 0.55), color.withValues(alpha: 0)], stops: const [0, 0.45, 1]),
          ),
        ),
      ),
    );
  }
}

/// Positioned glow inside a card/screen Stack.
class Bloom {
  const Bloom({required this.color, required this.size, this.left, this.top, this.right, this.bottom});

  final Color color;
  final double size;
  final double? left, top, right, bottom;

  Widget build() => Positioned(left: left, top: top, right: right, bottom: bottom, child: GlowBlob(color: color, size: size));
}

/// Rounded card used for nearly every section in the design.
class AmourCard extends StatelessWidget {
  const AmourCard({
    super.key,
    required this.child,
    this.color = AppColors.surfaceLow,
    this.radius = 32,
    this.padding = const EdgeInsets.all(16),
    this.blooms = const [],
    this.shadow = true,
    this.border,
    this.gradient,
  });

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final List<Bloom> blooms;
  final bool shadow;
  final BoxBorder? border;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget content = Padding(padding: padding, child: child);
    if (blooms.isNotEmpty) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [for (final b in blooms) b.build(), content],
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: r,
        border: border,
        boxShadow: shadow
            ? const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 12), spreadRadius: -10)]
            : null,
      ),
      child: ClipRRect(borderRadius: r, child: content),
    );
  }
}

/// Real backdrop blur — only used where content actually scrolls underneath
/// (header, nav, floating media chips). Elsewhere a translucent fill over the
/// flat background is visually identical and far cheaper.
class FrostedBox extends StatelessWidget {
  const FrostedBox({super.key, required this.child, this.sigma = 12, this.color, this.borderRadius = BorderRadius.zero});

  final Widget child;
  final double sigma;
  final Color? color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter.grouped(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColoredBox(color: color ?? AppColors.ink(0.8), child: child),
      ),
    );
  }
}
