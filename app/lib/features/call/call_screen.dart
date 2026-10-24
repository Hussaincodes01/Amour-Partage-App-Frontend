import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/waveform.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import 'watch_drawer.dart';

/// Immersive E2EE video (or voice) call with Camille.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, this.videoOn = true, this.connected = false, this.openWatch = false});

  final bool videoOn;

  /// Skip the ringing phase (call accepted from the incoming screen).
  final bool connected;
  final bool openWatch;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late bool _connected = widget.connected;
  late bool _video = widget.videoOn;
  late bool _watch = widget.openWatch;
  bool _muted = false;
  bool _frontCam = true;
  bool _partnerPulse = true;
  Duration _elapsed = const Duration(minutes: 24, seconds: 18);
  Timer? _clock;
  Timer? _ring;
  Timer? _pulse;
  final List<_Ripple> _ripples = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_connected) {
      _startClock();
    } else {
      _elapsed = Duration.zero;
      _ring = Timer(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() => _connected = true);
        _startClock();
      });
    }
    _pulse = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _partnerPulse = false);
    });
  }

  void _startClock() {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _ring?.cancel();
    _pulse?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String get _clockText {
    final m = _elapsed.inMinutes.toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _end() {
    HapticFeedback.heavyImpact();
    final nav = Navigator.of(context);
    showLoveToast(context, _connected ? 'Call ended • $_clockText together' : 'Call cancelled', icon: Symbols.call_end, color: AppColors.error);
    nav.pop();
  }

  void _sendTouch(Offset at) {
    HapticFeedback.mediumImpact();
    final ripple = _Ripple(at, UniqueKey());
    setState(() => _ripples.add(ripple));
    AppScope.read(context).addSpark();
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _ripples.remove(ripple));
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final state = AppScope.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Partner feed (camera stream in production).
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _sendTouch(d.globalPosition),
              onDoubleTap: () {},
              child: AnimatedSwitcher(
                duration: Motion.slow,
                child: _video && _connected
                    ? const CoverImage(DemoImages.partnerVideo, key: ValueKey('video'), alignment: Alignment(0, -0.2))
                    : _VoiceBackdrop(key: const ValueKey('voice'), ringing: !_connected),
              ),
            ),
          ),
          const _Scrims(),
          if (_video && _connected) const _AmbientSparks(),
          for (final r in _ripples) Positioned(left: r.at.dx - 60, top: r.at.dy - 60, child: _TouchRipple(key: r.key)),

          // 1. Top HUD
          Positioned(
            top: pad.top + 12,
            left: 16,
            right: 16,
            child: FadePop(
              child: _Hud(
                clock: _connected ? _clockText : 'Calling…',
                connected: _connected,
                sparks: state.sparks,
                onFlip: () {
                  setState(() => _frontCam = !_frontCam);
                  showLoveToast(context, _frontCam ? 'Front camera' : 'Rear camera', icon: Symbols.cameraswitch, color: AppColors.lavender);
                },
                onMinimize: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          if (_connected && _video && _partnerPulse && !_watch)
            Positioned(
              top: size.height * 0.25,
              left: 0,
              right: 0,
              child: const Center(child: FadePop(child: _PartnerTouchMarker())),
            ),

          // 4. Duo filters (post-beta preview)
          if (_connected && _video && !_watch)
            Positioned(left: 0, right: 0, top: size.height * 0.42, child: const FadePop(delay: Duration(milliseconds: 150), child: _DuoFilters())),

          // 2. Self view PIP (draggable)
          if (_connected)
            _DraggablePip(
              compact: _watch,
              topInset: pad.top,
              cameraOff: !_video,
              initialTop: _watch ? pad.top + 100 : size.height * 0.55,
            ),

          // 3. Quick love reactions
          if (_connected && !_watch)
            Positioned(
              left: 16,
              bottom: pad.bottom + 132,
              child: FadePop(
                delay: const Duration(milliseconds: 200),
                child: _LoveReactions(onSpark: state.addSpark),
              ),
            ),

          // 4.5 Watch together drawer
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 98,
            child: AnimatedSwitcher(
              duration: Motion.slow,
              switchInCurve: Motion.emphasized,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a), child: c),
              ),
              child: _watch ? WatchTogetherDrawer(key: const ValueKey('drawer'), onClose: () => setState(() => _watch = false)) : const SizedBox.shrink(),
            ),
          ),

          // 5. Bottom dock
          Positioned(
            left: 16,
            right: 16,
            bottom: pad.bottom + 20,
            child: FadePop(
              delay: const Duration(milliseconds: 100),
              child: _Dock(
                muted: _muted,
                video: _video,
                watch: _watch,
                onMute: () => setState(() => _muted = !_muted),
                onVideo: () => setState(() => _video = !_video),
                onFx: () => showComingSoon(context, 'Duo FX — synchronized AR filters', icon: Symbols.auto_fix_high),
                onWatch: _connected ? () => setState(() => _watch = !_watch) : null,
                onEnd: _end,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ripple {
  _Ripple(this.at, this.key);

  final Offset at;
  final Key key;
}

class _Scrims extends StatelessWidget {
  const _Scrims();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Column(
        children: [
          SizedBox(
            height: 176,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xCC100C18), Color(0x00100C18)]),
              ),
            ),
          ),
          Spacer(),
          SizedBox(
            height: 320,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xE6100C18), Color(0x00100C18)]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceBackdrop extends StatelessWidget {
  const _VoiceBackdrop({super.key, required this.ringing});

  final bool ringing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.bg),
        Positioned(left: -80, top: 80, child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.3), size: 360)),
        Positioned(right: -120, bottom: 120, child: GlowBlob(color: AppColors.violet.withValues(alpha: 0.4), size: 380)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Breathing(min: 0.85, max: 1.15, child: Dot(color: AppColors.hotPink.withValues(alpha: 0.15), size: 180)),
                    Breathing(min: 0.92, max: 1.06, period: const Duration(milliseconds: 1600), child: Dot(color: AppColors.primary.withValues(alpha: 0.2), size: 140)),
                    const Avatar(image: DemoImages.camille, size: 112, ring: AppGradients.avatarRing, ringWidth: 3),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(ringing ? 'Calling ${Mock.partner}…' : 'Voice call • ${Mock.partner}', style: AppText.title),
              const SizedBox(height: 6),
              Text(ringing ? 'Ringing on her phone • end-to-end encrypted' : 'Camera off • audio is end-to-end encrypted', style: AppText.small),
              if (!ringing) ...[
                const SizedBox(height: 24),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: _StudioAudioCard()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StudioAudioCard extends StatelessWidget {
  const _StudioAudioCard();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.98,
      onTap: () => showComingSoon(context, 'Binaural Whisper Audio', icon: Symbols.spatial_audio),
      child: AmourCard(
        color: AppColors.surfaceLow,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999)),
              child: const Sym(Symbols.graphic_eq, size: 18, color: AppColors.lavender),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Binaural Whisper Audio', style: AppText.headline),
                  Text('Spatial microphone profile calibrated for intimate couple speech', style: AppText.small),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tag(label: 'Studio\nON', color: AppColors.mint, background: AppColors.surface, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
          ],
        ),
      ),
    );
  }
}

