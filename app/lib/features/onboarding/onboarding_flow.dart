import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/security/biometric.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/question_card.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../shield/app_lock.dart';
import '../shield/shield_widgets.dart';

/// Four animated onboarding steps:
/// 1 About us · 2 AI Privacy Sanctuary (Figma) · 3 Pair devices · 4 Safety check.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pages = PageController();
  int _step = 0;

  static const _labels = ['About Us', 'Bonding Rituals', 'Pair Devices', 'Safety Check'];

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _pages.animateToPage(step, duration: Motion.slow, curve: Motion.emphasized);
  }

  void _finish() => context.resetTo(const AppLockGate(child: MainShell()));

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _go(_step - 1);
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            Positioned(left: -48, top: -64, child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.18), size: 300)),
            Positioned(right: -80, top: 344, child: GlowBlob(color: AppColors.violet.withValues(alpha: 0.3), size: 330)),
            PageView(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AboutStep(onNext: () => _go(1), step: 1, label: _labels[0]),
                _SanctuaryStep(onNext: () => _go(2), step: 2, label: _labels[1]),
                _PairStep(onNext: () => _go(3), step: 3, label: _labels[2]),
                _SafetyStep(onFinish: _finish, step: 4, label: _labels[3]),
              ],
            ),
            if (_step > 0)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                child: FadePop(
                  child: RoundIconButton(icon: Symbols.arrow_back, size: 40, iconSize: 20, color: AppColors.surfaceHigh, semanticLabel: 'Back', onTap: () => _go(_step - 1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable step body with a pinned CTA.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.children, required this.cta, this.footer});

  final List<Widget> children;
  final Widget cta;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, pad.top + 24, 16, 24),
            itemCount: children.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 24),
              child: FadePop.index(i, child: children[i]),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, pad.bottom + 16),
          child: Column(
            children: [
              cta,
              if (footer != null) ...[const SizedBox(height: 8), footer!],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.badge, required this.title, required this.subtitle, required this.hero});

  final String badge;
  final String title;
  final String subtitle;
  final Widget hero;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        hero,
        const SizedBox(height: 8),
        Tag(
          label: badge,
          dot: const Dot(color: AppColors.mint, size: 8, glow: true),
          background: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          style: AppText.label.copyWith(letterSpacing: 1),
          gap: 2,
        ),
        const SizedBox(height: 8),
        Text(title, style: AppText.display, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(subtitle, textAlign: TextAlign.center, style: AppText.small.copyWith(color: AppColors.outline, height: 19.5 / 12)),
        ),
      ],
    );
  }
}

// ── Step 1 ──────────────────────────────────────────────────────────────────

class _AboutStep extends StatefulWidget {
  const _AboutStep({required this.onNext, required this.step, required this.label});

  final VoidCallback onNext;
  final int step;
  final String label;

  @override
  State<_AboutStep> createState() => _AboutStepState();
}

