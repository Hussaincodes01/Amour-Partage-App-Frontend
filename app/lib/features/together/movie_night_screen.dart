import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';

/// Movie Night: each of you opens the film in your own app, and both phones
/// count down 3-2-1 together so you press play at the same moment.
class MovieNightScreen extends StatefulWidget {
  const MovieNightScreen({super.key});

  @override
  State<MovieNightScreen> createState() => _MovieNightScreenState();
}

class _MovieNightScreenState extends State<MovieNightScreen> {
  static const _services = ['Netflix', 'Prime Video', 'Disney+', 'Apple TV', 'Max', 'Other'];
  int _service = 0;
  StreamSubscription<MovieCountdown?>? _sub;
  DateTime? _shown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub ??= AppScope.read(context).backend.countdown.listen(_onCountdown);
  }

  void _onCountdown(MovieCountdown? countdown) {
    if (countdown == null || !mounted) return;
    // Show each countdown once, and only if it hasn't already finished.
    if (_shown == countdown.startAt || countdown.startAt.isBefore(DateTime.now())) return;
    _shown = countdown.startAt;
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: context.colors.bgA(0.94),
      transitionDuration: Motion.medium,
      pageBuilder: (_, _, _) => _CountdownOverlay(countdown: countdown),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SubPage(
      title: 'Movie night',
      bottom: GradientButton(
        label: 'Start 3-2-1 together',
        icon: Symbols.timer,
        onTap: () => AppScope.read(context).backend.startCountdown(_services[_service]),
      ),
      children: [
        Text('Where are you watching?', style: AppText.title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _services.length; i++)
              Pressable(
                haptic: PressFeedback.selection,
                onTap: () => setState(() => _service = i),
                semanticLabel: _services[i],
                child: AnimatedContainer(
                  duration: Motion.medium,
                  curve: Motion.emphasized,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: i == _service ? c.pink : c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                  child: Text(_services[i], style: AppText.smallStrong.copyWith(color: i == _service ? Colors.white : c.text)),
                ),
              ),
          ],
        ),
        AmourCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (icon, text) in const [
                (Symbols.looks_one, 'Open the same movie in your own app.'),
                (Symbols.looks_two, 'Tap “Start”. Both phones count down together.'),
                (Symbols.looks_3, 'Press play on “Go!”, and keep the call going if you like.'),
              ]) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Sym(icon, size: 22, color: c.accent, fill: true),
                    const SizedBox(width: 12),
                    Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(text, style: AppText.body))),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CountdownOverlay extends StatefulWidget {
  const _CountdownOverlay({required this.countdown});

  final MovieCountdown countdown;

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay> {
  Timer? _tick;
  int _left = 3;

  @override
  void initState() {
    super.initState();
    _update();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) => _update());
  }

  void _update() {
    final ms = widget.countdown.startAt.difference(DateTime.now()).inMilliseconds;
    final left = ms <= 0 ? 0 : (ms / 1000).ceil();
    if (left != _left) {
      HapticFeedback.heavyImpact();
      setState(() => _left = left);
    }
    if (ms < -1600) {
      _tick?.cancel();
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.countdown.service.toUpperCase(), style: AppText.label.copyWith(color: c.lavender)),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: Motion.medium,
                transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Motion.pop), child: FadeTransition(opacity: a, child: child)),
                child: Text(
                  _left > 3 ? 'Ready…' : (_left == 0 ? 'Go!' : '$_left'),
                  key: ValueKey(_left > 3 ? -1 : _left),
                  style: AppText.largeTitle.copyWith(fontSize: _left == 0 || _left > 3 ? 64 : 120, height: 1, color: c.accent),
                ),
              ),
              const SizedBox(height: 16),
              Text(_left == 0 ? 'Press play now' : 'Get ready to press play', style: AppText.body.copyWith(color: c.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
