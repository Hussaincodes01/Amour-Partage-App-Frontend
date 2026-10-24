import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// Pill switch with a springy knob.
class AmourSwitch extends StatelessWidget {
  const AmourSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              },
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.emphasized,
          width: 48,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: value ? c.pink : c.surfaceHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: Motion.medium,
            curve: Motion.pop,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.18), blurRadius: 4, offset: const Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
