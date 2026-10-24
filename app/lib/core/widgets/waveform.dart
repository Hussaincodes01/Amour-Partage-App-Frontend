import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../motion/motion.dart';

/// Rounded audio bars. When [live] is true the bars gently dance.
class Waveform extends StatefulWidget {
  const Waveform({
    super.key,
    required this.heights,
    required this.colors,
    this.barWidth = 4,
    this.gap = 3,
    this.live = false,
    this.maxHeight,
    this.progress,
    this.inactiveColor,
  });

  final List<double> heights;

  /// One colour per bar (cycled if shorter).
  final List<Color> colors;
  final double barWidth;
  final double gap;
  final bool live;
  final double? maxHeight;

  /// When set (0..1), bars after the playhead use [inactiveColor].
  final double? progress;
  final Color? inactiveColor;

  @override
  State<Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<Waveform> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.live && !Motion.reduced(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = widget.maxHeight ?? widget.heights.reduce(math.max);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size(widget.heights.length * (widget.barWidth + widget.gap) - widget.gap, maxH),
          painter: _BarsPainter(
            heights: widget.heights,
            colors: widget.colors,
            barWidth: widget.barWidth,
            gap: widget.gap,
            phase: widget.live ? _c.value : null,
            maxH: maxH,
            progress: widget.progress,
            inactive: widget.inactiveColor,
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.heights,
    required this.colors,
    required this.barWidth,
    required this.gap,
    required this.phase,
    required this.maxH,
    required this.progress,
    required this.inactive,
  });

  final List<double> heights;
  final List<Color> colors;
  final double barWidth, gap, maxH;
  final double? phase;
  final double? progress;
  final Color? inactive;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < heights.length; i++) {
      var h = heights[i];
      if (phase != null) {
        final wobble = 0.65 + 0.35 * math.sin((phase! * 2 * math.pi) + i * 0.9).abs();
        h = (h * wobble).clamp(barWidth, maxH);
      }
      final played = progress == null || (i + 0.5) / heights.length <= progress!;
      paint.color = played ? colors[i % colors.length] : (inactive ?? colors[i % colors.length]);
      final x = i * (barWidth + gap);
      final top = (size.height - h) / 2;
      canvas.drawRRect(RRect.fromLTRBR(x, top, x + barWidth, top + h, Radius.circular(barWidth)), paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.phase != phase || old.progress != progress || old.heights != heights;
}
