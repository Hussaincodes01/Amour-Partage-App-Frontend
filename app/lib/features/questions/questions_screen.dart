import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../../data/models.dart';
import '../home/soul_spark_card.dart';
import 'quiz_screen.dart';

/// Soul Sparks archive + entry to the "How well do you know me?" quiz.
class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = AppScope.of(context).spark;
    return SubPage(
      title: 'Soul Sparks',
      subtitle: '182 questions answered together',
      children: [
        Pressable(
          pressedScale: 0.98,
          onTap: () => context.pushPop(const QuizScreen()),
          child: AmourCard(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A1550), AppColors.surfaceLow]),
            blooms: [Bloom(color: AppColors.hotPink.withValues(alpha: 0.25), size: 200, right: -60, top: -70)],
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COUPLE QUIZ', style: AppText.label.copyWith(color: AppColors.lavender)),
                      Text('How well do you know ${Mock.partner}?', style: AppText.headline),
                      Text('4 questions • beat your last score of 3/4', style: AppText.small),
                    ],
                  ),
                ),
                const Sym(Symbols.play_circle, size: 32, color: AppColors.primary, fill: true),
              ],
            ),
          ),
        ),
        if (today.myAnswer == null) const SoulSparkCard() else _PastSpark(spark: today, isToday: true),
        Text('Earlier sparks', style: AppText.title),
        for (final s in Mock.pastSparks) _PastSpark(spark: s),
      ],
    );
  }
}

class _PastSpark extends StatelessWidget {
  const _PastSpark({required this.spark, this.isToday = false});

  final SoulSpark spark;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return AmourCard(
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SOUL SPARK #${spark.number}', style: AppText.label.copyWith(color: AppColors.primary)),
              const Spacer(),
              if (isToday) const Tag(label: 'TODAY', color: AppColors.mint) else const Tag(label: 'Unlocked', icon: Symbols.lock_open, color: AppColors.lavender),
            ],
          ),
          const SizedBox(height: 8),
          Text(spark.question, style: AppText.headline),
          const SizedBox(height: 12),
          _Answer(image: DemoImages.camille, name: Mock.partner, text: spark.partnerAnswer ?? '', color: AppColors.lavender),
          const SizedBox(height: 8),
          _Answer(image: DemoImages.julian, name: 'You', text: spark.myAnswer ?? '', color: AppColors.primary),
        ],
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.image, required this.name, required this.text, required this.color});

  final ImageProvider image;
  final String name;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(image: image, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.ink(0.55), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.label.copyWith(color: color)),
                Text(text, style: AppText.body.copyWith(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