class _AboutStepState extends State<_AboutStep> {
  final _name = TextEditingController(text: Mock.me);
  DateTime _since = DateTime(2025, 8, 22);
  final Set<int> _language = {1};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _since,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.hotPink, surface: AppColors.surfaceLow),
          datePickerTheme: const DatePickerThemeData(backgroundColor: AppColors.surfaceLow),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _since = picked);
  }

  String get _sinceLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_since.month - 1]} ${_since.day}, ${_since.year}';
  }

  @override
  Widget build(BuildContext context) {
    final days = DateTime.now().difference(_since).inDays;
    return _StepScaffold(
      cta: GradientButton(label: 'Continue', icon: Symbols.arrow_forward, iconSize: 14, onTap: _name.text.trim().isEmpty ? null : widget.onNext),
      children: [
        _StepHeader(
          badge: 'JUST THE TWO OF YOU',
          title: 'Let’s set up Our Space',
          subtitle: 'A few playful questions so Amour AI can make this place feel like yours.',
          hero: const AmourLogo(size: 72),
        ),
        StepProgress(step: widget.step, total: 4, label: widget.label),
        AmourCard(
          color: AppColors.surfaceLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('WHAT SHOULD ${Mock.partner.toUpperCase()} CALL YOU?', style: AppText.label.copyWith(color: AppColors.lavender)),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                style: AppText.headline,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg,
                  hintText: 'Your name or a cute nickname',
                  hintStyle: AppText.body.copyWith(color: AppColors.outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text('WHEN DID YOUR STORY BEGIN?', style: AppText.label.copyWith(color: AppColors.lavender)),
              const SizedBox(height: 8),
              Pressable(
                pressedScale: 0.98,
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    children: [
                      const Sym(Symbols.favorite, size: 18, color: AppColors.hotPink, fill: true),
                      const SizedBox(width: 10),
                      Text(_sinceLabel, style: AppText.bodyStrong),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: Motion.medium,
                        child: Text('$days days', key: ValueKey(days), style: AppText.label.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        QuestionCard(
          label: 'GETTING TO KNOW YOU',
          icon: Symbols.favorite,
          question: 'How do you feel most loved?',
          options: const [
            QuestionOption('Sweet words & voice notes', icon: Symbols.record_voice_over, color: AppColors.primary),
            QuestionOption('Quality time together', icon: Symbols.schedule, color: AppColors.lavender),
            QuestionOption('Little surprises', icon: Symbols.redeem, color: AppColors.mint),
            QuestionOption('Hugs & closeness', icon: Symbols.volunteer_activism, color: AppColors.hotPink),
          ],
          selected: _language,
          helper: 'Amour AI uses this to suggest your daily Soul Sparks.',
          onSelect: (i) => setState(() {
            _language
              ..clear()
              ..add(i);
          }),
        ),
      ],
    );
  }
}

// ── Step 2 (Figma: AI Privacy Sanctuary) ────────────────────────────────────

class _SanctuaryStep extends StatefulWidget {
  const _SanctuaryStep({required this.onNext, required this.step, required this.label});

  final VoidCallback onNext;
  final int step;
  final String label;

  @override
  State<_SanctuaryStep> createState() => _SanctuaryStepState();
}

class _SanctuaryStepState extends State<_SanctuaryStep> {
  final Set<int> _habits = {1};

  static const _options = [
    QuestionOption('Watching YouTube synced', icon: Symbols.tv, color: AppColors.primary),
    QuestionOption('Midnight music listening', icon: Symbols.headphones, color: AppColors.primary),
    QuestionOption('Long encrypted voice notes', icon: Symbols.mic, color: AppColors.lavender),
    QuestionOption('Silent screen presence', icon: Symbols.dark_mode, color: AppColors.mint),
    QuestionOption('Surprise memory photos', icon: Symbols.photo_library, color: AppColors.primary),
  ];

  Future<void> _toggleBiometric() async {
    final state = AppScope.read(context);
    if (!state.biometricLock) {
      final r = await Biometric.unlock('Turn on Biometric Couple Lock');
      if (r == BiometricResult.failed || !mounted) return;
    }
    state.toggle('biometric');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _StepScaffold(
      cta: GradientButton(
        label: 'Authorize AI Privacy & Pair Devices',
        icon: Symbols.arrow_forward,
        iconSize: 14,
        textStyle: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
        onTap: widget.onNext,
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Sym(Symbols.lock, size: 14, color: AppColors.mint, fill: true),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Both partners hold exclusive zero-knowledge cryptographic keys.', textAlign: TextAlign.center, style: AppText.label.copyWith(color: AppColors.outline)),
          ),
        ],
      ),
      children: [
        const _StepHeader(
          badge: 'ZERO-KNOWLEDGE COUPLE VAULT',
          title: 'AI Privacy Sanctuary',
          subtitle: 'Your late-night intimate habits & notes are cryptographically shielded before AI ever reads them.',
          hero: PulsingShield(),
        ),
        StepProgress(step: widget.step, total: 4, label: widget.label),
        QuestionCard(
          question: 'What is your favorite late-night shared habit?',
          options: _options,
          selected: _habits,
          helper: 'Amour AI adapts suggestions based on selected habits.',
          onSelect: (i) => setState(() => _habits.contains(i) ? _habits.remove(i) : _habits.add(i)),
        ),
        AmourCard(
          color: AppColors.surfaceLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Sym(Symbols.lock_reset, size: 20, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Vault Protocols', style: AppText.headline)),
                  Tag(label: 'E2EE Active', color: AppColors.mint, background: AppColors.mintDeep.withValues(alpha: 0.3)),
                ],
              ),
              const SizedBox(height: 12),
              GuardRow(
                icon: Symbols.fingerprint,
                title: 'Biometric Couple Lock',
                subtitle: 'Fingerprint or face to unveil secret albums',
                value: state.biometricLock,
                onChanged: (_) => _toggleBiometric(),
              ),
              GuardRow(
                icon: Symbols.visibility_off,
                title: 'Anti-Snoop Stealth Mode',
                subtitle: 'Auto-blurs if an unfamiliar face peers over',
                value: false,
                soon: true,
                onChanged: (_) => showComingSoon(context, 'Anti-Snoop Stealth Mode', icon: Symbols.visibility_off),
              ),
              const SizedBox(height: 12),
              const MutualKeyCard(inset: true),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 3: pair devices ────────────────────────────────────────────────────

class _PairStep extends StatefulWidget {
  const _PairStep({required this.onNext, required this.step, required this.label});

  final VoidCallback onNext;
  final int step;
  final String label;

  @override
  State<_PairStep> createState() => _PairStepState();
}

class _PairStepState extends State<_PairStep> {
  static const _myCode = 'X7F4-9B2A';
  final _code = TextEditingController();
  bool _pairing = false;

  bool get _valid => _code.text.replaceAll('-', '').trim().length == 8;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    FocusScope.of(context).unfocus();
    setState(() => _pairing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _pairing = false);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      cta: GradientButton(
        label: _pairing ? 'Exchanging keys…' : 'Pair with ${Mock.partner}',
        leadingIcon: _pairing ? Symbols.sync : Symbols.link,
        gradient: AppGradients.pinkViolet,
        onTap: _valid && !_pairing ? _pair : null,
      ),
      children: [
        const _StepHeader(
          badge: 'IN-PERSON KEY EXCHANGE',
          title: 'Pair your phones',
          subtitle: 'Hold your phones together. Your keys are exchanged directly — our servers never see them.',
          hero: SizedBox(
            width: 140,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(left: 12, child: Avatar(image: DemoImages.julian, size: 64, ring: AppGradients.avatarRing, ringWidth: 2)),
                Positioned(right: 12, child: Avatar(image: DemoImages.camille, size: 64, ring: AppGradients.avatarRing, ringWidth: 2)),
              ],
            ),
          ),
        ),
        StepProgress(step: widget.step, total: 4, label: widget.label),
        AmourCard(
          color: AppColors.surfaceLow,
          child: Column(
            children: [
              Text('YOUR INVITE CODE', style: AppText.label.copyWith(color: AppColors.lavender)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.25), blurRadius: 24)],
                ),
                child: QrImageView(
                  data: 'amourpartage://pair/$_myCode',
                  size: 168,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Color(0xFF2C0051)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFFB90066)),
                ),
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: _myCode));
                  showLoveToast(context, 'Invite code copied', icon: Symbols.content_copy, color: AppColors.mint);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_myCode, style: AppText.mono.copyWith(fontSize: 22, height: 1.2, color: AppColors.primary, letterSpacing: 3)),
                    const SizedBox(width: 8),
                    const Sym(Symbols.content_copy, size: 18, color: AppColors.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
        ),
        AmourCard(
          color: AppColors.surfaceLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('OR ENTER ${Mock.partner.toUpperCase()}’S CODE', style: AppText.label.copyWith(color: AppColors.lavender)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 9,
                      style: AppText.mono.copyWith(fontSize: 18, height: 1.3, color: AppColors.onSurface, letterSpacing: 2),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.bg,
                        hintText: 'XXXX-XXXX',
                        hintStyle: AppText.mono.copyWith(fontSize: 18, height: 1.3, color: AppColors.outline, letterSpacing: 2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    icon: Symbols.qr_code_scanner,
                    size: 52,
                    iconSize: 24,
                    color: AppColors.surfaceHigh,
                    iconColor: AppColors.primary,
                    semanticLabel: 'Scan QR code',
                    onTap: () => showComingSoon(context, 'QR scanner', icon: Symbols.qr_code_scanner, detail: 'Camera scanning arrives with the next build. For now, type the 8-character code from your partner’s screen.'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Step 4: safety emoji check ──────────────────────────────────────────────

class _SafetyStep extends StatefulWidget {
  const _SafetyStep({required this.onFinish, required this.step, required this.label});

  final VoidCallback onFinish;
  final int step;
  final String label;

  @override
  State<_SafetyStep> createState() => _SafetyStepState();
}

class _SafetyStepState extends State<_SafetyStep> {
  bool _matched = false;

  void _match() {
    HapticFeedback.heavyImpact();
    setState(() => _matched = true);
    showEmojiBurst(context, '💞', count: 12);
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      cta: AnimatedSwitcher(
        duration: Motion.medium,
        child: _matched
            ? GradientButton(key: const ValueKey('enter'), label: 'Enter Our Space', icon: Symbols.arrow_forward, iconSize: 14, gradient: AppGradients.pinkViolet, onTap: widget.onFinish)
            : Row(
                key: const ValueKey('check'),
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: () => showLoveToast(context, 'Don’t continue — re-pair in person', icon: Symbols.warning, color: AppColors.error),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                        child: Text('They differ', style: AppText.bodyStrong.copyWith(color: AppColors.onSurfaceVariant)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: GradientButton(label: 'They match', leadingIcon: Symbols.check_circle, gradient: AppGradients.mintTab, glowColor: AppColors.mint, onTap: _match)),
                ],
              ),
      ),
      children: [
        _StepHeader(
          badge: 'MAN-IN-THE-MIDDLE CHECK',
          title: _matched ? 'You’re paired! 💞' : 'Compare your emojis',
          subtitle: _matched
              ? 'Your private space is ready. Everything from here on is end-to-end encrypted.'
              : 'Both phones show four emojis made from your shared key. If they match, nobody is listening in.',
          hero: const PulsingShield(),
        ),
        StepProgress(step: widget.step, total: 4, label: _matched ? 'Done' : widget.label),
        AmourCard(
          color: AppColors.surfaceLow,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < MutualKeyCard.safetyEmojis.length; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 500 + i * 160),
                      curve: Motion.pop,
                      builder: (context, t, child) => Transform.scale(scale: t, child: child),
                      child: AnimatedContainer(
                        duration: Motion.medium,
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _matched ? AppColors.mint.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _matched ? AppColors.mint.withValues(alpha: 0.5) : Colors.transparent),
                        ),
                        child: Text(MutualKeyCard.safetyEmojis[i], style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Key fingerprint  0x7F49 A1C3 5E08 9B2A', style: AppText.mono.copyWith(color: AppColors.primary, fontSize: 11)),
            ],
          ),
        ),
        Row(
          children: [
            const AmourSwitch(value: true, onChanged: null),
            const SizedBox(width: 12),
            Expanded(child: Text('Remind me to re-verify if either of us changes phones', style: AppText.small)),
          ],
        ),
      ],
    );
  }
}
