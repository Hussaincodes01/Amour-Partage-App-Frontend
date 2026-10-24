import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/segmented.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';

/// First screen: what the app is, and sign in.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).backend.signInWithGoogle();
    } on Exception catch (e) {
      if (mounted) showToast(context, '$e', icon: Symbols.error, color: context.colors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientGlow()),
          Padding(
            padding: EdgeInsets.fromLTRB(28, pad.top + 24, 28, pad.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 3),
                const FadePop(child: Center(child: AmourLogo(size: 88))),
                const SizedBox(height: 28),
                FadePop(
                  delay: const Duration(milliseconds: 80),
                  child: Text('A private space for the two of you', textAlign: TextAlign.center, style: AppText.largeTitle.copyWith(fontSize: 32, height: 1.15)),
                ),
                const SizedBox(height: 12),
                FadePop(
                  delay: const Duration(milliseconds: 140),
                  child: Text(
                    'Chat, call, watch together and share where you are. Everything is encrypted on your phones.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: c.textMuted),
                  ),
                ),
                const Spacer(flex: 4),
                FadePop(
                  delay: const Duration(milliseconds: 200),
                  child: _GoogleButton(busy: _busy, onTap: _google),
                ),
                const SizedBox(height: 12),
                FadePop(
                  delay: const Duration(milliseconds: 240),
                  child: TonalButton(label: 'Continue with email', icon: Symbols.mail, height: 54, onTap: () => showAmourSheet<void>(context, builder: (_) => const _EmailSheet())),
                ),
                const SizedBox(height: 16),
                FadePop(
                  delay: const Duration(milliseconds: 280),
                  child: Text('For couples 18+. By continuing you agree to the Terms and Privacy Policy.', textAlign: TextAlign.center, style: AppText.caption.copyWith(color: c.textFaint)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: busy ? null : onTap,
      haptic: PressFeedback.medium,
      semanticLabel: 'Continue with Google',
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: c.isDark ? Colors.white : c.text,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Text('G', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF4285F4))),
            ),
            const SizedBox(width: 10),
            Text(busy ? 'Signing in…' : 'Continue with Google', style: AppText.bodyStrong.copyWith(color: c.isDark ? Colors.black : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _EmailSheet extends StatefulWidget {
  const _EmailSheet();

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = true;
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).backend.signInWithEmail(email: _email.text.trim(), password: _password.text, create: _create);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget field(TextEditingController controller, String hint, IconData icon, {bool password = false}) => Container(
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Sym(icon, size: 20, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: password && _hide,
                  keyboardType: password ? TextInputType.visiblePassword : TextInputType.emailAddress,
                  autofillHints: [password ? (_create ? AutofillHints.newPassword : AutofillHints.password) : AutofillHints.email],
                  style: AppText.body.copyWith(color: c.text),
                  decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: AppText.body.copyWith(color: c.textFaint)),
                ),
              ),
              if (password)
                RoundIconButton(
                  icon: _hide ? Symbols.visibility : Symbols.visibility_off,
                  color: Colors.transparent,
                  iconColor: c.textMuted,
                  size: 40,
                  iconSize: 20,
                  semanticLabel: _hide ? 'Show password' : 'Hide password',
                  onTap: () => setState(() => _hide = !_hide),
                ),
            ],
          ),
        );
    return AmourSheet(
      title: _create ? 'Create your account' : 'Welcome back',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Segmented<bool>(
              value: _create,
              onChanged: (v) => setState(() {
                _create = v;
                _error = null;
              }),
              segments: const [Segment(true, 'New here'), Segment(false, 'I have an account')],
            ),
            const SizedBox(height: 14),
            field(_email, 'Email', Symbols.mail),
            const SizedBox(height: 8),
            field(_password, _create ? 'Password (8+ characters)' : 'Password', Symbols.key, password: true),
            if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: AppText.small.copyWith(color: c.danger))],
            const SizedBox(height: 16),
            GradientButton(label: _create ? 'Create account' : 'Sign in', busy: _busy, onTap: _submit),
          ],
        ),
      ),
    );
  }
}
