import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/question_card.dart';
import '../../core/widgets/segmented.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import '../privacy/safety_emojis.dart';

/// After sign-in: your name → the privacy promise → pair phones → safety emojis.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _steps = 4;
  final _page = PageController();
  int _step = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.slow, curve: Motion.emphasized);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = MediaQuery.paddingOf(context);
    final paired = AppScope.of(context).couple != null;
    // Pairing finished (here or on the partner's phone): show the emojis.
    if (paired && _step == 2) WidgetsBinding.instance.addPostFrameCallback((_) => _go(3));
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0 && _step < 3) _go(_step - 1);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientGlow()),
            Padding(
              padding: EdgeInsets.only(top: pad.top + 16),
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: StepProgress(step: _step + 1, total: _steps)),
                  Expanded(
                    child: PageView(
                      controller: _page,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _NameStep(onNext: () => _go(1)),
                        _PromiseStep(onNext: () => _go(2)),
                        const _PairStep(),
                        _EmojiStep(
                          onDone: widget.onFinished,
                          onMismatch: () async {
                            await AppScope.read(context).backend.unlink();
                            _go(2);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared layout for a step: title, body, then a button pinned at the bottom.
class _Step extends StatelessWidget {
  const _Step({required this.title, this.subtitle, required this.child, this.button});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 28, 24, bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FadePop(child: Text(title, style: AppText.largeTitle)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            FadePop(delay: const Duration(milliseconds: 60), child: Text(subtitle!, style: AppText.body.copyWith(color: c.textMuted))),
          ],
          const SizedBox(height: 28),
          Expanded(child: SingleChildScrollView(child: FadePop(delay: const Duration(milliseconds: 120), child: child))),
          if (button != null) ...[const SizedBox(height: 12), FadePop(delay: const Duration(milliseconds: 180), child: button!)],
        ],
      ),
    );
  }
}

class _NameStep extends StatefulWidget {
  const _NameStep({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final _name = TextEditingController(text: AppScope.read(context).account?.name ?? '');

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final name = _name.text.trim();
    final backend = AppScope.read(context).backend;
    widget.onNext();
    try {
      await backend.updateName(name);
    } on Exception {
      // The name can be changed later in Profile.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Step(
      title: 'What should your partner call you?',
      button: GradientButton(label: 'Continue', onTap: _name.text.trim().isEmpty ? null : _next),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(20)),
        child: TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          style: AppText.title.copyWith(color: c.text),
          onSubmitted: (_) => _name.text.trim().isEmpty ? null : _next(),
          decoration: InputDecoration(border: InputBorder.none, hintText: 'Your first name', hintStyle: AppText.title.copyWith(color: c.textFaint)),
        ),
      ),
    );
  }
}

