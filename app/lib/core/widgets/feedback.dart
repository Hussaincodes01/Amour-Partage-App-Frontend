import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/motion.dart';
import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'buttons.dart';
import 'symbol.dart';

/// "Coming soon" pop-up for features scheduled after beta hardening.
Future<void> showComingSoon(BuildContext context, String feature, {IconData icon = Symbols.rocket_launch, String? detail}) {
  HapticFeedback.mediumImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x99050308),
    transitionDuration: Motion.slow,
    pageBuilder: (context, _, _) => _ComingSoonCard(feature: feature, icon: icon, detail: detail),
    transitionBuilder: (context, animation, _, child) {
      final pop = CurvedAnimation(parent: animation, curve: Motion.pop, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Motion.fadeIn),
        child: ScaleTransition(scale: Tween(begin: 0.82, end: 1.0).animate(pop), child: child),
      );
    },
  );
}

class _ComingSoonCard extends StatefulWidget {
  const _ComingSoonCard({required this.feature, required this.icon, this.detail});

  final String feature;
  final IconData icon;
  final String? detail;

  @override
  State<_ComingSoonCard> createState() => _ComingSoonCardState();
}

class _ComingSoonCardState extends State<_ComingSoonCard> {
  bool _notify = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
              boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [AppColors.violet, AppColors.hotPink]),
                    boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.4), blurRadius: 20)],
                  ),
                  child: Sym(widget.icon, size: 28, color: Colors.white, fill: true),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(999)),
                  child: Text('COMING SOON', style: AppText.label.copyWith(color: AppColors.lavender, letterSpacing: 1)),
                ),
                const SizedBox(height: 10),
                Text(widget.feature, textAlign: TextAlign.center, style: AppText.headline),
                const SizedBox(height: 6),
                Text(
                  widget.detail ?? 'We are polishing and security-hardening this for after the beta. It will unlock for both of you at the same time.',
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(height: 1.5),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Pressable(
                        onTap: () => setState(() => _notify = !_notify),
                        haptic: PressFeedback.selection,
                        child: AnimatedContainer(
                          duration: Motion.medium,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _notify ? AppColors.mint.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Sym(_notify ? Symbols.notifications_active : Symbols.notifications, size: 16, color: _notify ? AppColors.mint : AppColors.onSurfaceVariant, fill: _notify),
                              const SizedBox(width: 6),
                              Text(_notify ? "We'll ping you" : 'Notify me', style: AppText.smallStrong.copyWith(color: _notify ? AppColors.mint : AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GradientButton(
                        label: 'Got it',
                        height: 44,
                        padding: EdgeInsets.zero,
                        textStyle: AppText.smallBold.copyWith(color: Colors.white),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small confirmation toast that pops in under the header and fades away.
void showLoveToast(BuildContext context, String message, {IconData icon = Symbols.favorite, Color color = AppColors.hotPink}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Toast(message: message, icon: icon, color: color, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.icon, required this.color, required this.onDone});

  final String message;
  final IconData icon;
  final Color color;
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
    Future.delayed(const Duration(milliseconds: 1700), () async {
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
    final top = MediaQuery.paddingOf(context).top + 72;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _c,
            child: ScaleTransition(
              scale: Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Motion.pop, reverseCurve: Curves.easeIn)),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: widget.color.withValues(alpha: 0.35)),
                    boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.25), blurRadius: 24)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Sym(widget.icon, size: 16, color: widget.color, fill: true),
                      const SizedBox(width: 8),
                      Text(widget.message, style: AppText.smallStrong),
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

/// Floating emoji reaction burst launched from a point on screen.
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
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _particles = List.generate(widget.count, (i) {
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.6;
      return _Particle(
        dx: math.cos(angle) * (60 + rnd.nextDouble() * 90),
        dy: math.sin(angle) * (140 + rnd.nextDouble() * 120),
        delay: rnd.nextDouble() * 0.25,
        size: 20 + rnd.nextDouble() * 14,
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
            builder: (context, _) => Stack(
              children: [
                for (final p in _particles) _buildParticle(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(_Particle p) {
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

/// Confirmation dialog in the app's style.
Future<bool> confirmAction(BuildContext context, {required String title, required String message, required String confirm, bool destructive = false}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: const Color(0x99050308),
    transitionDuration: Motion.medium,
    pageBuilder: (context, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.headline),
                const SizedBox(height: 8),
                Text(message, style: AppText.small.copyWith(height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Pressable(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text('Cancel', style: AppText.smallStrong.copyWith(color: AppColors.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      onTap: () => Navigator.of(context).pop(true),
                      haptic: PressFeedback.medium,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: destructive ? AppColors.crimson : AppColors.hotPink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(confirm, style: AppText.smallBold.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Motion.pop)), child: child),
    ),
  );
  return result ?? false;
}

/// Little round "×" used on dismissible surfaces.
class CloseDot extends StatelessWidget {
  const CloseDot({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RoundIconButton(
        icon: Symbols.close,
        onTap: onTap,
        size: 28,
        iconSize: 14,
        color: AppColors.surfaceHighest.withValues(alpha: 0.8),
        iconColor: AppColors.onSurfaceVariant,
        semanticLabel: 'Close',
      );
}
