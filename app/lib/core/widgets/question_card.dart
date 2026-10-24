import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

class QuestionOption {
  const QuestionOption(this.label, {this.icon});

  final String label;
  final IconData? icon;
}

/// A question with selectable answer pills that pop when picked.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, required this.options, required this.selected, required this.onSelect, this.correct});

  final String question;
  final List<QuestionOption> options;
  final Set<int> selected;
  final ValueChanged<int> onSelect;

  /// When set (quiz mode), marks the right answer once something is picked.
  final int? correct;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: AppText.title),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++) ...[
          _OptionPill(
            option: options[i],
            selected: selected.contains(i),
            grade: correct == null || selected.isEmpty
                ? _Grade.none
                : i == correct
                    ? _Grade.right
                    : selected.contains(i)
                        ? _Grade.wrong
                        : _Grade.none,
            onTap: () => onSelect(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

enum _Grade { none, right, wrong }

class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.option, required this.selected, required this.grade, required this.onTap});

  final QuestionOption option;
  final bool selected;
  final _Grade grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color bg = switch (grade) {
      _Grade.right => c.success,
      _Grade.wrong => c.danger,
      _Grade.none => selected ? c.pink : c.surfaceHigh,
    };
    final active = selected || grade != _Grade.none;
    final fg = active ? (c.isDark && grade != _Grade.none ? c.bg : const Color(0xFFFFFFFF)) : c.text;
    return Pressable(
      onTap: onTap,
      haptic: PressFeedback.selection,
      pressedScale: 0.96,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            if (option.icon != null) ...[Sym(option.icon!, size: 20, color: active ? fg : c.accent, fill: active), const SizedBox(width: 12)],
            Expanded(child: Text(option.label, style: AppText.subhead.copyWith(color: fg))),
            AnimatedScale(
              duration: Motion.medium,
              curve: Motion.pop,
              scale: active ? 1 : 0,
              child: Sym(grade == _Grade.wrong ? Symbols.close : Symbols.check_circle, size: 20, color: fg, fill: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin progress bar with "Step 2 of 4".
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
            child: LayoutBuilder(
              builder: (context, box) => Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: step / total),
                  duration: Motion.slow,
                  curve: Motion.emphasized,
                  builder: (context, f, _) => Container(
                    width: box.maxWidth * f,
                    decoration: BoxDecoration(gradient: AppGradients.pinkLilac, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$step of $total', style: AppText.caption.copyWith(color: c.textMuted)),
      ],
    );
  }
}
