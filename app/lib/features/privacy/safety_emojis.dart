import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../data/couple_state.dart';

/// Shows the four safety emojis. Both phones must show the same ones.
Future<void> showSafetyEmojis(BuildContext context) => showAmourSheet<void>(context, builder: (_) => const _SafetyEmojisSheet());

class SafetyEmojiRow extends StatelessWidget {
  const SafetyEmojiRow({super.key, required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < emojis.length; i++)
          FadePop.index(
            i,
            child: Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
              child: Text(emojis[i], style: const TextStyle(fontSize: 32)),
            ),
          ),
      ],
    );
  }
}

class _SafetyEmojisSheet extends StatelessWidget {
  const _SafetyEmojisSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final couple = state.couple;
    if (couple == null) return const SizedBox.shrink();
    return AmourSheet(
      title: 'Safety emojis',
      subtitle: 'Open this on both phones. If the emojis match, nobody is listening in.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (couple.keyChanged) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Text('${couple.partner.name} has a new phone or reinstalled the app. Check the emojis together before sharing anything private.', style: AppText.small.copyWith(color: c.danger)),
            ),
            const SizedBox(height: 16),
          ],
          SafetyEmojiRow(emojis: couple.safetyEmojis),
          const SizedBox(height: 20),
          GradientButton(
            label: 'They match',
            icon: Symbols.verified,
            onTap: () async {
              await state.backend.confirmSafetyEmojis();
              if (!context.mounted) return;
              Navigator.of(context).pop();
              showToast(context, 'Verified. Your space is private', icon: Symbols.verified_user, color: c.success);
            },
          ),
          const SizedBox(height: 8),
          TonalButton(
            label: 'They don’t match',
            color: c.danger,
            onTap: () async {
              final again = await confirmAction(
                context,
                title: 'Don’t share anything private yet',
                message: 'Different emojis mean the keys don’t match. Unlink and pair again, ideally side by side using the QR code.',
                confirm: 'Unlink',
                destructive: true,
              );
              if (!again || !context.mounted) return;
              await state.backend.unlink();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
