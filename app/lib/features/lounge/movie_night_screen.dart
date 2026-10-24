import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import 'fullscreen_player.dart';

/// Movie Night: shared watchlist + a synced 3-2-1 start for any service.
class MovieNightScreen extends StatefulWidget {
  const MovieNightScreen({super.key});

  @override
  State<MovieNightScreen> createState() => _MovieNightScreenState();
}

class _MovieNightScreenState extends State<MovieNightScreen> {
  static const _services = ['Netflix', 'Prime Video', 'Disney+', 'Apple TV', 'YouTube'];
  int _service = 0;

  static const _watchlist = [
    ('Before Sunrise', '1995 • Romance', DemoImages.movieNight, false),
    ('Spirited Away', '2001 • Animation', DemoImages.queueGhibli, false),
    ('Paris, je t’aime', '2006 • Anthology', DemoImages.montmartre, true),
  ];

  void _startCountdown() {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xE6100C18),
      transitionDuration: Motion.medium,
      pageBuilder: (_, _, _) => _CountdownOverlay(service: _services[_service]),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Movie Night',
      subtitle: 'Press play at the exact same moment',
      bottom: GradientButton(
        label: 'Start 3-2-1 together',
        leadingIcon: Symbols.timer,
        gradient: AppGradients.pinkViolet,
        onTap: _startCountdown,
      ),
      children: [
        AmourCard(
          color: AppColors.surfaceLow,
          blooms: [Bloom(color: AppColors.hotPink.withValues(alpha: 0.2), size: 180, right: -60, top: -60)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHERE ARE YOU WATCHING?', style: AppText.label.copyWith(color: AppColors.lavender)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _services.length; i++)
                    Pressable(
                      haptic: PressFeedback.selection,
                      onTap: () => setState(() => _service = i),
                      child: AnimatedContainer(
                        duration: Motion.medium,
                        curve: Motion.emphasized,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: i == _service ? AppColors.hotPink : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: i == _service ? [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.3), blurRadius: 10)] : null,
                        ),
                        child: Text(_services[i], style: AppText.smallStrong.copyWith(color: i == _service ? Colors.white : AppColors.onSurfaceVariant)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Sym(Symbols.info, size: 14, color: AppColors.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Each of you opens the movie in your own app. We count down on both phones and keep a call bubble on top.',
                      style: AppText.small.copyWith(color: AppColors.outline),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text('Our Watchlist', style: AppText.title),
            const SizedBox(width: 8),
            Tag(label: '${_watchlist.length + 11} films', color: AppColors.primary, background: AppColors.surfaceHigh),
          ],
        ),
        for (final m in _watchlist)
          AmourCard(
            color: AppColors.surface,
            radius: 24,
            padding: const EdgeInsets.all(10),
            shadow: false,
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(width: 64, height: 84, child: CoverImage(m.$3))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.$1, style: AppText.headline),
                      Text(m.$2, style: AppText.small),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('${Mock.partner} wants to watch', style: AppText.label.copyWith(color: AppColors.lavender)),
                          const SizedBox(width: 4),
                          const Sym(Symbols.favorite, size: 12, color: AppColors.hotPink, fill: true),
                        ],
                      ),
                    ],
                  ),
                ),
                if (m.$4)
                  RoundIconButton(
                    icon: Symbols.play_arrow,
                    size: 40,
                    iconSize: 22,
                    fill: true,
                    gradient: AppGradients.playButton,
                    iconColor: Colors.white,
                    semanticLabel: 'Watch ${m.$1} together on YouTube',
                    onTap: () => context.pushPop(FullscreenPlayer(title: m.$1)),
                  )
                else
                  RoundIconButton(
                    icon: Symbols.event,
                    size: 40,
                    iconSize: 20,
                    iconColor: AppColors.primary,
                    semanticLabel: 'Plan movie night',
                    onTap: () => showLoveToast(context, 'Movie night invite sent', icon: Symbols.event_available, color: AppColors.lavender),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CountdownOverlay extends StatefulWidget {
  const _CountdownOverlay({required this.service});

  final String service;

  @override
  State<_CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<_CountdownOverlay> {
  int _value = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() => _value--);
      if (_value == 0) {
        showEmojiBurst(context, '🍿', count: 10);
      }
      if (_value < -1) {
        t.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _value > 0 ? '$_value' : 'Play!';
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Both phones on ${widget.service}', style: AppText.label.copyWith(color: AppColors.lavender)),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: Tween(begin: 1.6, end: 1.0).animate(CurvedAnimation(parent: a, curve: Motion.pop)), child: child),
              ),
              child: ShaderMask(
                key: ValueKey(text),
                shaderCallback: (r) => AppGradients.pinkLavender.createShader(r),
                child: Text(text, style: AppText.display.copyWith(fontSize: 96, height: 1.1, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Text(_value > 0 ? 'Get your thumb on play…' : 'Enjoy the movie, you two 💞', style: AppText.body),
          ],
        ),
      ),
    );
  }
}
