import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/question_card.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';

class _Question {
  const _Question(this.question, this.options, this.tip);

  final String question;
  final List<QuestionOption> options;
  final String tip;
}

const _questions = [
  _Question(
    'Where do you usually read your messages?',
    [
      QuestionOption('Mostly at home', icon: Symbols.home),
      QuestionOption('On the train or at work', icon: Symbols.train),
      QuestionOption('Everywhere, honestly', icon: Symbols.public),
    ],
    'Discreet notifications keep message text off your lock screen.',
  ),
  _Question(
    'Does anyone else know your phone’s PIN?',
    [
      QuestionOption('Only my partner', icon: Symbols.favorite),
      QuestionOption('A family member or friend', icon: Symbols.group),
      QuestionOption('Nobody', icon: Symbols.lock),
    ],
    'App lock adds your fingerprint on top of the phone’s PIN.',
  ),
  _Question(
    'Do you ever share your screen or hand your phone to others?',
    [
      QuestionOption('Often', icon: Symbols.cast),
      QuestionOption('Sometimes', icon: Symbols.swap_horiz),
      QuestionOption('Never', icon: Symbols.do_not_touch),
    ],
    'Screenshot blocking also hides the app in your recent apps.',
  ),
];

/// Three questions that switch on the right protections.
class PrivacyCheckupScreen extends StatefulWidget {
  const PrivacyCheckupScreen({super.key});

  @override
  State<PrivacyCheckupScreen> createState() => _PrivacyCheckupScreenState();
}

class _PrivacyCheckupScreenState extends State<PrivacyCheckupScreen> {
  int _step = 0;
  final List<int?> _answers = List.filled(_questions.length, null);
  Timer? _advance;

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _pick(int i) {
    setState(() => _answers[_step] = i);
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (_step == _questions.length - 1) _apply();
      setState(() => _step++);
    });
  }

  void _apply() {
    final state = AppScope.read(context);
    if (_answers[0] != 0) state.setGuard(Guard.discreet, true);
    if (_answers[1] != 2) state.setGuard(Guard.appLock, true);
    if (_answers[2] != 2) state.setGuard(Guard.screenshots, true);
    showEmojiBurst(context, '🛡️', count: 8);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = _step >= _questions.length;
    return SubPage(
      title: 'Privacy check-up',
      bottom: done ? GradientButton(label: 'Done', onTap: () => Navigator.of(context).pop()) : null,
      children: [
        StepProgress(step: done ? _questions.length : _step + 1, total: _questions.length),
        AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a), child: child),
          ),
          child: done
              ? Column(
                  key: const ValueKey('done'),
                  children: [
                    const SizedBox(height: 24),
                    Sym(Symbols.verified_user, size: 56, color: c.success, fill: true),
                    const SizedBox(height: 12),
                    Text('All set', style: AppText.display),
                    const SizedBox(height: 6),
                    Text('We switched on the protections that fit how you use your phone.', textAlign: TextAlign.center, style: AppText.body.copyWith(color: c.textMuted)),
                  ],
                )
              : Column(
                  key: ValueKey(_step),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestionCard(
                      question: _questions[_step].question,
                      options: _questions[_step].options,
                      selected: {?_answers[_step]},
                      onSelect: _pick,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Sym(Symbols.lightbulb, size: 16, color: c.textFaint),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_questions[_step].tip, style: AppText.small.copyWith(color: c.textFaint))),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
