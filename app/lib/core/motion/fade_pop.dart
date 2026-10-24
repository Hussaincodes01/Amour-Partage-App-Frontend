import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Entrance animation used across the app: fades in while "popping" from a
/// slightly smaller, lower position. Runs once, on the compositor only
/// (opacity + transform), so it stays smooth at high refresh rates.
class FadePop extends StatefulWidget {
  const FadePop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
    this.offsetY = 14,
    this.fromScale = 0.96,
  });

  /// Convenience for staggered lists: `FadePop.index(i, child: ...)`.
  factory FadePop.index(int index, {Key? key, required Widget child}) => FadePop(key: key, delay: Motion.stagger * index, child: child);

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double fromScale;

  @override
  State<FadePop> createState() => _FadePopState();
}

class _FadePopState extends State<FadePop> with SingleTickerProviderStateMixin {
  // The stagger delay is folded into the animation itself (no timers), so a
  // disposed widget never leaves anything scheduled behind.
  late final Duration _total = widget.delay + widget.duration;
  late final double _start = widget.delay.inMicroseconds / _total.inMicroseconds;
  late final AnimationController _c = AnimationController(vsync: this, duration: _total);
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Interval(_start, _start + (1 - _start) * 0.7, curve: Motion.fadeIn));
  late final Animation<double> _pop = CurvedAnimation(parent: _c, curve: Interval(_start, 1, curve: Motion.pop));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _pop,
        child: widget.child,
        builder: (context, child) {
          final t = _pop.value;
          final scale = widget.fromScale + (1 - widget.fromScale) * t;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translateByDouble(0, widget.offsetY * (1 - t), 0, 1)
              ..scaleByDouble(scale, scale, 1, 1),
            child: child,
          );
        },
      ),
    );
  }
}
