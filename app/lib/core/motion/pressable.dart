import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

enum PressFeedback { none, light, selection, medium }

/// Tap target with a springy "pop" press effect and optional haptics.
/// Replaces ink splashes everywhere so taps feel tactile and stay cheap.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.haptic = PressFeedback.light,
    this.semanticLabel,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final PressFeedback haptic;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: widget.pressedScale).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOut, reverseCurve: Motion.pop),
  );

  bool get _active => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _haptic() {
    switch (widget.haptic) {
      case PressFeedback.none:
        break;
      case PressFeedback.light:
        HapticFeedback.lightImpact();
      case PressFeedback.selection:
        HapticFeedback.selectionClick();
      case PressFeedback.medium:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _active,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _active ? (_) => _c.forward() : null,
        onTapCancel: _active ? () => _c.reverse() : null,
        onTapUp: _active ? (_) => _c.reverse() : null,
        onTap: _active && widget.onTap != null
            ? () {
                _haptic();
                widget.onTap!();
              }
            : null,
        onLongPress: _active && widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
