import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'surfaces.dart';
import 'symbol.dart';

class QuestionOption {
  const QuestionOption(this.label, {this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;
}

/// Interactive question card ("SYNC PROMPT") with selectable pills that pop.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.label = 'SYNC PROMPT',
    this.icon = Symbols.bedtime,
    this.helper,
    this.correct,
  });

  final String question;
  final List<QuestionOption> options;
  final Set<int> selected;
  final ValueChanged<int> onSelect;
  final String label;
  final IconData icon;
  final String? helper;

  /// When set (quiz mode), highlights the right answer once something is picked.
  final int? correct;

  @override
  Widget build(BuildContext context) {
    return AmourCard(
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 2),
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                child: Sym(icon, size: 18, color: AppColors.lavender, fill: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.label.copyWith(color: AppColors.lavender)),
                    Text(question, style: AppText.headline.copyWith(height: 24.75 / 18)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < options.length; i++) ...[
            _OptionPill(
              option: options[i],
              index: i,
              selected: selected.contains(i),
              state: correct == null || selected.isEmpty
                  ? _Grade.none
                  : i == correct
                      ? _Grade.right
                      : selected.contains(i)
                          ? _Grade.wrong
                          : _Grade.none,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: 8),
          ],
          if (helper != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Sym(Symbols.auto_awesome, size: 15, color: AppColors.outline),
                const SizedBox(width: 6),
                Expanded(child: Text(helper!, style: AppText.small.copyWith(color: AppColors.outline))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _Grade { none, right, wrong }

class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.option, required this.index, required this.selected, required this.state, required this.onTap});

  final QuestionOption option;
  final int index;
  final bool selected;
  final _Grade state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (state) {
      _Grade.right => AppColors.mintDeep,
      _Grade.wrong => AppColors.crimson,
      _Grade.none => selected ? AppColors.hotPink : AppColors.surfaceHigh,
    };
    final active = selected || state != _Grade.none;
    final fg = active ? const Color(0xFFFFFFFF) : AppColors.onSurfaceVariant;
    return Pressable(
      onTap: onTap,
      haptic: PressFeedback.selection,
      pressedScale: 0.94,
      child: AnimatedScale(
        duration: Motion.medium,
        curve: Motion.pop,
        scale: selected ? 1.03 : 1,
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active ? [BoxShadow(color: bg.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Sym(option.icon!, size: 16, color: active ? fg : (option.color ?? AppColors.onSurfaceVariant), fill: active),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(option.label, style: AppText.smallStrong.copyWith(color: fg))),
              if (state == _Grade.right) ...[const SizedBox(width: 8), const Sym(Symbols.check_circle, size: 16, color: Color(0xFFFFFFFF), fill: true)],
            ],
          ),
        ),
      ),
    );
  }
}

/// "STEP 02 OF 04 · Bonding Rituals" progress header.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.total, required this.label});

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.bg,
      child: Column(
        children: [
          Row(
            children: [
              Text('STEP ${step.toString().padLeft(2, '0')} OF ${total.toString().padLeft(2, '0')}', style: AppText.labelSemi.copyWith(color: AppColors.lavender)),
              const Spacer(),
              AnimatedSwitcher(
                duration: Motion.medium,
                child: Text(label, key: ValueKey(label), style: AppText.label.copyWith(color: AppColors.outline)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999)),
            child: LayoutBuilder(
              builder: (context, c) => Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: step / total),
                  duration: Motion.slow,
                  curve: Motion.emphasized,
                  builder: (context, f, _) => Container(
                    width: c.maxWidth * f,
                    decoration: BoxDecoration(gradient: AppGradients.progress, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
