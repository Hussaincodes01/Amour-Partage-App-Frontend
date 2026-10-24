import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../backend/backend.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pulse.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/tiles.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import 'call_watch_panel.dart';

/// A voice or video call. Pass [session] when answering an incoming call;
/// otherwise the screen starts an outgoing call.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key, this.video = true, this.session});

  final bool video;
  final CallSession? session;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  CallSession? _session;
  Object? _error;
  Timer? _clock;
  Offset _selfView = const Offset(16, 120);
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session?.connectedAt != null) setState(() {});
    });
    if (widget.session != null) {
      _attach(widget.session!);
    } else {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final s = await AppScope.read(context).backend.startCall(video: widget.video);
      if (!mounted) {
        await s.hangUp();
        return;
      }
      _attach(s);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _attach(CallSession s) {
    s.state.addListener(_onState);
    setState(() => _session = s);
  }

  void _onState() {
    final s = _session;
    if (s == null || !mounted) return;
    if (s.state.value == CallState.active) HapticFeedback.mediumImpact();
    if (s.state.value == CallState.ended) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  Future<void> _hangUp() async {
    HapticFeedback.heavyImpact();
    final s = _session;
    if (s == null) {
      Navigator.of(context).maybePop();
      return;
    }
    await s.hangUp();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _session?.state.removeListener(_onState);
    final s = _session;
    if (s != null && s.state.value != CallState.ended) s.hangUp();
    super.dispose();
  }

  String _status(CallSession? s) {
    if (_error != null) return '$_error';
    if (s == null) return 'Starting…';
    final at = s.connectedAt;
    if (s.state.value != CallState.active || at == null) return s.info.incoming ? 'Connecting…' : 'Calling…';
    final d = DateTime.now().difference(at);
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final partner = state.couple?.partner;
    final s = _session;
    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final active = s?.state.value == CallState.active;
    final video = s?.info.video ?? widget.video;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0910),
      body: GestureDetector(
        onDoubleTapDown: (d) {
          if (!active) return;
          HapticFeedback.lightImpact();
          showEmojiBurst(context, '💗', from: d.globalPosition, count: 6);
        },
        child: Stack(
          children: [
            // Partner video, or a calm backdrop for voice calls / while ringing.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: Motion.slow,
                child: active && video
                    ? SizedBox.expand(key: const ValueKey('remote'), child: s!.remoteView())
                    : SizedBox.expand(key: const ValueKey('backdrop'), child: _Backdrop(partner: partner, ringing: !active)),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.22, 0.7, 1],
                      colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0xB3000000)],
                    ),
                  ),
                ),
              ),
            ),
            // Name + timer.
            Positioned(
              top: pad.top + 16,
              left: 20,
              right: 20,
              child: FadePop(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner?.name ?? 'Partner', style: AppText.display.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Sym(Symbols.lock, size: 13, color: Colors.white70, fill: true),
                        const SizedBox(width: 4),
                        Text('Encrypted · ${_status(s)}', style: AppText.small.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Draggable self view.
            if (video && s != null && !_watching)
              ValueListenableBuilder<bool>(
                valueListenable: s.cameraOn,
                builder: (context, on, _) => !on
                    ? const SizedBox.shrink()
                    : Positioned(
                        right: _selfView.dx,
                        top: pad.top + _selfView.dy,
                        child: GestureDetector(
                          onPanUpdate: (d) => setState(() {
                            _selfView = Offset(
                              (_selfView.dx - d.delta.dx).clamp(8, size.width - 120),
                              (_selfView.dy + d.delta.dy).clamp(80, size.height - pad.top - 320),
                            );
                          }),
                          child: Container(
                            width: 104,
                            height: 148,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24, width: 1.5)),
                            clipBehavior: Clip.antiAlias,
                            child: s.localView(),
                          ),
                        ),
                      ),
              ),
            // Watch Together panel.
            if (_watching)
              Positioned(
                left: 12,
                right: 12,
                bottom: pad.bottom + 112,
                child: FadePop(child: CallWatchPanel(onClose: () => setState(() => _watching = false))),
              ),
            // Controls.
            Positioned(
              left: 16,
              right: 16,
              bottom: pad.bottom + 20,
              child: FadePop(delay: const Duration(milliseconds: 120), child: _Dock(session: s, video: video, onHangUp: _hangUp, onMore: _more)),
            ),
          ],
        ),
      ),
    );
  }

  void _more() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.all(8),
        child: AmourCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MoreRow(icon: Symbols.smart_display, label: 'Watch together', onTap: () {
                Navigator.of(sheet).pop();
                setState(() => _watching = true);
              }),
              _MoreRow(icon: Symbols.favorite, label: 'Send a heart', onTap: () {
                Navigator.of(sheet).pop();
                showEmojiBurst(context, '💗', count: 8);
              }),
              _MoreRow(icon: Symbols.auto_awesome, label: 'Couple filters', soon: true, onTap: () => showComingSoon(sheet, 'Couple filters', icon: Symbols.auto_awesome)),
              _MoreRow(icon: Symbols.screen_share, label: 'Share screen', soon: true, onTap: () => showComingSoon(sheet, 'Screen sharing', icon: Symbols.screen_share)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.partner, required this.ringing});

  final Person? partner;
  final bool ringing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF120C1C)),
        Positioned(left: -120, top: 80, child: GlowBlob(color: Brand.pink.withValues(alpha: 0.28), size: 420)),
        Positioned(right: -140, bottom: 80, child: GlowBlob(color: Brand.violet.withValues(alpha: 0.4), size: 440)),
        Center(
          child: Breathing(
            breaths: ringing ? null : 1,
            min: 0.96,
            max: 1.04,
            child: Avatar(image: partner?.photo, name: partner?.name ?? '', size: 148, ring: true),
          ),
        ),
      ],
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.session, required this.video, required this.onHangUp, required this.onMore});

  final CallSession? session;
  final bool video;
  final VoidCallback onHangUp;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final s = session;
    const glass = Color(0x33FFFFFF);
    Widget toggle(ValueListenable<bool>? value, IconData on, IconData off, String label, Future<void> Function(bool)? set) =>
        ValueListenableBuilder<bool>(
          valueListenable: value ?? ValueNotifier(true),
          builder: (context, isOn, _) => RoundIconButton(
            icon: isOn ? on : off,
            size: 56,
            iconSize: 26,
            color: isOn ? glass : Colors.white,
            iconColor: isOn ? Colors.white : Colors.black,
            fill: true,
            semanticLabel: label,
            onTap: set == null ? null : () => set(!isOn),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        toggle(s?.micOn, Symbols.mic, Symbols.mic_off, 'Microphone', s?.setMic),
        if (video) toggle(s?.cameraOn, Symbols.videocam, Symbols.videocam_off, 'Camera', s?.setCamera),
        RoundIconButton(icon: Symbols.call_end, size: 68, iconSize: 30, color: const Color(0xFFE5394B), iconColor: Colors.white, fill: true, semanticLabel: 'End call', onTap: onHangUp),
        if (video) RoundIconButton(icon: Symbols.cameraswitch, size: 56, iconSize: 24, color: glass, iconColor: Colors.white, semanticLabel: 'Flip camera', onTap: s?.flipCamera),
        RoundIconButton(icon: Symbols.more_horiz, size: 56, iconSize: 26, color: glass, iconColor: Colors.white, semanticLabel: 'More', onTap: onMore),
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.icon, required this.label, required this.onTap, this.soon = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(icon: icon, title: label, soon: soon, chevron: false, onTap: onTap);
  }
}
