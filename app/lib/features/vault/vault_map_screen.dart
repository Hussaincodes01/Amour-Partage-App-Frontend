import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/security/biometric.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/waveform.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../../data/models.dart';
import 'new_capsule_sheet.dart';
import 'share_location_sheet.dart';
import 'timeline_screen.dart';

/// Live Map (time-boxed, mutual location sharing) + Memory Vault.
class VaultMapScreen extends StatefulWidget {
  const VaultMapScreen({super.key});

  @override
  State<VaultMapScreen> createState() => _VaultMapScreenState();
}

class _VaultMapScreenState extends State<VaultMapScreen> {
  int _segment = 0;
  final _scroll = ScrollController();
  bool _fabExpanded = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final expanded = _scroll.offset < 60;
      if (expanded != _fabExpanded) setState(() => _fabExpanded = expanded);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = ShellInsets.of(context);
    final map = <Widget>[
      const _LiveMapCard(),
      const _GhostModeBar(),
      const _MilestoneCard(),
      const _AiRecapCard(),
      const _VaultGrid(compact: true),
    ];
    final vault = <Widget>[
      const _VaultGrid(compact: false),
    ];
    final sections = _segment == 0 ? map : vault;
    return Stack(
      children: [
        ListView.builder(
          controller: _scroll,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16, insets.top + 12, 16, insets.bottom + 96),
          itemCount: sections.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return _Segmented(
                index: _segment,
                onChanged: (v) {
                  setState(() => _segment = v);
                  if (_scroll.hasClients) _scroll.animateTo(0, duration: Motion.medium, curve: Motion.emphasized);
                },
              );
            }
            return Padding(
              key: ValueKey('$_segment-$i'),
              padding: const EdgeInsets.only(top: 16),
              child: FadePop.index(i, child: sections[i - 1]),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: insets.bottom + 16,
          child: _CapsuleFab(expanded: _fabExpanded),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ink(0.8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10), spreadRadius: -3)],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.slow,
                curve: Motion.pop,
                left: index * w,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.pinkViolet,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.35), blurRadius: 8)],
                  ),
                ),
              ),
              Row(
                children: [
                  _segment(0, Symbols.near_me, 'Live Map'),
                  _segment(1, Symbols.lock, 'Memory Vault'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(int i, IconData icon, String label) {
    final active = i == index;
    final color = active ? Colors.white : AppColors.onSurfaceVariant;
    return Expanded(
      child: Pressable(
        haptic: PressFeedback.selection,
        onTap: () => onChanged(i),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Sym(icon, size: 18, color: color, fill: active),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(duration: Motion.fast, style: AppText.bodyStrong.copyWith(color: color), child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _LiveMapCard extends StatefulWidget {
  const _LiveMapCard();

  @override
  State<_LiveMapCard> createState() => _LiveMapCardState();
}

class _LiveMapCardState extends State<_LiveMapCard> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ghost = state.ghostMode;
    final sharing = state.locationShare != LocationShare.off;
    return Container(
      height: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 36, offset: Offset(0, 12))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Stylised map base (Google Maps tiles with a dark romantic style in production).
          const Opacity(
            opacity: 0.45,
            child: CoverImage(
              DemoImages.mapParis,
              colorFilter: ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0, 0, 0, 1, 0,
              ]),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.bg, Color(0x4D100C18), Color(0xB3100C18)],
              ),
            ),
          ),
          Positioned(left: -55, top: -45, child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.25), size: 320)),
          Positioned(right: -70, bottom: -50, child: GlowBlob(color: AppColors.violet.withValues(alpha: 0.32), size: 340)),
          const Positioned.fill(child: CustomPaint(painter: _RoutePainter())),
          if (sharing)
            const Positioned(left: 40, top: 56, child: _MapPin(name: 'Camille', image: DemoImages.camille, color: AppColors.hotPink, label: 'Le Marais • Battery 84%', tagRight: true)),
          Positioned(
            right: 40,
            bottom: 72,
            child: _MapPin(
              name: 'Julian',
              image: DemoImages.julian,
              color: AppColors.mint,
              label: ghost ? 'Approximate area' : 'Moving • 26 mph',
              labelIcon: ghost ? Symbols.blur_on : Symbols.directions_car,
              ghost: ghost,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.ink(0.85), borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  const Sym(Symbols.lock, size: 14, color: AppColors.mint, fill: true),
                  const SizedBox(width: 6),
                  Text('Zero-Knowledge GPS', style: AppText.label),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xE6211E2A), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 25, offset: Offset(0, 20))]),
              child: Row(
                children: [
                  IconBadge(icon: Symbols.route, color: AppColors.primary, background: AppColors.hotPink.withValues(alpha: 0.2), size: 32, iconSize: 16, glow: AppColors.hotPink.withValues(alpha: 0.3)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('2.4 miles apart', style: AppText.title.copyWith(height: 1.25))),
                        Text('ETA: 12 min driving', style: AppText.small.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () {
                      setState(() => _sent = true);
                      showEmojiBurst(context, '🚗', count: 4);
                      showLoveToast(context, '“On my way” sent with live ETA', icon: Symbols.near_me, color: AppColors.mint);
                    },
                    child: AnimatedContainer(
                      duration: Motion.medium,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _sent ? AppColors.mint.withValues(alpha: 0.2) : AppColors.hotPink,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: _sent ? null : [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.4), blurRadius: 7)],
                      ),
                      child: Row(
                        children: [
                          Sym(_sent ? Symbols.check : Symbols.send, size: 14, color: _sent ? AppColors.mint : Colors.white, fill: true),
                          const SizedBox(width: 4),
                          Text(_sent ? 'Sent' : '"On my way"', style: AppText.smallStrong.copyWith(color: _sent ? AppColors.mint : Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final a = const Offset(64, 80);
    final b = Offset(size.width - 64, size.height - 96);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx + 90, a.dy + 10, b.dx - 120, b.dy - 90, b.dx, b.dy);
    final shader = const LinearGradient(colors: [AppColors.hotPink, AppColors.lavender, AppColors.mint]).createShader(Rect.fromPoints(a, b));
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 7, metric.length)), paint);
        d += 13;
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.name,
    required this.image,
    required this.color,
    required this.label,
    this.labelIcon,
    this.tagRight = false,
    this.ghost = false,
  });

  final String name;
  final ImageProvider image;
  final Color color;
  final String label;
  final IconData? labelIcon;
  final bool tagRight;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                duration: Motion.slow,
                curve: Motion.pop,
                scale: ghost ? 2.4 : 1,
                child: PingDot(color: color.withValues(alpha: ghost ? 0.18 : 0.3), size: 56, glow: false, period: const Duration(milliseconds: 2200)),
              ),
              AnimatedOpacity(
                duration: Motion.medium,
                opacity: ghost ? 0.6 : 1,
                child: Avatar(
                  image: image,
                  size: 48,
                  ring: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [color, AppColors.lavender]),
                  glow: color.withValues(alpha: 0.7),
                ),
              ),
              Positioned(
                right: tagRight ? -4 : null,
                left: tagRight ? null : -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: tagRight ? AppColors.hotPink : AppColors.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                  child: Text(name, style: AppText.label.copyWith(fontSize: 9, letterSpacing: 0, color: tagRight ? Colors.white : AppColors.mint)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.ink(0.85), borderRadius: BorderRadius.circular(999)),
          child: Row(
            children: [
              if (labelIcon != null) Sym(labelIcon!, size: 13, color: AppColors.onSurface) else const Dot(color: AppColors.mint, size: 6, glow: true),
              const SizedBox(width: 6),
              Text(label, style: AppText.label.copyWith(color: AppColors.onSurface)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GhostModeBar extends StatelessWidget {
  const _GhostModeBar();

  String _shareLabel(LocationShare s) => switch (s) {
        LocationShare.off => 'Location sharing is off',
        LocationShare.oneHour => 'Sharing live location • 58 min left',
        LocationShare.eightHours => 'Sharing live location • 7h 58m left',
        LocationShare.untilStopped => 'Sharing until you stop it',
      };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final sharing = state.locationShare != LocationShare.off;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: AppColors.surfaceLow, boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))]),
          child: Row(
            children: [
              IconBadge(icon: Symbols.visibility_off, color: AppColors.lavender, background: AppColors.violet.withValues(alpha: 0.25), size: 40, iconSize: 20, glow: AppColors.lavender.withValues(alpha: 0.2)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ghost Mode', style: AppText.bodyStrong),
                    Text('Obfuscate precise street radius', style: AppText.small),
                  ],
                ),
              ),
              AmourSwitch(value: state.ghostMode, semanticLabel: 'Ghost mode', onChanged: (_) => state.toggle('ghost')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Pressable(
          pressedScale: 0.98,
          onTap: () => showAmourSheet(context, builder: (_) => const ShareLocationSheet()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sharing ? AppColors.mint.withValues(alpha: 0.08) : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: (sharing ? AppColors.mint : AppColors.outlineVariant).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                sharing ? const PingDot(color: AppColors.mint, size: 8) : const Dot(color: AppColors.outline, size: 8),
                const SizedBox(width: 10),
                Expanded(child: Text(_shareLabel(state.locationShare), style: AppText.smallStrong.copyWith(color: sharing ? AppColors.mint : AppColors.onSurfaceVariant))),
                Text(sharing ? 'Manage' : 'Start', style: AppText.label.copyWith(color: AppColors.primary)),
                const Sym(Symbols.chevron_right, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard();

  @override
  Widget build(BuildContext context) {
    return AmourCard(
      color: AppColors.surfaceLow,
      padding: const EdgeInsets.all(20),
      blooms: [Bloom(color: AppColors.hotPink.withValues(alpha: 0.22), size: 200, right: -76, top: -76)],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Tag(label: 'Milestone Approaching', icon: Symbols.celebration, iconSize: 13, gap: 6, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('500 Days Together', style: AppText.title),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style: AppText.small.copyWith(height: 16.5 / 12),
                        children: [
                          const TextSpan(text: '${Mock.daysTogether} days of laughter, secret notes & shared sunsets. Only '),
                          TextSpan(text: '72 days left', style: AppText.small.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary, height: 16.5 / 12)),
                          const TextSpan(text: ' until our 500-day celebration!'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _ProgressRing(progress: Mock.daysTogether / 500, value: '72'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Sym(Symbols.event, size: 15, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(child: Text('Target: January 4, 2027', style: AppText.label)),
              Pressable(
                onTap: () => context.pushPop(const TimelineScreen()),
                child: Row(
                  children: [
                    Text('View Timeline', style: AppText.label.copyWith(color: AppColors.lavender)),
                    const SizedBox(width: 2),
                    const Sym(Symbols.arrow_forward, size: 13, color: AppColors.lavender),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.value});

  final double progress;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Motion.emphasized,
      builder: (context, t, _) => SizedBox.square(
        dimension: 96,
        child: CustomPaint(
          painter: _RingPainter(t),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: AppText.display.copyWith(height: 1, letterSpacing: -0.24)),
                Text('DAYS', style: AppText.label.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawArc(rect, 0, math.pi * 2, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.surfaceHighest);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [AppColors.lavender, AppColors.primary, AppColors.hotPink],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

class _AiRecapCard extends StatelessWidget {
  const _AiRecapCard();

  @override
  Widget build(BuildContext context) {
    return AmourCard(
      color: AppColors.raised(0.6),
      shadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [AppColors.violet, AppColors.hotPink]),
              boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: const Sym(Symbols.auto_awesome, size: 22, color: Colors.white, fill: true),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('AMOUR AI • SYNC RECAP', style: AppText.label.copyWith(color: AppColors.lavender))),
                    Text('Today 8:30 AM', style: AppText.label),
                  ],
                ),
                const SizedBox(height: 2),
                Text("This Week's Shared Harmony", style: AppText.headline),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: AppText.small,
                    children: [
                      const TextSpan(text: 'You and ${Mock.partner} listened together to '),
                      TextSpan(text: '"Quelqu\'un m\'a dit"', style: AppText.smallStrong.copyWith(letterSpacing: 0)),
                      const TextSpan(text: ' 14 times while 2.4 miles apart. We compiled your synchronized moments into an encrypted reel.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Pressable(
                  pressedScale: 0.98,
                  onTap: () => showComingSoon(context, 'AI recap reels', icon: Symbols.movie),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: AppColors.ink(0.8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.hotPink, shape: BoxShape.circle),
                          child: const Sym(Symbols.play_arrow, size: 18, color: Colors.white, fill: true),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Center(
                            child: Waveform(
                              heights: [12, 20, 8, 16, 20, 8, 16],
                              colors: [AppColors.primary, AppColors.lavender, AppColors.hotPink, AppColors.mint, AppColors.violet, AppColors.primary, AppColors.lavenderFixed],
                              barWidth: 4,
                              gap: 4,
                              maxHeight: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('2m 44s', style: AppText.label),
                      ],
                    ),
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

class _VaultGrid extends StatelessWidget {
  const _VaultGrid({required this.compact});

  final bool compact;

  Future<void> _openLocked(BuildContext context) async {
    final state = AppScope.read(context);
    if (state.vaultUnlocked) return;
    final result = await Biometric.unlock('Unlock your private Memory Vault');
    if (!context.mounted) return;
    switch (result) {
      case BiometricResult.success:
        state.setVaultUnlocked(true);
        showEmojiBurst(context, '🔓', count: 5);
        showLoveToast(context, 'Vault unlocked for this session', icon: Symbols.lock_open, color: AppColors.mint);
      case BiometricResult.failed:
        showLoveToast(context, 'Couldn’t verify — try again', icon: Symbols.fingerprint, color: AppColors.error);
      case BiometricResult.unavailable:
        showLoveToast(context, 'Set up a fingerprint or face unlock to use the Vault lock', icon: Symbols.fingerprint, color: AppColors.lavender);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final memories = state.vault;
    final featured = memories.first;
    final rest = memories.skip(1).toList();
    final shown = compact ? rest.take(2).toList() : rest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Memory Vault',
          icon: Symbols.photo_library,
          titleStyle: AppText.title,
          trailing: 'Vault Security (AES-256)',
          trailingIcon: Symbols.verified_user,
          trailingStyle: AppText.smallStrong.copyWith(color: AppColors.primary),
          onTrailingTap: () => state.selectTab(4),
        ),
        const SizedBox(height: 8),
        _FeaturedCapsule(memory: featured),
        const SizedBox(height: 8),
        for (var r = 0; r < (shown.length / 2).ceil(); r++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < 2; c++) ...[
                if (c == 1) const SizedBox(width: 8),
                Expanded(
                  child: r * 2 + c < shown.length
                      ? _BentoCapsule(
                          memory: shown[r * 2 + c],
                          locked: shown[r * 2 + c].locked && !state.vaultUnlocked,
                          onLockedTap: () => _openLocked(context),
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FeaturedCapsule extends StatefulWidget {
  const _FeaturedCapsule({required this.memory});

  final Memory memory;

  @override
  State<_FeaturedCapsule> createState() => _FeaturedCapsuleState();
}

class _FeaturedCapsuleState extends State<_FeaturedCapsule> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    return AmourCard(
      color: AppColors.surfaceLow,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 192,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverImage(m.image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [AppColors.surfaceLow, Color(0x661D1A26), Color(0x001D1A26)]),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.ink(0.8), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        const Sym(Symbols.lock, size: 13, color: AppColors.mint, fill: true),
                        const SizedBox(width: 6),
                        Text('48 Photos • 3 Videos', style: AppText.label.copyWith(color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: RoundIconButton(
                    icon: Symbols.favorite,
                    size: 32,
                    iconSize: 17,
                    fill: _liked,
                    color: AppColors.ink(0.8),
                    iconColor: _liked ? AppColors.hotPink : AppColors.onSurface,
                    semanticLabel: 'Favourite',
                    onTap: () {
                      setState(() => _liked = !_liked);
                      if (_liked) showEmojiBurst(context, '💗', count: 4);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(m.title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(m.date, style: AppText.label.copyWith(color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(m.subtitle, style: AppText.small, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Tag(label: m.tag ?? 'Paris', icon: Symbols.location_on, iconSize: 12, background: AppColors.surfaceHigh, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                    Tag(label: 'Biometric Vault', icon: Symbols.fingerprint, iconSize: 12, background: AppColors.surfaceHigh, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoCapsule extends StatelessWidget {
  const _BentoCapsule({required this.memory, required this.locked, required this.onLockedTap});

  final Memory memory;
  final bool locked;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.97,
      onTap: locked ? onLockedTap : () => showLoveToast(context, 'Opening “${memory.title}”', icon: Symbols.photo_library, color: AppColors.lavender),
      child: AmourCard(
        color: AppColors.surfaceLow,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedOpacity(duration: Motion.slow, opacity: locked ? 0.55 : 1, child: CoverImage(memory.image)),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xCC1D1A26), Color(0x001D1A26)])),
                  ),
                  if (memory.locked)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.ink(0.8), shape: BoxShape.circle),
                        child: const Sym(Symbols.mic, size: 13, color: AppColors.onSurface),
                      ),
                    ),
                  if (memory.tag != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.ink(0.8), borderRadius: BorderRadius.circular(999)),
                        child: Text(memory.tag!, style: AppText.labelRegular.copyWith(letterSpacing: 0, color: memory.locked ? AppColors.primary : AppColors.lavender)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(memory.title, style: AppText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(memory.subtitle, style: AppText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(memory.date, style: AppText.small.copyWith(fontSize: 11))),
                AnimatedSwitcher(
                  duration: Motion.medium,
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: locked
                      ? const Sym(Symbols.lock, key: ValueKey('l'), size: 15, color: AppColors.primary, fill: true)
                      : Sym(memory.locked ? Symbols.lock_open : Symbols.check_circle, key: const ValueKey('u'), size: 15, color: AppColors.mint, fill: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapsuleFab extends StatelessWidget {
  const _CapsuleFab({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      haptic: PressFeedback.medium,
      semanticLabel: 'New memory capsule',
      onTap: () => showAmourSheet(context, builder: (_) => const NewCapsuleSheet()),
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: expanded ? 20 : 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.hotPink, AppColors.hotPink, AppColors.violet]),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Sym(Symbols.add, size: 22, color: Colors.white, weight: 600),
            AnimatedSize(
              duration: Motion.medium,
              curve: Motion.emphasized,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text('New Memory Capsule', style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
