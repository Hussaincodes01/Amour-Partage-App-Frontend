import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/waveform.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import 'fullscreen_player.dart';
import 'player_controller.dart';

/// Main synced player card: artwork + partner PIP + metadata + controls.
class MediaStage extends StatelessWidget {
  const MediaStage({super.key, required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 224, child: _Artwork(player: player)),
          ColoredBox(
            color: AppColors.ink(0.9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Meta(player: player),
                  const SizedBox(height: 16),
                  SyncedScrubber(player: player),
                  const SizedBox(height: 16),
                  PlayerControls(player: player),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const CoverImage(DemoImages.neonStreet),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.bg, Color(0x4D100C18), Color(0x99000000)],
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Row(
            children: [
              Tag(
                label: 'LIVE STREAM',
                icon: Symbols.sensors,
                iconSize: 14,
                gap: 6,
                color: AppColors.onSurface,
                background: AppColors.ink(0.8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                style: AppText.labelSemi,
              ),
              const SizedBox(width: 8),
              Tag(
                label: 'E2EE Tunnel',
                icon: Symbols.lock,
                iconSize: 12,
                color: AppColors.onSurfaceVariant,
                background: AppColors.ink(0.6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Row(
            children: [
              RoundIconButton(
                icon: Symbols.cast,
                size: 32,
                iconSize: 16,
                color: AppColors.ink(0.8),
                semanticLabel: 'Cast to TV',
                onTap: () => showComingSoon(context, 'Cast to TV', icon: Symbols.cast),
              ),
              const SizedBox(width: 6),
              RoundIconButton(
                icon: Symbols.fullscreen,
                size: 32,
                iconSize: 18,
                color: AppColors.ink(0.8),
                semanticLabel: 'Full screen',
                onTap: () => context.pushPop(FullscreenPlayer(title: player.title, player: player)),
              ),
            ],
          ),
        ),
        const Positioned(right: 14, bottom: 14, child: PartnerPip()),
      ],
    );
  }
}

/// Floating partner camera bubble with live audio bars.
class PartnerPip extends StatefulWidget {
  const PartnerPip({super.key, this.width = 96, this.height = 128});

  final double width;
  final double height;

  @override
  State<PartnerPip> createState() => _PartnerPipState();
}

class _PartnerPipState extends State<PartnerPip> {
  bool _mic = true;
  bool _cam = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.raised(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(duration: Motion.medium, opacity: _cam ? 1 : 0.15, child: const CoverImage(DemoImages.partnerCam)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x00000000), Color(0xB3000000)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Dot(color: AppColors.mint, size: 6, glow: true),
                      const Spacer(),
                      Text(Mock.partner, style: AppText.label.copyWith(fontSize: 9, color: Colors.white, letterSpacing: -0.2)),
                    ],
                  ),
                ),
                const Spacer(),
                Waveform(
                  heights: const [8, 12, 6, 10, 4],
                  colors: const [AppColors.primary, AppColors.hotPink, AppColors.lavender, AppColors.primary, AppColors.mint],
                  barWidth: 2,
                  gap: 2,
                  live: _mic,
                  maxHeight: 12,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MiniToggle(icon: _mic ? Symbols.mic : Symbols.mic_off, onTap: () => setState(() => _mic = !_mic)),
                      _MiniToggle(icon: _cam ? Symbols.videocam : Symbols.videocam_off, onTap: () => setState(() => _cam = !_cam)),
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

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        haptic: PressFeedback.selection,
        child: Padding(padding: const EdgeInsets.all(5), child: Sym(icon, size: 13, color: Colors.white)),
      );
}

class _Meta extends StatefulWidget {
  const _Meta({required this.player});

  final PlayerController player;

  @override
  State<_Meta> createState() => _MetaState();
}

class _MetaState extends State<_Meta> {
  bool _loved = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: widget.player,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.player.title, style: AppText.titleBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(child: Text('Late Night Synchrony Session', style: AppText.small.copyWith(color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    const Dot(color: AppColors.onSurfaceVariant, size: 4),
                    const SizedBox(width: 8),
                    Text('YouTube HD', style: AppText.small),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Pressable(
          onTap: () {
            setState(() => _loved = !_loved);
            if (_loved) showEmojiBurst(context, '💗', count: 5);
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Motion.pop), child: c),
              child: Sym(Symbols.favorite, key: ValueKey(_loved), size: 22, color: _loved ? AppColors.primary : AppColors.onSurfaceVariant, fill: _loved),
            ),
          ),
        ),
      ],
    );
  }
}

/// Track with both partners' cursors pinned to the shared playhead.
class SyncedScrubber extends StatelessWidget {
  const SyncedScrubber({super.key, required this.player, this.showSynced = true});

