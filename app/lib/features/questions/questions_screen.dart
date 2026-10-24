import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import '../home/spark_card.dart';

/// Today's question and the answers you've both revealed before.
class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  late final Future<List<DailySpark>> _past = AppScope.read(context).backend.pastSparks();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final partner = AppScope.of(context).partnerName;
    return FutureBuilder<List<DailySpark>>(
      future: _past,
      builder: (context, snap) {
        final past = snap.data ?? const <DailySpark>[];
        return SubPage(
          title: 'Daily questions',
          children: [
            const SparkCard(),
            const _FreshQuestions(),
            if (past.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 4, top: 8), child: Text('Earlier', style: AppText.headline)),
            for (final s in past)
              AmourCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.prompt, style: AppText.subhead),
                    const SizedBox(height: 10),
                    if (s.myAnswer != null) _Line(who: 'You', text: s.myAnswer!, color: c.textMuted),
                    if (s.partnerAnswer != null) ...[const SizedBox(height: 6), _Line(who: partner, text: s.partnerAnswer!, color: c.accent)],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.who, required this.text, required this.color});

  final String who;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$who  ', style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        TextSpan(text: text, style: AppText.small),
      ]),
    );
  }
}

/// Ask for new AI-written questions on a theme (used on the next days).
class _FreshQuestions extends StatefulWidget {
  const _FreshQuestions();

  @override
  State<_FreshQuestions> createState() => _FreshQuestionsState();
}

class _FreshQuestionsState extends State<_FreshQuestions> {
  static const _themes = [('fun', 'Fun', Symbols.mood), ('deep', 'Deep', Symbols.favorite), ('future', 'Future', Symbols.rocket_launch), ('memories', 'Memories', Symbols.photo_library)];
  String? _busy;

  Future<void> _generate(String theme, String label) async {
    if (_busy != null) return;
    setState(() => _busy = theme);
    try {
      final questions = await AppScope.read(context).backend.generateQuestions(theme);
      if (mounted) showToast(context, '${questions.length} new $label questions are on the way', icon: Symbols.auto_awesome);
    } on Exception catch (e) {
      if (mounted) showToast(context, '$e', icon: Symbols.error, color: context.colors.danger);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fresh questions', style: AppText.subhead),
          const SizedBox(height: 2),
          Text('Pick a mood. New questions show up on the next days.', style: AppText.small.copyWith(color: c.textMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (id, label, icon) in _themes)
                Pressable(
                  onTap: () => _generate(id, label.toLowerCase()),
                  haptic: PressFeedback.selection,
                  semanticLabel: '$label questions',
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: _busy == id ? c.pink : c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Sym(icon, size: 16, color: _busy == id ? Colors.white : c.accent, fill: true),
                        const SizedBox(width: 6),
                        Text(_busy == id ? 'Writing…' : label, style: AppText.smallStrong.copyWith(color: _busy == id ? Colors.white : c.text)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
