import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../backend/demo/demo_data.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/question_card.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/symbol.dart';

/// "How well do you know me?" (demo questions for now).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _step = 0;
  int _score = 0;
  int? _picked;
  Timer? _advance;

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _pick(int i) {
    if (_picked != null) return;
    final q = DemoData.quiz[_step];
    setState(() {
      _picked = i;
      if (i == q.correct) _score++;
    });
    _advance = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _step++;
        _picked = null;
      });
      if (_step == DemoData.quiz.length && _score >= DemoData.quiz.length - 1) showEmojiBurst(context, '💞', count: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = DemoData.quiz.length;
    final done = _step >= total;
    return SubPage(
      title: 'How well do you know me?',
      bottom: done ? GradientButton(label: 'Play again', icon: Symbols.replay, onTap: () => setState(() {
                _step = 0;
                _score = 0;
              })) : null,
      children: [
        StepProgress(step: done ? total : _step + 1, total: total),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: child)),
          child: done
              ? Column(
                  key: const ValueKey('done'),
                  children: [
                    const SizedBox(height: 24),
                    Sym(Symbols.favorite, size: 56, color: c.accent, fill: true),
                    const SizedBox(height: 12),
                    Text('$_score of $total', style: AppText.display),
                    const SizedBox(height: 6),
                    Text(_score == total ? 'Soulmates. Obviously.' : 'Ask her about the ones you missed 😉', style: AppText.body.copyWith(color: c.textMuted)),
                  ],
                )
              : QuestionCard(
                  key: ValueKey(_step),
                  question: DemoData.quiz[_step].question,
                  options: [for (final o in DemoData.quiz[_step].options) QuestionOption(o)],
                  selected: {?_picked},
                  correct: DemoData.quiz[_step].correct,
                  onSelect: _pick,
                ),
        ),
      ],
    );
  }
}
