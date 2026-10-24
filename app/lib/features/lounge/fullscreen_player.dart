import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../data/demo_images.dart';
import 'media_stage.dart';
import 'player_controller.dart';

/// Immersive watch-together view (YouTube player area + shared controls).
class FullscreenPlayer extends StatefulWidget {
  const FullscreenPlayer({super.key, required this.title, this.player});

  final String title;

  /// Shares the Lounge's playback clock when opened from there.
  final PlayerController? player;

  @override
  State<FullscreenPlayer> createState() => _FullscreenPlayerState();
}

class _FullscreenPlayerState extends State<FullscreenPlayer> with TickerProviderStateMixin {
  PlayerController? _own;

  PlayerController get _player => widget.player ?? (_own ??= PlayerController(vsync: this, total: const Duration(minutes: 42, seconds: 7), start: Duration.zero)..title = widget.title);

  @override
  void initState() {
    super.initState();
    if (widget.player == null) _player.play();
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CoverImage(DemoImages.neonStreet),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB3000000), Color(0x00000000), Color(0x00000000), Color(0xF2100C18)],
                stops: [0, 0.25, 0.5, 0.85],
              ),
            ),
          ),
          Positioned(
            top: pad.top + 12,
            left: 16,
            right: 16,
            child: FadePop(
              child: Row(
                children: [
                  RoundIconButton(icon: Symbols.arrow_back, color: AppColors.ink(0.7), semanticLabel: 'Back', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListenableBuilder(
                          listenable: _player,
                          builder: (_, _) => Text(_player.title, style: AppText.subhead, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text('Watching together • YouTube', style: AppText.label.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  Tag(label: 'E2EE', icon: Symbols.lock, color: AppColors.mint, background: AppColors.ink(0.7), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                ],
              ),
            ),
          ),
          Positioned(top: pad.top + 72, right: 16, child: const FadePop(delay: Duration(milliseconds: 120), child: PartnerPip(width: 104, height: 140))),
          Positioned(
            left: 16,
            right: 16,
            bottom: pad.bottom + 20,
            child: FadePop(
              delay: const Duration(milliseconds: 80),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final e in const ['❤️', '😂', '😮', '🥹', '🍿'])
                        Builder(
                          builder: (c) => Pressable(
                            pressedScale: 0.8,
                            onTap: () => showEmojiBurst(c, e),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: AppColors.raised(0.8), shape: BoxShape.circle),
                              child: Text(e, style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SyncedScrubber(player: _player),
                  const SizedBox(height: 16),
                  PlayerControls(player: _player),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