class _AmbientSparks extends StatelessWidget {
  const _AmbientSparks();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    Widget spark(String e, double x, double y, double s, int ms) => Positioned(
          left: size.width * x,
          top: size.height * y,
          child: IgnorePointer(
            child: Opacity(opacity: 0.55, child: Breathing(min: 0.8, max: 1.15, period: Duration(milliseconds: ms), child: Text(e, style: TextStyle(fontSize: s)))),
          ),
        );
    return Stack(
      children: [
        spark('✨', 0.08, 0.25, 22, 2600),
        spark('💖', 0.85, 0.33, 16, 3000),
        spark('✨', 0.16, 0.5, 13, 2200),
        spark('💫', 0.1, 0.63, 18, 2800),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.clock, required this.connected, required this.sparks, required this.onFlip, required this.onMinimize});

  final String clock;
  final bool connected;
  final int sparks;
  final VoidCallback onFlip;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
              decoration: BoxDecoration(
                color: AppColors.raised(0.7),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Avatar(image: DemoImages.camille, size: 32, status: AppColors.mint, statusSize: 10),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(Mock.partner, style: AppText.headline.copyWith(height: 1.25)),
                          const SizedBox(width: 6),
                          Tag(label: 'LOVE', color: AppColors.primary, background: AppColors.hotPink.withValues(alpha: 0.3), padding: const EdgeInsets.symmetric(horizontal: 6)),
                        ],
                      ),
                      Row(
                        children: [
                          Dot(color: connected ? AppColors.mint : AppColors.primary, size: 6),
                          const SizedBox(width: 6),
                          Text(clock, style: AppText.label.copyWith(color: connected ? AppColors.mint : AppColors.primary)),
                          if (connected) Text('  • 4K HDR', style: AppText.label.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.7))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: () => showComingSoon(context, 'Anti-Snoop Cloak', icon: Symbols.visibility_off, detail: 'On-device AI will blur the call if an unfamiliar face appears behind you. Arriving after beta hardening.'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.raised(0.7), borderRadius: BorderRadius.circular(999)),
                child: const Sym(Symbols.verified_user, size: 18, color: AppColors.mint, fill: true),
              ),
            ),
            const SizedBox(width: 8),
            RoundIconButton(icon: Symbols.cameraswitch, size: 36, iconSize: 18, color: AppColors.raised(0.7), semanticLabel: 'Flip camera', onTap: onFlip),
            const SizedBox(width: 8),
            RoundIconButton(icon: Symbols.keyboard_arrow_down, size: 36, iconSize: 22, color: AppColors.raised(0.7), semanticLabel: 'Minimize call', onTap: onMinimize),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.ink(0.6), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    const Sym(Symbols.lock, size: 13, color: AppColors.onSurfaceVariant, fill: true),
                    const SizedBox(width: 6),
                    Text('Zero-Knowledge E2EE', style: AppText.labelRegular),
                    Text('  •  ', style: AppText.labelRegular.copyWith(color: AppColors.outline)),
                    Text('0ms Sync', style: AppText.label.copyWith(color: AppColors.mint)),
                  ],
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: Motion.medium,
                transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Motion.pop), child: c),
                child: Tag(
                  key: ValueKey(sparks),
                  label: '$sparks Sparks',
                  icon: Symbols.favorite,
                  iconSize: 14,
                  gap: 6,
                  color: AppColors.primary,
                  background: AppColors.hotPink.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  style: AppText.label.copyWith(letterSpacing: 0.25),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartnerTouchMarker extends StatelessWidget {
  const _PartnerTouchMarker();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Breathing(min: 0.85, max: 1.1, period: const Duration(milliseconds: 1200), child: Dot(color: AppColors.hotPink.withValues(alpha: 0.2), size: 80)),
                Dot(color: AppColors.primary.withValues(alpha: 0.4), size: 48),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.hotPink,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: const Sym(Symbols.favorite, size: 16, color: Colors.white, fill: true),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surfaceHighest.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Dot(color: AppColors.mint, size: 6),
                const SizedBox(width: 6),
                Text('Touch Pulse from ${Mock.partner}', style: AppText.label.copyWith(color: AppColors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TouchRipple extends StatefulWidget {
  const _TouchRipple({super.key});

  @override
  State<_TouchRipple> createState() => _TouchRippleState();
}

class _TouchRippleState extends State<_TouchRipple> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_c.value);
            return Opacity(
              opacity: (1 - _c.value).clamp(0, 1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(scale: 0.4 + t, child: Dot(color: AppColors.hotPink.withValues(alpha: 0.25), size: 120)),
                  Transform.scale(scale: 0.6 + t * 0.6, child: const Sym(Symbols.favorite, size: 34, color: AppColors.primary, fill: true)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DuoFilters extends StatelessWidget {
  const _DuoFilters();

  @override
  Widget build(BuildContext context) {
    void soon() => showComingSoon(context, 'Duo FX — synchronized AR filters', icon: Symbols.auto_fix_high);
    Widget filter(IconData icon, String label, {bool active = false}) => Pressable(
          onTap: soon,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.hotPink : AppColors.raised(0.8),
              borderRadius: BorderRadius.circular(999),
              boxShadow: active ? [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 10), spreadRadius: -3)] : null,
            ),
            child: Row(
              children: [
                Sym(icon, size: 18, color: active ? Colors.white : AppColors.onSurface, fill: active),
                const SizedBox(width: 8),
                Text(label, style: (active ? AppText.smallBold : AppText.small).copyWith(color: active ? Colors.white : AppColors.onSurface)),
                if (active) ...[const SizedBox(width: 8), const Dot(color: Colors.white, size: 6)],
              ],
            ),
          ),
        );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Sym(Symbols.arrow_back_ios_new, size: 14, color: AppColors.onSurface),
              const SizedBox(width: 8),
              Text('Synchronized Duo Filters', style: AppText.smallBold.copyWith(letterSpacing: -0.3)),
              const Spacer(),
              Tag(label: 'Matched with ${Mock.partner}', icon: Symbols.link, iconSize: 13, color: AppColors.lavenderFixed, background: AppColors.violet.withValues(alpha: 0.3), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), style: AppText.labelSemi),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              filter(Symbols.flare, 'Starlight Golden Glow', active: true),
              filter(Symbols.cruelty_free, 'Cozy Duo Ears'),
              filter(Symbols.local_florist, 'Paris Petals'),
              filter(Symbols.nights_stay, 'Midnight Aurora'),
            ],
          ),
        ),
      ],
    );
  }
}

