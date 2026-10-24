import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../questions/questions_screen.dart';

/// Daily question. Both answers stay sealed until both partners respond,
/// then they reveal together with a flip + burst.
class SoulSparkCard extends StatefulWidget {
  const SoulSparkCard({super.key});

  @override
  State<SoulSparkCard> createState() => _SoulSparkCardState();
}

class _SoulSparkCardState extends State<SoulSparkCard> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.heavyImpact();
    _focus.unfocus();
    AppScope.read(context).answerSpark(text);
    _controller.clear();
    showEmojiBurst(context, '✨', count: 9);
  }

  @override
  Widget build(BuildContext context) {
    final spark = AppScope.of(context).spark;
    final revealed = spark.myAnswer != null;
    return AmourCard(
      color: AppColors.raised(0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Symbols.auto_awesome, color: AppColors.primary, background: Color(0x33FFB0C9), size: 24, iconSize: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text("TODAY'S SOUL SPARK #${spark.number}", style: AppText.label.copyWith(color: AppColors.primary)),
              ),
              const Tag(label: 'Dual E2EE', icon: Symbols.lock, color: AppColors.mint, padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(spark.question, style: AppText.title),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: Motion.slow,
            switchInCurve: Motion.pop,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
            ),
            child: revealed ? _Revealed(key: const ValueKey('revealed'), mine: spark.myAnswer!, theirs: spark.partnerAnswer!) : const _LockedTeaser(key: ValueKey('locked')),
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: Motion.medium,
            curve: Motion.emphasized,
            child: revealed
                ? _AfterReveal(onMore: () => context.pushPop(const QuestionsScreen()))
                : Column(
                    children: [
                      _AnswerField(controller: _controller, focus: _focus, enabled: _hasText, onSubmit: _submit),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text('Both responses unlock simultaneously', style: AppText.label)),
                            const Sym(Symbols.verified_user, size: 12, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Zero-Knowledge Storage', style: AppText.label),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LockedTeaser extends StatelessWidget {
  const _LockedTeaser({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: AppColors.ink(0.6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Blurred placeholder of Camille's sealed answer.
          Opacity(
            opacity: 0.25,
            child: Row(
              children: [
                const Dot(color: Color(0x806F00BE), size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 196, decoration: BoxDecoration(color: AppColors.onSurfaceVariant.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(99))),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 164, decoration: BoxDecoration(color: AppColors.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(99))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 32,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
                child: const Sym(Symbols.key, size: 13, color: AppColors.lavender, fill: true),
              ),
              const SizedBox(height: 6),
              Text('${Mock.partner} answered ${Mock.spark.partnerAnsweredAgo}', style: AppText.smallBold, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('Submit your memory below to unlock both reflections together', style: AppText.small, textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}

class _Revealed extends StatelessWidget {
  const _Revealed({super.key, required this.mine, required this.theirs});

  final String mine;
  final String theirs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AnswerBubble(name: Mock.partner, image: DemoImages.camille, text: theirs, accent: AppColors.lavender),
        const SizedBox(height: 8),
        _AnswerBubble(name: 'You', image: DemoImages.julian, text: mine, accent: AppColors.primary),
      ],
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.name, required this.image, required this.text, required this.accent});

  final String name;
  final ImageProvider image;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(image: image, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.label.copyWith(color: accent)),
                const SizedBox(height: 2),
                Text(text, style: AppText.body.copyWith(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AfterReveal extends StatelessWidget {
  const _AfterReveal({required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Sym(Symbols.celebration, size: 16, color: AppColors.mint),
        const SizedBox(width: 6),
        Expanded(child: Text('Unlocked together • Saved to your Vault', style: AppText.label.copyWith(color: AppColors.mint))),
        Pressable(
          onTap: onMore,
          child: Row(
            children: [
              Text('More sparks', style: AppText.label.copyWith(color: AppColors.primary)),
              const Sym(Symbols.chevron_right, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerField extends StatelessWidget {
  const _AnswerField({required this.controller, required this.focus, required this.enabled, required this.onSubmit});

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(color: AppColors.ink(0.8), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              style: AppText.body,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Share your song & why...',
                hintStyle: AppText.body.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            ),
          ),
          Pressable(
            onTap: enabled ? onSubmit : null,
            pressedScale: 0.88,
            child: AnimatedOpacity(
              duration: Motion.fast,
              opacity: enabled ? 1 : 0.55,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.pinkViolet),
                child: const Sym(Symbols.send, size: 18, color: Colors.white, fill: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
