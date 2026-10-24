import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// 48×28 pill switch from the Figma theme, with a springy knob.
class AmourSwitch extends StatelessWidget {
  const AmourSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
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
            color: value ? AppColors.hotPink : AppColors.surfaceHighest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: value ? [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.35), blurRadius: 10)] : null,
          ),
          child: AnimatedAlign(
            duration: Motion.medium,
            curve: Motion.pop,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.pop,
              width: value ? 20 : 24,
              height: value ? 20 : 24,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFFFFFFF) : AppColors.onSurface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
