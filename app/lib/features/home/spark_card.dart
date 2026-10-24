import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import '../questions/questions_screen.dart';

/// Today's question. Answers stay hidden until you have both answered.
class SparkCard extends StatelessWidget {
  const SparkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final spark = state.spark;
    if (spark == null) return const SizedBox.shrink();
    final partner = state.partnerName;
    return AmourCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Sym(Symbols.auto_awesome, size: 16, color: c.lavender, fill: true),
              const SizedBox(width: 6),
              Expanded(child: Text('TODAY’S QUESTION', style: AppText.label.copyWith(color: c.lavender))),
              TextAction(label: 'Past answers', onTap: () => context.pushPop(const QuestionsScreen())),
            ],
          ),
          const SizedBox(height: 6),
          Text(spark.prompt, style: AppText.title),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: Motion.slow,
            switchInCurve: Motion.emphasized,
            transitionBuilder: (child, a) => FadeTransition(opacity: a, child: SizeTransition(sizeFactor: a, alignment: Alignment.topCenter, child: child)),
            child: spark.revealed
                ? _Revealed(key: const ValueKey('revealed'), spark: spark, partner: partner)
                : spark.answered
                    ? _Waiting(key: const ValueKey('waiting'), partner: partner)
                    : _AnswerPrompt(key: const ValueKey('prompt'), spark: spark, partner: partner),
          ),
        ],
      ),
    );
  }
}

class _AnswerPrompt extends StatelessWidget {
  const _AnswerPrompt({super.key, required this.spark, required this.partner});

  final DailySpark spark;
  final String partner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Sym(spark.partnerAnswered ? Symbols.lock : Symbols.hourglass_empty, size: 16, color: c.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                spark.partnerAnswered ? '$partner answered. Answer to unlock both.' : 'Answers unlock when you’ve both replied.',
                style: AppText.small.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GradientButton(label: 'Answer', icon: Symbols.edit, height: 48, onTap: () => showSparkAnswerSheet(context, spark)),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting({super.key, required this.partner});

  final String partner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Sym(Symbols.lock_clock, size: 20, color: c.accent),
          const SizedBox(width: 10),
          Expanded(child: Text('Your answer is locked in. It unlocks when $partner answers.', style: AppText.small.copyWith(color: c.textMuted))),
        ],
      ),
    );
  }
}

class _Revealed extends StatelessWidget {
  const _Revealed({super.key, required this.spark, required this.partner});

  final DailySpark spark;
  final String partner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadePop(child: _Answer(who: 'You', text: spark.myAnswer!)),
        const SizedBox(height: 10),
        FadePop(delay: const Duration(milliseconds: 180), child: _Answer(who: partner, text: spark.partnerAnswer!, partner: true)),
      ],
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.who, required this.text, this.partner = false});

  final String who;
  final String text;
  final bool partner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: partner ? c.pink.withValues(alpha: c.isDark ? 0.14 : 0.08) : c.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(who, style: AppText.caption.copyWith(color: partner ? c.accent : c.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(text, style: AppText.body),
        ],
      ),
    );
  }
}

Future<void> showSparkAnswerSheet(BuildContext context, DailySpark spark) {
  return showAmourSheet<void>(context, builder: (_) => _AnswerSheet(spark: spark));
}

class _AnswerSheet extends StatefulWidget {
  const _AnswerSheet({required this.spark});

  final DailySpark spark;

  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final answer = _text.text.trim();
    if (answer.isEmpty) return;
    setState(() => _busy = true);
    final state = AppScope.read(context);
    try {
      await state.backend.answerSpark(widget.spark.id, answer);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, '$e', icon: Symbols.error, color: context.colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourSheet(
      title: 'Your answer',
      subtitle: 'Only ${AppScope.read(context).partnerName} can read it, after answering too.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.spark.prompt, style: AppText.headline),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
            child: TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.body.copyWith(color: c.text),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Write from the heart…',
                hintStyle: AppText.body.copyWith(color: c.textFaint),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Lock in my answer', icon: Symbols.lock, busy: _busy, onTap: _text.text.trim().isEmpty ? null : _submit),
        ],
      ),
    );
  }
}
