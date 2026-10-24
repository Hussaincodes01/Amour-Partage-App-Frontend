import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/demo_images.dart';
import 'onboarding_flow.dart';

/// First screen: what the app is + sign in (email magic link or Google).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) => context.replaceWithPop(const OnboardingFlow());

  void _email(BuildContext context) {
    showAmourSheet(context, builder: (_) => _EmailSheet(onDone: () => _start(context)));
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned(left: -100, top: -40, child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.3), size: 420)),
          Positioned(right: -140, top: 220, child: GlowBlob(color: AppColors.violet.withValues(alpha: 0.4), size: 440)),
          Padding(
            padding: EdgeInsets.fromLTRB(24, pad.top + 24, 24, pad.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FadePop(child: Align(alignment: Alignment.centerLeft, child: AmourLogo(size: 44))),
                const Spacer(),
                FadePop(
                  delay: const Duration(milliseconds: 80),
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned(left: 20, child: Breathing(min: 0.97, max: 1.03, breaths: 3, child: Avatar(image: DemoImages.julian, size: 104, ring: AppGradients.avatarRing, ringWidth: 3))),
                          const Positioned(right: 20, child: Breathing(min: 0.97, max: 1.03, period: Duration(milliseconds: 2600), breaths: 3, child: Avatar(image: DemoImages.camille, size: 104, ring: AppGradients.avatarRing, ringWidth: 3))),
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.hotPink,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.bg, width: 3),
                              boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.5), blurRadius: 16)],
                            ),
                            child: const Sym(Symbols.favorite, size: 20, color: Colors.white, fill: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadePop(
                  delay: const Duration(milliseconds: 140),
                  child: Text.rich(
                    TextSpan(
                      style: AppText.display.copyWith(fontSize: 34, height: 1.15, letterSpacing: -1),
                      children: [
                        const TextSpan(text: 'A private space for '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: ShaderMask(
                            shaderCallback: (r) => AppGradients.pinkLavender.createShader(r),
                            child: Text('the two of you', style: AppText.display.copyWith(fontSize: 34, height: 1.15, letterSpacing: -1, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                FadePop(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Chat, call, watch and listen together, share where you are — protected by an AI shield that never reads your messages.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                  ),
                ),
                const Spacer(),
                FadePop(
                  delay: const Duration(milliseconds: 260),
                  child: Pressable(
                    onTap: () => _email(context),
                    haptic: PressFeedback.medium,
                    child: Container(
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                      child: Text('Continue with Email', style: AppText.bodyStrong.copyWith(color: AppColors.bg)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadePop(
                  delay: const Duration(milliseconds: 300),
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR CONTINUE WITH', style: AppText.label.copyWith(letterSpacing: 1))),
                      Expanded(child: Container(height: 1, color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadePop(
                  delay: const Duration(milliseconds: 340),
                  child: Pressable(
                    // Google Sign-In is wired with the auth backend; the UI continues straight on.
                    onTap: () => _start(context),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.only(left: 20, right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text('Continue with Google', style: AppText.bodyStrong)),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Text('G', style: AppText.subhead.copyWith(color: const Color(0xFF4285F4), fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadePop(
                  delay: const Duration(milliseconds: 380),
                  child: Text(
                    'By continuing you agree to our Terms of Service and Privacy Policy. 18+ only.',
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(color: AppColors.outline, height: 1.6),
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

class _EmailSheet extends StatefulWidget {
  const _EmailSheet({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  final _email = TextEditingController();
  bool _sent = false;

  bool get _valid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmourSheet(
      title: _sent ? 'Check your inbox' : 'Continue with Email',
      subtitle: _sent ? 'We sent a magic link to ${_email.text.trim()}' : 'No passwords — we’ll email you a magic link',
      icon: _sent ? Symbols.mark_email_read : Symbols.mail,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _sent
            ? Column(
                key: const ValueKey('sent'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: Text('💌', style: TextStyle(fontSize: 56))),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'I’ve opened the link',
                    gradient: AppGradients.pinkViolet,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onDone();
                    },
                  ),
                ],
              )
            : Column(
                key: const ValueKey('form'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    style: AppText.body,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bg,
                      hintText: 'you@example.com',
                      hintStyle: AppText.body.copyWith(color: AppColors.outline),
                      prefixIcon: const Padding(padding: EdgeInsets.all(12), child: Sym(Symbols.mail, size: 20, color: AppColors.outline)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientButton(label: 'Send magic link', icon: Symbols.arrow_forward, onTap: _valid ? () => setState(() => _sent = true) : null),
                ],
              ),
      ),
    );
  }
}