class _PromiseStep extends StatelessWidget {
  const _PromiseStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const points = [
      (Symbols.lock, 'Only the two of you can read it', 'Messages, photos, answers and locations are encrypted on your phones.'),
      (Symbols.smartphone, 'Protection runs on your phone', 'Scam-link and photo guards never send your chats anywhere.'),
      (Symbols.location_on, 'You choose what to share', 'Location is always mutual, time-limited and easy to stop.'),
    ];
    return _Step(
      title: 'Private by design',
      subtitle: 'Before you pair, here’s our promise.',
      button: GradientButton(label: 'Sounds good', onTap: onNext),
      child: Column(
        children: [
          for (final (icon, title, body) in points) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: icon, size: 44, iconSize: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.subhead),
                      const SizedBox(height: 2),
                      Text(body, style: AppText.small.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class _PairStep extends StatefulWidget {
  const _PairStep();

  @override
  State<_PairStep> createState() => _PairStepState();
}

class _PairStepState extends State<_PairStep> {
  bool _haveCode = false;
  Future<Invite>? _invite;
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _invite ??= AppScope.read(context).backend.createInvite();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).backend.acceptInvite(_code.text);
      HapticFeedback.mediumImpact();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Step(
      title: 'Pair your phones',
      subtitle: 'One of you shares an invite, the other enters the code.',
      button: _haveCode ? GradientButton(label: 'Pair', icon: Symbols.link, busy: _busy, onTap: _join) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Segmented<bool>(
            value: _haveCode,
            onChanged: (v) => setState(() {
              _haveCode = v;
              _error = null;
            }),
            segments: const [Segment(false, 'Invite', icon: Symbols.qr_code_2), Segment(true, 'I have a code', icon: Symbols.keyboard)],
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: Motion.medium,
            child: _haveCode
                ? Column(
                    key: const ValueKey('code'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(20), border: Border.all(color: _error != null ? c.danger : Colors.transparent)),
                        child: TextField(
                          controller: _code,
                          textCapitalization: TextCapitalization.characters,
                          textAlign: TextAlign.center,
                          style: AppText.title.copyWith(color: c.text, letterSpacing: 4),
                          onSubmitted: (_) => _join(),
                          decoration: InputDecoration(border: InputBorder.none, hintText: 'XXXX-XXXX', hintStyle: AppText.title.copyWith(color: c.textFaint, letterSpacing: 4)),
                        ),
                      ),
                      if (_error != null) ...[const SizedBox(height: 8), Text(_error!, textAlign: TextAlign.center, style: AppText.small.copyWith(color: c.danger))],
                    ],
                  )
                : FutureBuilder<Invite>(
                    key: const ValueKey('invite'),
                    future: _invite,
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Text('Couldn’t create an invite. ${snap.error}', textAlign: TextAlign.center, style: AppText.small.copyWith(color: c.danger));
                      }
                      final invite = snap.data;
                      return Column(
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: cardShadow(c)),
                            child: invite == null
                                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                                : QrImageView(data: invite.qrPayload, padding: EdgeInsets.zero, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF1C1023)), dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF1C1023))),
                          ),
                          const SizedBox(height: 18),
                          Text('or share this code', style: AppText.small.copyWith(color: c.textMuted)),
                          const SizedBox(height: 4),
                          SelectableText(invite?.code ?? '····-····', style: AppText.display.copyWith(letterSpacing: 4)),
                          const SizedBox(height: 10),
                          if (invite != null)
                            TonalButton(
                              label: 'Copy code',
                              icon: Symbols.content_copy,
                              expand: false,
                              height: 42,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: invite.code));
                                showToast(context, 'Code copied', icon: Symbols.content_copy);
                              },
                            ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 10),
                              Text('Waiting for your partner…', style: AppText.small.copyWith(color: c.textMuted)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmojiStep extends StatelessWidget {
  const _EmojiStep({required this.onDone, required this.onMismatch});

  final VoidCallback onDone;
  final Future<void> Function() onMismatch;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final couple = state.couple;
    return _Step(
      title: 'Compare your emojis',
      subtitle: couple == null ? null : 'You’re paired with ${couple.partner.name}. Check that both phones show the same four emojis.',
      button: Column(
        children: [
          GradientButton(
            label: 'They match',
            icon: Symbols.verified,
            onTap: () async {
              await state.backend.confirmSafetyEmojis();
              if (context.mounted) showEmojiBurst(context, '💞', count: 10);
              onDone();
            },
          ),
          const SizedBox(height: 8),
          TonalButton(
            label: 'They don’t match',
            color: c.danger,
            onTap: () async {
              final again = await confirmAction(
                context,
                title: 'Pair again?',
                message: 'Different emojis mean the keys don’t match. Pair again, ideally side by side using the QR code.',
                confirm: 'Pair again',
                destructive: true,
              );
              if (again) await onMismatch();
            },
          ),
        ],
      ),
      child: couple == null ? const SizedBox(height: 80) : SafetyEmojiRow(emojis: couple.safetyEmojis),
    );
  }
}