  final PlayerController player;
  final bool showSynced;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: player.position,
      builder: (context, pos, _) {
        final f = player.progress.clamp(0.0, 1.0);
        return Column(
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                void seekTo(double dx) => player.seekFraction(dx / w);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) {
                    HapticFeedback.selectionClick();
                    seekTo(d.localPosition.dx);
                  },
                  onHorizontalDragUpdate: (d) => seekTo(d.localPosition.dx),
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(color: AppColors.surfaceHighest, borderRadius: BorderRadius.circular(999)),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.75,
                          child: Container(height: 8, decoration: BoxDecoration(color: AppColors.surfaceBright.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999))),
                        ),
                        FractionallySizedBox(
                          widthFactor: f,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(gradient: AppGradients.pinkLavender, borderRadius: BorderRadius.circular(999)),
                          ),
                        ),
                        Positioned(
                          left: (w * f - 10).clamp(0, w - 20),
                          top: 4,
                          child: SizedBox(
                            width: 30,
                            height: 24,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Positioned(left: 0, top: 0, child: _Cursor(letter: 'J', color: AppColors.hotPink, size: 20, text: Colors.white)),
                                Positioned(left: 12, top: -4, child: _Cursor(letter: 'C', color: AppColors.lavender, size: 16, text: AppColors.onLavender)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  Text(formatClock(pos), style: AppText.mono.copyWith(color: AppColors.primary)),
                  if (showSynced) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(16)),
                      child: Text('SYNCED', style: AppText.mono.copyWith(fontSize: 9)),
                    ),
                  ],
                  const Spacer(),
                  Text(formatClock(player.total), style: AppText.mono),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Cursor extends StatelessWidget {
  const _Cursor({required this.letter, required this.color, required this.size, required this.text});

  final String letter;
  final Color color;
  final double size;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 5)]),
      child: Text(letter, style: AppText.label.copyWith(fontSize: size * 0.45, height: 1, letterSpacing: 0, color: text)),
    );
  }
}

/// Volume · −10s · play/pause · +10s · resync.
class PlayerControls extends StatefulWidget {
  const PlayerControls({super.key, required this.player, this.dark = false});

  final PlayerController player;
  final bool dark;

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RoundIconButton(
            icon: p.muted ? Symbols.volume_off : Symbols.volume_up,
            size: 40,
            iconSize: 20,
            semanticLabel: p.muted ? 'Unmute' : 'Mute',
            onTap: p.toggleMute,
          ),
          Row(
            children: [
              RoundIconButton(icon: Symbols.replay_10, size: 44, iconSize: 24, color: AppColors.raised(0.8), semanticLabel: 'Back 10 seconds', onTap: () => p.skip(-10)),
              const SizedBox(width: 16),
              Pressable(
                onTap: p.toggle,
                pressedScale: 0.88,
                haptic: PressFeedback.medium,
                semanticLabel: p.playing ? 'Pause for both' : 'Play for both',
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.playButton,
                    boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.45), blurRadius: 14)],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Motion.pop), child: FadeTransition(opacity: a, child: c)),
                    child: Sym(p.playing ? Symbols.pause : Symbols.play_arrow, key: ValueKey(p.playing), size: 30, color: Colors.white, fill: true),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              RoundIconButton(icon: Symbols.forward_10, size: 44, iconSize: 24, color: AppColors.raised(0.8), semanticLabel: 'Forward 10 seconds', onTap: () => p.skip(10)),
            ],
          ),
          Pressable(
            semanticLabel: 'Resync with partner',
            onTap: () {
              _spin.forward(from: 0);
              showLoveToast(context, 'Locked to ${Mock.partner} • 0ms drift', icon: Symbols.sync, color: AppColors.mint);
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
              child: RotationTransition(
                turns: CurvedAnimation(parent: _spin, curve: Motion.emphasized),
                child: const Sym(Symbols.sync, size: 18, color: AppColors.mint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "⚡ PERFECTLY IN-SYNC" status pill.
class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xE61D1A26), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const PingDot(color: AppColors.mint, size: 8, glow: false),
          const SizedBox(width: 8),
          Expanded(
            child: Text('⚡ PERFECTLY IN-SYNC (0MS DELAY)', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.copyWith(color: AppColors.mint, letterSpacing: 0.25)),
          ),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${Mock.me} ', style: AppText.labelSemi.copyWith(color: AppColors.primary)),
                TextSpan(text: '(Host)', style: AppText.labelRegular),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Sym(Symbols.sync_alt, size: 13, color: AppColors.mint),
          const SizedBox(width: 6),
          Text(Mock.partner, style: AppText.labelSemi.copyWith(color: AppColors.lavender)),
        ],
      ),
    );
  }
}
