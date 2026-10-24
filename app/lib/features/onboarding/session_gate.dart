import 'package:flutter/material.dart';

import '../../app/shell.dart';
import '../../core/motion/motion.dart';
import '../../data/couple_state.dart';
import '../privacy/app_lock.dart';
import 'onboarding_flow.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

/// Picks the first screen from the session: welcome → pairing → the app.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  bool _splashDone = false;

  /// Stays true until onboarding finishes, so the safety-emoji step still
  /// shows after pairing succeeds.
  bool _onboarding = false;

  @override
  Widget build(BuildContext context) {
    final phase = AppScope.of(context).phase;
    if (phase == SessionPhase.unpaired) _onboarding = true;
    if (phase == SessionPhase.signedOut) _onboarding = false;
    final Widget screen;
    if (!_splashDone || phase == SessionPhase.loading) {
      screen = SplashScreen(key: const ValueKey('splash'), onDone: () => setState(() => _splashDone = true));
    } else if (phase == SessionPhase.signedOut) {
      screen = const WelcomeScreen(key: ValueKey('welcome'));
    } else if (_onboarding) {
      screen = OnboardingFlow(key: const ValueKey('onboarding'), onFinished: () => setState(() => _onboarding = false));
    } else {
      screen = const AppLockGate(key: ValueKey('app'), child: MainShell());
    }
    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.emphasized,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(a), child: child),
      ),
      child: screen,
    );
  }
}
