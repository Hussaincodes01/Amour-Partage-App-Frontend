import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/mock.dart';

/// Mutual, time-boxed live location sharing (always visible, one tap to stop).
class ShareLocationSheet extends StatelessWidget {
  const ShareLocationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const options = [
      (LocationShare.oneHour, 'For 1 hour', 'Great for “I’m on my way”', Symbols.timer),
      (LocationShare.eightHours, 'For 8 hours', 'A night out or a long trip', Symbols.schedule),
      (LocationShare.untilStopped, 'Until I stop', 'You’ll get a daily reminder', Symbols.all_inclusive),
    ];
    return AmourSheet(
      title: 'Share live location',
      subtitle: 'Only ${Mock.partner} can see it • encrypted on your phone',
      icon: Symbols.share_location,
      iconColor: AppColors.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final o in options) ...[
            Pressable(
              pressedScale: 0.98,
              haptic: PressFeedback.selection,
              onTap: () => state.setLocationShare(o.$1),
              child: AnimatedContainer(
                duration: Motion.medium,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: state.locationShare == o.$1 ? AppColors.mint.withValues(alpha: 0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: state.locationShare == o.$1 ? AppColors.mint.withValues(alpha: 0.5) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    IconBadge(icon: o.$4, color: AppColors.mint, size: 36, iconSize: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.$2, style: AppText.bodyStrong),
                          Text(o.$3, style: AppText.small),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: Motion.medium,
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: state.locationShare == o.$1
                          ? const Sym(Symbols.check_circle, key: ValueKey('on'), size: 22, color: AppColors.mint, fill: true)
                          : const Sym(Symbols.radio_button_unchecked, key: ValueKey('off'), size: 22, color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Sym(Symbols.shield, size: 14, color: AppColors.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sharing is always mutual and shows a persistent notification. Either of you can stop it instantly.',
                  style: AppText.small.copyWith(color: AppColors.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.locationShare != LocationShare.off)
            Pressable(
              onTap: () {
                state.setLocationShare(LocationShare.off);
                Navigator.of(context).pop();
                showLoveToast(context, 'Location sharing stopped', icon: Symbols.location_off, color: AppColors.lavender);
              },
              haptic: PressFeedback.medium,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999)),
                child: Text('Stop sharing now', style: AppText.bodyStrong.copyWith(color: AppColors.error)),
              ),
            )
          else
            GradientButton(
              label: 'Start sharing',
              leadingIcon: Symbols.share_location,
              gradient: AppGradients.mintTab,
              glowColor: AppColors.mint,
              onTap: () {
                state.setLocationShare(LocationShare.oneHour);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}
