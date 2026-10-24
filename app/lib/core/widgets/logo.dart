import 'package:flutter/widgets.dart';

/// Amour Partagé app mark: a neon heart around a smaller heart, on a dark
/// rounded tile. Vector, so it stays crisp at any size (header, splash, icon).
class AmourLogo extends StatelessWidget {
  const AmourLogo({super.key, this.size = 32, this.tile = true, this.glow = 1});

  final double size;
  final bool tile;

  /// 0..1 strength of the neon glow (animated on the splash screen).
  final double glow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(size: Size.square(size), painter: _LogoPainter(tile: tile, glow: glow)),
    );
  }
}

Path heartPath(Rect r) {
  final w = r.width, h = r.height, x = r.left, y = r.top;
  Offset p(double u, double v) => Offset(x + u * w, y + v * h);
  return Path()
    ..moveTo(p(0.5, 0.9).dx, p(0.5, 0.9).dy)
    ..cubicTo(p(0.36, 0.8).dx, p(0.36, 0.8).dy, p(0.04, 0.6).dx, p(0.04, 0.6).dy, p(0.04, 0.33).dx, p(0.04, 0.33).dy)
    ..cubicTo(p(0.04, 0.17).dx, p(0.04, 0.17).dy, p(0.17, 0.06).dx, p(0.17, 0.06).dy, p(0.3, 0.06).dx, p(0.3, 0.06).dy)
    ..cubicTo(p(0.4, 0.06).dx, p(0.4, 0.06).dy, p(0.47, 0.12).dx, p(0.47, 0.12).dy, p(0.5, 0.2).dx, p(0.5, 0.2).dy)
    ..cubicTo(p(0.53, 0.12).dx, p(0.53, 0.12).dy, p(0.6, 0.06).dx, p(0.6, 0.06).dy, p(0.7, 0.06).dx, p(0.7, 0.06).dy)
    ..cubicTo(p(0.83, 0.06).dx, p(0.83, 0.06).dy, p(0.96, 0.17).dx, p(0.96, 0.17).dy, p(0.96, 0.33).dx, p(0.96, 0.33).dy)
    ..cubicTo(p(0.96, 0.6).dx, p(0.96, 0.6).dy, p(0.64, 0.8).dx, p(0.64, 0.8).dy, p(0.5, 0.9).dx, p(0.5, 0.9).dy)
    ..close();
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.tile, required this.glow});

  final bool tile;
  final double glow;

  static const _magenta = Color(0xFFFF3FB4);
  static const _violet = Color(0xFF8F5BFF);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bounds = Offset.zero & size;
    if (tile) {
      final rr = RRect.fromRectAndRadius(bounds, Radius.circular(s * 0.25));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1C1030), Color(0xFF120A1E)]).createShader(bounds),
      );
      canvas.drawRRect(
        rr.deflate(s * 0.01),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..shader = LinearGradient(colors: [_magenta.withValues(alpha: 0.35), _violet.withValues(alpha: 0.12)]).createShader(bounds),
      );
    }

    final outerRect = Rect.fromLTWH(s * 0.19, s * 0.22, s * 0.62, s * 0.56);
    final outer = heartPath(outerRect);
    final strokeShader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_magenta, _violet]).createShader(outerRect);

    if (glow > 0) {
      canvas.drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.1
          ..shader = strokeShader
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
      );
    }
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..strokeJoin = StrokeJoin.round
        ..shader = strokeShader,
    );

    final innerRect = Rect.fromCenter(center: Offset(s * 0.5, s * 0.5), width: s * 0.24, height: s * 0.22);
    final inner = heartPath(innerRect);
    canvas.drawPath(
      inner,
      Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0409E), _violet]).createShader(innerRect),
    );
    canvas.drawCircle(
      Offset(s * 0.505, s * 0.5),
      s * 0.04,
      Paint()
        ..color = const Color(0xFFF4D9FF).withValues(alpha: 0.9)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.025),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.glow != glow || old.tile != tile;
}
