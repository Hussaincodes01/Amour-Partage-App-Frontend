import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

class Segment<T> {
  const Segment(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Pill segmented control with a sliding thumb.
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.segments, required this.value, required this.onChanged});

  final List<Segment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final index = segments.indexWhere((s) => s.value == value);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.medium,
                curve: Motion.emphasized,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.isDark ? c.surfaceHighest : c.surface,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: c.isDark ? null : [BoxShadow(color: c.shadow.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final s in segments)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: s.value == value,
                        label: s.label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (s.value == value) return;
                            HapticFeedback.selectionClick();
                            onChanged(s.value);
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (s.icon != null) ...[Sym(s.icon!, size: 16, color: s.value == value ? c.text : c.textMuted, fill: s.value == value), const SizedBox(width: 6)],
                                Flexible(
                                  child: Text(
                                    s.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.smallStrong.copyWith(color: s.value == value ? c.text : c.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
