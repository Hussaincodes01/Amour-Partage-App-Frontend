import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/question_card.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/mock.dart';

/// "How well do you know me?" — animated couple quiz.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _picked;

  void _pick(int i) {
    if (_picked != null) return;
    final q = Mock.quiz[_index];
    final right = i == q.correct;
    setState(() {
      _picked = i;
      if (right) _score++;
    });
    if (right) {
      HapticFeedback.mediumImpact();
      showEmojiBurst(context, '💖', count: 6);
    } else {
      HapticFeedback.vibrate();
    }
    Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _index++;
        _picked = null;
      });
      if (_index == Mock.quiz.length) showEmojiBurst(context, '🎉', count: 12);
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= Mock.quiz.length;
    return SubPage(
      title: 'Couple Quiz',
      subtitle: 'How well do you know ${Mock.partner}?',
      children: [
        StepProgress(step: done ? Mock.quiz.length : _index + 1, total: Mock.quiz.length, label: done ? 'Finished' : 'Score $_score'),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(a), child: c),
          ),
          child: done
              ? _Score(key: const ValueKey('score'), score: _score, total: Mock.quiz.length, onAgain: () => setState(() {
                    _index = 0;
                    _score = 0;
                  }))
              : QuestionCard(
                  key: ValueKey(_index),
                  label: 'QUESTION ${_index + 1}',
                  icon: Symbols.quiz,
                  question: Mock.quiz[_index].question,
                  options: [for (final o in Mock.quiz[_index].options) QuestionOption(o)],
                  selected: {?_picked},
                  correct: Mock.quiz[_index].correct,
                  onSelect: _pick,
                ),
        ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({super.key, required this.score, required this.total, required this.onAgain});

  final int score;
  final int total;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final perfect = score == total;
    return AmourCard(
      color: AppColors.surfaceLow,
      blooms: [Bloom(color: AppColors.hotPink.withValues(alpha: 0.22), size: 240, right: -80, top: -80)],
      child: Column(
        children: [
          Text(perfect ? '🏆' : '💞', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text('$score / $total', style: AppText.display.copyWith(fontSize: 44, height: 1.1)),
          const SizedBox(height: 6),
          Text(
            perfect ? 'Soulmate level. ${Mock.partner} will be impressed.' : 'Cute! Ask ${Mock.partner} about the ones you missed tonight.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Challenge ${Mock.partner}', leadingIcon: Symbols.send, gradient: AppGradients.pinkViolet, onTap: () {
            showLoveToast(context, 'Quiz sent to ${Mock.partner}', icon: Symbols.quiz);
            Navigator.of(context).pop();
          }),
          const SizedBox(height: 10),
          GradientButton(
            label: 'Play again',
            gradient: const LinearGradient(colors: [AppColors.surfaceHigh, AppColors.surfaceHigh]),
            glowColor: const Color(0x00000000),
            onTap: onAgain,
          ),
        ],
      ),
    );
  }
}
