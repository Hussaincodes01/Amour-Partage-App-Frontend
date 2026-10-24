import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pulse.dart';
import '../../core/security/biometric.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/couple_state.dart';

/// App lock: covers the app when it comes back from the background (after a
/// short grace period) until the owner unlocks with biometrics.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  static const _grace = Duration(seconds: 30);
  DateTime? _backgroundedAt;
  bool _locked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _backgroundedAt == null ? Duration.zero : DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (!_busy && AppScope.read(context).guard(Guard.appLock) && away > _grace) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_busy) return;
    _busy = true;
    final result = await Biometric.unlock('Unlock Amour Partagé');
    _busy = false;
    if (!mounted) return;
    if (result != BiometricResult.failed) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !_locked,
          child: AnimatedOpacity(
            duration: Motion.medium,
            opacity: _locked ? 1 : 0,
            child: _locked ? _LockScreen(onUnlock: _unlock) : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Spacer(),
                  const Breathing(min: 0.96, max: 1.04, child: AmourLogo(size: 88)),
                  const SizedBox(height: 24),
                  Text('Locked', style: AppText.display),
                  const SizedBox(height: 8),
                  Text('Unlock to see your chats and memories.', style: AppText.body.copyWith(color: c.textMuted), textAlign: TextAlign.center),
                  const Spacer(),
                  GradientButton(label: 'Unlock', icon: Symbols.fingerprint, onTap: onUnlock),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
