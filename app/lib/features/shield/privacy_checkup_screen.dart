import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/question_card.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/mock.dart';

class _CheckupQuestion {
  const _CheckupQuestion(this.question, this.options, this.helper);

  final String question;
  final List<QuestionOption> options;
  final String helper;
}

const _questions = [
  _CheckupQuestion(
    'Where do you usually read our messages?',
    [
      QuestionOption('Mostly at home', icon: Symbols.home, color: AppColors.lavender),
      QuestionOption('On the train or at work', icon: Symbols.train, color: AppColors.primary),
      QuestionOption('Everywhere, honestly', icon: Symbols.public, color: AppColors.mint),
    ],
    'We’ll tune notification privacy to match.',
  ),
  _CheckupQuestion(
    'Does anyone else know your phone’s PIN?',
    [
      QuestionOption('Only ${Mock.partner}', icon: Symbols.favorite, color: AppColors.hotPink),
      QuestionOption('A family member', icon: Symbols.family_restroom, color: AppColors.lavender),
      QuestionOption('Nobody', icon: Symbols.lock, color: AppColors.mint),
    ],
    'Biometric Couple Lock adds a second, personal layer.',
  ),
  _CheckupQuestion(
    'How long should live location stay on by default?',
    [
      QuestionOption('1 hour, then ask me', icon: Symbols.timer, color: AppColors.mint),
      QuestionOption('8 hours', icon: Symbols.schedule, color: AppColors.lavender),
      QuestionOption('Until I stop it', icon: Symbols.all_inclusive, color: AppColors.primary),
    ],
    'Shorter windows are safer — you can always extend.',
  ),
];

/// Playful privacy check-up that adjusts the guards from your answers.
class PrivacyCheckupScreen extends StatefulWidget {
  const PrivacyCheckupScreen({super.key});

  @override
  State<PrivacyCheckupScreen> createState() => _PrivacyCheckupScreenState();
}

class _PrivacyCheckupScreenState extends State<PrivacyCheckupScreen> {
  int _step = 0;
  final List<int?> _answers = List.filled(_questions.length, null);

  void _pick(int i) {
    setState(() => _answers[_step] = i);
    Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      if (_step < _questions.length - 1) {
        setState(() => _step++);
      } else {
        _apply();
        setState(() => _step = _questions.length);
      }
    });
  }

  void _apply() {
    final state = AppScope.read(context);
    if (_answers[0] != 0 && !state.discreetNotifications) state.toggle('discreet');
    if (!state.biometricLock) state.toggle('biometric');
    state.setLocationShare(switch (_answers[2]) {
      1 => LocationShare.eightHours,
      2 => LocationShare.untilStopped,
      _ => LocationShare.oneHour,
    });
    showEmojiBurst(context, '🛡️', count: 8);
  }

  @override
  Widget build(BuildContext context) {
    final done = _step >= _questions.length;
    return SubPage(
      title: 'Privacy Check-up',
      subtitle: 'Amour AI • on-device',
      children: [
        StepProgress(step: done ? _questions.length : _step + 1, total: _questions.length, label: done ? 'All set' : 'Question ${_step + 1}'),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a), child: child),
          ),
          child: done
              ? _Result(key: const ValueKey('done'), onFinish: () => Navigator.of(context).pop())
              : QuestionCard(
                  key: ValueKey(_step),
                  label: 'PRIVACY PROMPT ${_step + 1}',
                  icon: Symbols.psychology,
                  question: _questions[_step].question,
                  options: _questions[_step].options,
                  selected: {?_answers[_step]},
                  helper: _questions[_step].helper,
                  onSelect: _pick,
                ),
        ),
      ],
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return AmourCard(
      color: AppColors.surfaceLow,
      blooms: [Bloom(color: AppColors.mint.withValues(alpha: 0.18), size: 220, right: -70, top: -70)],
      child: Column(
        children: [
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 96),
            duration: const Duration(milliseconds: 1200),
            curve: Motion.emphasized,
            builder: (context, v, _) => Text('${v.round()}', style: AppText.display.copyWith(fontSize: 56, height: 1, color: AppColors.mint)),
          ),
          Text('PRIVACY SCORE', style: AppText.label.copyWith(color: AppColors.mint, letterSpacing: 1)),
          const SizedBox(height: 16),
          for (final (i, line) in const [
            'Biometric Couple Lock is on',
            'Discreet notifications tuned to where you read',
            'Live location defaults to your chosen window',
          ].indexed)
            FadePop(
              delay: Duration(milliseconds: 200 + i * 120),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Sym(Symbols.check_circle, size: 18, color: AppColors.mint, fill: true),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line, style: AppText.body)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          GradientButton(label: 'Back to AI Shield', onTap: onFinish, gradient: AppGradients.mintTab, glowColor: AppColors.mint),
        ],
      ),
    );
  }
}
