import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'buttons.dart';
import 'symbol.dart';

Widget _popTransition(BuildContext context, Animation<double> animation, Animation<double> _, Widget child) {
  final pop = CurvedAnimation(parent: animation, curve: Motion.pop, reverseCurve: Curves.easeInCubic);
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Motion.fadeIn),
    child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(pop), child: child),
  );
}

/// Centered dialog card used by the pop-ups below.
class _DialogCard extends StatelessWidget {
  const _DialogCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: c.isDark ? 0.6 : 0.18), blurRadius: 40, offset: const Offset(0, 16))],
            ),
            child: DefaultTextStyle(style: AppText.body.copyWith(color: c.text), child: child),
          ),
        ),
      ),
    );
  }
}

/// Small "Coming soon" pop-up for features scheduled after the beta.
Future<void> showComingSoon(BuildContext context, String feature, {IconData icon = Symbols.rocket_launch, String? detail}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x80050308),
    transitionDuration: Motion.slow,
    transitionBuilder: _popTransition,
    pageBuilder: (context, _, _) {
      final c = context.colors;
      return _DialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.pinkViolet),
              child: Sym(icon, size: 26, color: Colors.white, fill: true),
            ),
            const SizedBox(height: 14),
            Text('COMING SOON', style: AppText.label.copyWith(color: c.lavender)),
            const SizedBox(height: 6),
            Text(feature, textAlign: TextAlign.center, style: AppText.headline),
            const SizedBox(height: 6),
            Text(
              detail ?? 'We’re finishing this after the beta. It will switch on for both of you at the same time.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 20),
            GradientButton(label: 'Got it', height: 46, onTap: () => Navigator.of(context).pop()),
          ],
        ),
      );
    },
  );
}

/// Confirmation dialog in the app's style.
Future<bool> confirmAction(BuildContext context, {required String title, required String message, required String confirm, bool destructive = false}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x80050308),
    transitionDuration: Motion.medium,
    transitionBuilder: _popTransition,
    pageBuilder: (context, _, _) {
      final c = context.colors;
      return _DialogCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.headline),
            const SizedBox(height: 8),
            Text(message, style: AppText.small.copyWith(color: c.textMuted)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TonalButton(label: 'Cancel', height: 44, onTap: () => Navigator.of(context).pop(false))),
                const SizedBox(width: 10),
                Expanded(
                  child: destructive
                      ? TonalButton(label: confirm, height: 44, color: c.danger, onTap: () => Navigator.of(context).pop(true))
                      : GradientButton(label: confirm, height: 44, onTap: () => Navigator.of(context).pop(true)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

/// Short toast that pops in near the top and fades away.
void showToast(BuildContext context, String message, {IconData icon = Symbols.favorite, Color? color}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Toast(message: message, icon: icon, color: color, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.icon, required this.color, required this.onDone});

  final String message;
  final IconData icon;
  final Color? color;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow, reverseDuration: Motion.medium);

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = widget.color ?? c.accent;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _c,
            child: ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Motion.pop, reverseCurve: Curves.easeIn)),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.border),
                    boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: c.isDark ? 0.5 : 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Sym(widget.icon, size: 18, color: accent, fill: true),
                      const SizedBox(width: 8),
                      Flexible(child: Text(widget.message, style: AppText.smallStrong.copyWith(color: c.text))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating emoji burst launched from a point on screen.
void showEmojiBurst(BuildContext context, String emoji, {Offset? from, int count = 7}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final box = context.findRenderObject() as RenderBox?;
  final origin = from ?? (box != null && box.hasSize ? box.localToGlobal(box.size.center(Offset.zero)) : MediaQuery.sizeOf(context).center(Offset.zero));
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _EmojiBurst(emoji: emoji, origin: origin, count: count, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _EmojiBurst extends StatefulWidget {
  const _EmojiBurst({required this.emoji, required this.origin, required this.count, required this.onDone});

  final String emoji;
  final Offset origin;
  final int count;
  final VoidCallback onDone;

  @override
  State<_EmojiBurst> createState() => _EmojiBurstState();
}

class _EmojiBurstState extends State<_EmojiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List.generate(widget.count, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.6;
      return _Particle(
        dx: math.cos(angle) * (50 + rnd.nextDouble() * 80),
        dy: math.sin(angle) * (120 + rnd.nextDouble() * 110),
        delay: rnd.nextDouble() * 0.25,
        size: 20 + rnd.nextDouble() * 12,
        spin: (rnd.nextDouble() - 0.5) * 0.8,
      );
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Stack(children: [for (final p in _particles) _particle(p)]),
          ),
        ),
      ),
    );
  }

  Widget _particle(_Particle p) {
    final t = ((_c.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
    final rise = Curves.easeOutCubic.transform(t);
    final scale = t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0;
    final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
    return Positioned(
      left: widget.origin.dx + p.dx * rise - p.size / 2,
      top: widget.origin.dy + p.dy * rise - p.size / 2,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.rotate(
          angle: p.spin * rise,
          child: Transform.scale(scale: scale, child: Text(widget.emoji, style: TextStyle(fontSize: p.size, decoration: TextDecoration.none))),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({required this.dx, required this.dy, required this.delay, required this.size, required this.spin});

  final double dx, dy, delay, size, spin;
}
