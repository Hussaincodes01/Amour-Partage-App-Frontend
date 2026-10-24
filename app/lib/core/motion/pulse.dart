import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Glowing status dot with an expanding "ping" ring (live / synced / online).
class PingDot extends StatefulWidget {
  const PingDot({super.key, required this.color, this.size = 8, this.glow = true, this.period = const Duration(milliseconds: 1600)});

  final Color color;
  final double size;
  final bool glow;
  final Duration period;

  @override
  State<PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);
  Timer? _rest;

  @override
  void initState() {
    super.initState();
    // Ping, then rest: the screen only renders new frames while a ping is in
    // flight, which keeps idle screens from redrawing at 120-165 Hz forever.
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _c.value = 0;
        _rest = Timer(widget.period * 1.5, () {
          if (mounted && TickerMode.valuesOf(context).enabled) _c.forward();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating && TickerMode.valuesOf(context).enabled) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _rest?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return RepaintBoundary(
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_c.value);
                return Transform.scale(
                  scale: 1 + t * 1.6,
                  child: Opacity(
                    opacity: (1 - t) * 0.6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                      child: SizedBox(width: s, height: s),
                    ),
                  ),
                );
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: widget.glow ? [BoxShadow(color: widget.color, blurRadius: s)] : null,
              ),
              child: SizedBox(width: s, height: s),
            ),
          ],
        ),
      ),
    );
  }
}

/// Repeating "breathing" scale, used on pulsing rings and the touch-pulse marker.
class Breathing extends StatefulWidget {
  const Breathing({
    super.key,
    required this.child,
    this.min = 0.92,
    this.max = 1.08,
    this.period = const Duration(milliseconds: 2200),
    this.breaths,
  });

  final Widget child;
  final double min;
  final double max;
  final Duration period;

  /// Stop after this many in/out cycles (null = forever). Decorative loops on
  /// static screens use a few breaths so the GPU can idle afterwards.
  final int? breaths;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating && !_finished) {
      _c.repeat(reverse: true, count: widget.breaths == null ? null : widget.breaths! * 2).whenCompleteOrCancel(() {
        if (widget.breaths != null && _c.status == AnimationStatus.dismissed) _finished = true;
      });
    }
  }

  bool _finished = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(
        scale: Tween(begin: widget.min, end: widget.max).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutSine)),
        child: widget.child,
      ),
    );
  }
}

/// Three bouncing dots for "is typing".
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, required this.color, this.size = 4});

  final Color color;
  final double size;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: widget.size / 2),
              Transform.translate(
                offset: Offset(0, -widget.size * 0.9 * math.max(0, math.sin((_c.value - i * 0.18) * 2 * math.pi))),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  child: SizedBox.square(dimension: widget.size),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
