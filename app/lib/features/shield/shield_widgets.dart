import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/mock.dart';

/// Animated cryptographic shield with pulsing rings (onboarding + AI Shield).
class PulsingShield extends StatelessWidget {
  const PulsingShield({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.75,
      height: size * 1.75,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Breathing(min: 0.85, max: 1.0, period: const Duration(milliseconds: 2600), breaths: 3, child: Dot(color: AppColors.primary.withValues(alpha: 0.1), size: size * 1.75)),
          Breathing(min: 0.9, max: 1.1, period: const Duration(milliseconds: 1800), breaths: 4, child: Dot(color: AppColors.mint.withValues(alpha: 0.08), size: size * 1.25)),
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 10), spreadRadius: -3)],
            ),
            child: Sym(Symbols.shield_with_heart, size: size * 0.44, color: AppColors.primary, fill: true),
          ),
          Positioned(
            right: size * 0.375 + 4,
            bottom: size * 0.375 + 4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: AppColors.mint, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceHigh, width: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle row from the "Vault Protocols" panel.
class GuardRow extends StatelessWidget {
  const GuardRow({super.key, required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged, this.soon = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Sym(icon, size: 20, color: value ? AppColors.primary : AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (soon) ...[const SizedBox(width: 6), const Tag(label: 'SOON', color: AppColors.lavender, padding: EdgeInsets.symmetric(horizontal: 6))],
                  ],
                ),
                Text(subtitle, style: AppText.small.copyWith(color: AppColors.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmourSwitch(value: value, onChanged: onChanged, semanticLabel: title),
        ],
      ),
    );
  }
}

/// Paired-device key status with safety-emoji verification.
class MutualKeyCard extends StatelessWidget {
  const MutualKeyCard({super.key, this.inset = false});

  /// Square inset style (inside the onboarding panel).
  final bool inset;

  static const safetyEmojis = ['🦊', '🌙', '🍓', '🎸'];

  void _verify(BuildContext context) {
    showAmourSheet(
      context,
      builder: (_) => AmourSheet(
        title: 'Safety check',
        subtitle: 'Compare these with ${Mock.partner}’s screen',
        icon: Symbols.verified_user,
        iconColor: AppColors.mint,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < safetyEmojis.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 420 + i * 120),
                    curve: Motion.pop,
                    builder: (context, t, child) => Transform.scale(scale: t, child: child),
                    child: Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                      child: Text(safetyEmojis[i], style: const TextStyle(fontSize: 32)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'If they match, nobody is in the middle. If they don’t, re-pair in person.',
              textAlign: TextAlign.center,
              style: AppText.small,
            ),
            const SizedBox(height: 16),
            Text('Key fingerprint  0x7F49 A1C3 5E08 9B2A', style: AppText.mono.copyWith(color: AppColors.primary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 48,
              height: 28,
              child: Stack(
                children: [
                  InitialAvatar(text: 'YOU', color: AppColors.hotPink, size: 28, fontSize: 9, borderColor: AppColors.surface),
                  Positioned(left: 20, child: InitialAvatar(text: 'CA', color: AppColors.violet, size: 28, fontSize: 10, borderColor: AppColors.surface)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('${Mock.partner}’s Device', style: AppText.smallStrong)),
            const Dot(color: AppColors.mint, size: 6),
            const SizedBox(width: 4),
            Text('Synced', style: AppText.labelSemi.copyWith(color: AppColors.mint)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('Diffie-Hellman Hash:', style: AppText.label.copyWith(color: AppColors.outline))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(16)),
              child: Text('0x7F49...9B2A', style: AppText.mono.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        if (!inset) ...[
          const SizedBox(height: 12),
          Pressable(
            onTap: () => _verify(context),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Sym(Symbols.verified_user, size: 16, color: AppColors.mint, fill: true),
                  const SizedBox(width: 6),
                  Text('Verify safety emojis', style: AppText.smallBold.copyWith(color: AppColors.mint)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
    if (inset) {
      return Container(padding: const EdgeInsets.all(16), color: AppColors.surface, child: content);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Sym(Symbols.key, size: 20, color: AppColors.lavender),
              const SizedBox(width: 6),
              Text('Paired Keys', style: AppText.headline),
            ],
          ),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), color: AppColors.surface, child: content),
        ],
      ),
    );
  }
}