class _DraggablePip extends StatefulWidget {
  const _DraggablePip({required this.compact, required this.topInset, required this.cameraOff, required this.initialTop});

  final bool compact;
  final double topInset;
  final bool cameraOff;
  final double initialTop;

  @override
  State<_DraggablePip> createState() => _DraggablePipState();
}

class _DraggablePipState extends State<_DraggablePip> {
  late double _top = widget.initialTop;
  bool _right = true;
  Offset? _drag;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = widget.compact ? 96.0 : 112.0;
    final h = widget.compact ? 128.0 : 160.0;
    final left = _drag?.dx ?? (_right ? size.width - w - 16 : 16);
    final top = _drag?.dy ?? _top;
    return AnimatedPositioned(
      duration: _drag != null ? Duration.zero : Motion.slow,
      curve: Motion.pop,
      left: left,
      top: top,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _drag = Offset(left, top)),
        onPanUpdate: (d) => setState(() => _drag = _drag! + d.delta),
        onPanEnd: (_) {
          HapticFeedback.selectionClick();
          setState(() {
            _right = _drag!.dx + w / 2 > size.width / 2;
            _top = _drag!.dy.clamp(widget.topInset + 96, size.height - h - 140);
            _drag = null;
          });
        },
        child: AnimatedContainer(
          duration: Motion.medium,
          width: w,
          height: h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(widget.compact ? 16 : 32),
            boxShadow: const [BoxShadow(color: Color(0xE6100C18), blurRadius: 25, offset: Offset(0, 20), spreadRadius: -5)],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.cameraOff)
                const Center(child: Sym(Symbols.videocam_off, size: 28, color: AppColors.outline))
              else
                const CoverImage(DemoImages.selfVideo, alignment: Alignment(0, -0.3)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xCC100C18), Color(0x00100C18)], stops: [0, 0.5]),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.violet.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    children: [
                      const Sym(Symbols.auto_awesome, size: 11, color: AppColors.lavenderFixed, fill: true),
                      const SizedBox(width: 4),
                      Text('Synced', style: AppText.label.copyWith(fontSize: 9, height: 1, letterSpacing: 0, color: AppColors.lavenderFixed)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Row(
                  children: [
                    Text('You', style: AppText.labelSemi.copyWith(color: AppColors.onSurface)),
                    const Spacer(),
                    const Dot(color: AppColors.mint, size: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoveReactions extends StatelessWidget {
  const _LoveReactions({required this.onSpark});

  final VoidCallback onSpark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.raised(0.6), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in const ['💖', '🥂', '✨', '🥰'])
            Builder(
              builder: (c) => Pressable(
                pressedScale: 0.82,
                onTap: () {
                  onSpark();
                  showEmojiBurst(c, e);
                },
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.surfaceHighest.withValues(alpha: 0.8), shape: BoxShape.circle),
                  child: Text(e, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.muted,
    required this.video,
    required this.watch,
    required this.onMute,
    required this.onVideo,
    required this.onFx,
    required this.onWatch,
    required this.onEnd,
  });

  final bool muted;
  final bool video;
  final bool watch;
  final VoidCallback onMute;
  final VoidCallback onVideo;
  final VoidCallback onFx;
  final VoidCallback? onWatch;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    Widget item({required Widget button, required String label, Color labelColor = AppColors.onSurfaceVariant, FontWeight weight = FontWeight.w400}) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            const SizedBox(height: 4),
            Text(label, style: AppText.labelRegular.copyWith(color: labelColor, fontWeight: weight)),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.raised(0.92),
        borderRadius: BorderRadius.circular(48),
        boxShadow: const [BoxShadow(color: AppColors.bg, blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          item(
            button: RoundIconButton(
              icon: muted ? Symbols.mic_off : Symbols.mic,
              size: 48,
              iconSize: 22,
              color: muted ? AppColors.onSurface : AppColors.surfaceHighest,
              iconColor: muted ? AppColors.bg : AppColors.onSurface,
              semanticLabel: muted ? 'Unmute' : 'Mute',
              onTap: onMute,
            ),
            label: muted ? 'Unmute' : 'Mute',
          ),
          item(
            button: RoundIconButton(
              icon: video ? Symbols.videocam : Symbols.videocam_off,
              size: 48,
              iconSize: 22,
              color: video ? AppColors.surfaceHighest : AppColors.onSurface,
              iconColor: video ? AppColors.onSurface : AppColors.bg,
              semanticLabel: video ? 'Turn camera off' : 'Turn camera on',
              onTap: onVideo,
            ),
            label: 'Video',
          ),
          item(
            button: Pressable(
              onTap: onFx,
              semanticLabel: 'Duo effects',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppGradients.duoFx,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 10), spreadRadius: -3)],
                ),
                child: const Sym(Symbols.auto_fix_high, size: 22, color: Colors.white, fill: true),
              ),
            ),
            label: 'Duo FX',
            labelColor: AppColors.primary,
            weight: FontWeight.w700,
          ),
          item(
            button: RoundIconButton(
              icon: Symbols.smart_display,
              size: 48,
              iconSize: 22,
              color: AppColors.surfaceHighest,
              gradient: watch ? AppGradients.pinkBlush : null,
              iconColor: watch ? Colors.white : AppColors.onSurface,
              fill: watch,
              glow: watch ? AppColors.hotPink.withValues(alpha: 0.45) : null,
              semanticLabel: 'Watch together',
              onTap: onWatch,
            ),
            label: 'Watch',
            labelColor: watch ? AppColors.primary : AppColors.onSurfaceVariant,
            weight: watch ? FontWeight.w700 : FontWeight.w400,
          ),
          item(
            button: RoundIconButton(
              icon: Symbols.call_end,
              size: 48,
              iconSize: 24,
              color: AppColors.crimson,
              iconColor: AppColors.error,
              fill: true,
              glow: AppColors.crimson.withValues(alpha: 0.5),
              semanticLabel: 'End call',
              onTap: onEnd,
            ),
            label: 'End',
            labelColor: AppColors.error,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

/// Incoming call — full-screen, with pulsing avatar and accept/decline.
class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Opacity(opacity: 0.35, child: CoverImage(DemoImages.partnerVideo)),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99100C18), Color(0xF2100C18)]))),
          Positioned(left: -60, top: 120, child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.3), size: 300)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                FadePop(child: Tag(label: 'END-TO-END ENCRYPTED VIDEO CALL', icon: Symbols.lock, color: AppColors.mint, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4))),
                const SizedBox(height: 40),
                FadePop(
                  delay: const Duration(milliseconds: 80),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Breathing(min: 0.8, max: 1.15, period: const Duration(milliseconds: 1400), child: Dot(color: AppColors.hotPink.withValues(alpha: 0.18), size: 200)),
                        Breathing(min: 0.9, max: 1.08, period: const Duration(milliseconds: 1000), child: Dot(color: AppColors.primary.withValues(alpha: 0.22), size: 156)),
                        const Avatar(image: DemoImages.camille, size: 124, ring: AppGradients.avatarRing, ringWidth: 3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadePop(delay: const Duration(milliseconds: 140), child: Text(Mock.partner, style: AppText.display.copyWith(fontSize: 32, height: 1.2))),
                const SizedBox(height: 6),
                FadePop(delay: const Duration(milliseconds: 180), child: Text('is calling you… 💞', style: AppText.body.copyWith(color: AppColors.onSurfaceVariant))),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(48, 0, 48, pad.bottom + 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CallAction(
                        label: 'Decline',
                        color: AppColors.crimson,
                        icon: Symbols.call_end,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      _CallAction(
                        label: 'Message',
                        color: AppColors.surfaceHigh,
                        icon: Symbols.chat_bubble,
                        small: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          AppScope.read(context).selectTab(2);
                        },
                      ),
                      _CallAction(
                        label: 'Accept',
                        color: AppColors.mintDeep,
                        icon: Symbols.videocam,
                        pulse: true,
                        onTap: () => Navigator.of(context).pushReplacement(
                          PageRouteBuilder<void>(
                            transitionDuration: Motion.slow,
                            pageBuilder: (_, _, _) => const CallScreen(connected: true),
                            transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
                          ),
                        ),
                      ),
                    ],
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

class _CallAction extends StatelessWidget {
  const _CallAction({required this.label, required this.color, required this.icon, required this.onTap, this.small = false, this.pulse = false});

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool small;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final size = small ? 52.0 : 68.0;
    Widget button = Pressable(
      onTap: onTap,
      haptic: PressFeedback.medium,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20)]),
        child: Sym(icon, size: small ? 22 : 30, color: Colors.white, fill: true),
      ),
    );
    if (pulse) button = Breathing(min: 0.94, max: 1.06, period: const Duration(milliseconds: 900), child: button);
    return Column(
      children: [
        button,
        const SizedBox(height: 8),
        Text(label, style: AppText.label.copyWith(color: AppColors.onSurface)),
      ],
    );
  }
}

/// Small waveform helper reused by the drawer.
class LiveBars extends StatelessWidget {
  const LiveBars({super.key});

  @override
  Widget build(BuildContext context) => const Waveform(
        heights: [10, 18, 8, 16, 20, 8, 14],
        colors: [AppColors.primary, AppColors.lavender, AppColors.hotPink, AppColors.mint, AppColors.violet, AppColors.primary, AppColors.lavenderFixed],
        barWidth: 4,
        gap: 4,
        live: true,
        maxHeight: 20,
      );
}
