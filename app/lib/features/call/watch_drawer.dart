import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../../data/models.dart';
import '../lounge/add_media_sheet.dart';
import '../lounge/fullscreen_player.dart';
import '../lounge/movie_night_screen.dart';
import 'call_screen.dart';

/// "Watch Together" synced lounge drawer shown over a live call.
class WatchTogetherDrawer extends StatefulWidget {
  const WatchTogetherDrawer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<WatchTogetherDrawer> createState() => _WatchTogetherDrawerState();
}

class _WatchTogetherDrawerState extends State<WatchTogetherDrawer> {
  bool _playing = true;
  int _reaction = 3;

  @override
  Widget build(BuildContext context) {
    final queue = AppScope.of(context).queue;
    final maxH = MediaQuery.sizeOf(context).height * 0.52;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xF22C2834),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(24)),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: const [BoxShadow(color: AppColors.bg, blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 4,
              width: double.infinity,
              child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.lavender, AppColors.primary, AppColors.hotPink]))),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.outlineVariant.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _header(context),
                  const SizedBox(height: 14),
                  _tabs(context),
                  const SizedBox(height: 14),
                  _player(context),
                  const SizedBox(height: 14),
                  _reactions(context),
                  const SizedBox(height: 18),
                  _queueHeader(context, queue.length),
                  const SizedBox(height: 8),
                  for (final item in queue.take(3)) ...[_queueTile(context, item), const SizedBox(height: 8)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const IconBadge(icon: Symbols.smart_display, color: AppColors.hotPink, size: 28, iconSize: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Watch Together', style: AppText.subhead),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Tag(
                      label: '⚡ 0ms Lockstep Sync',
                      color: AppColors.mint,
                      background: AppColors.mintDeep.withValues(alpha: 0.3),
                      dot: const Dot(color: AppColors.mint, size: 6),
                      gap: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    ),
                  ),
                ],
              ),
              Text('${Mock.partner} is synchronized to your playback', style: AppText.small.copyWith(fontSize: 11)),
            ],
          ),
        ),
        RoundIconButton(
          icon: Symbols.open_in_full,
          size: 28,
          iconSize: 14,
          color: AppColors.surfaceHighest.withValues(alpha: 0.8),
          semanticLabel: 'Open full screen',
          onTap: () => context.pushPop(const FullscreenPlayer(title: 'Lo-Fi Beats & Chill Synthwave')),
        ),
        const SizedBox(width: 6),
        CloseDot(onTap: widget.onClose),
      ],
    );
  }

  Widget _tabs(BuildContext context) {
    Widget tab({required String label, required IconData icon, required bool active, required VoidCallback onTap, bool trailingDot = false}) => Expanded(
          child: Pressable(
            onTap: onTap,
            haptic: PressFeedback.selection,
            child: AnimatedContainer(
              duration: Motion.medium,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                gradient: active ? AppGradients.mintTab : null,
                borderRadius: BorderRadius.circular(999),
                boxShadow: active ? [BoxShadow(color: AppColors.mint.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Sym(icon, size: 15, color: active ? AppColors.onMint : AppColors.onSurfaceVariant, fill: active),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (active ? AppText.smallBold : AppText.small).copyWith(color: active ? AppColors.onMint : AppColors.onSurfaceVariant, letterSpacing: 0),
                    ),
                  ),
                  if (trailingDot) ...[const SizedBox(width: 4), const Dot(color: Colors.white, size: 7)],
                ],
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.ink(0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          tab(label: 'YouTube', icon: Symbols.smart_display, active: true, trailingDot: true, onTap: () {}),
          tab(
            label: 'Spotify Dual',
            icon: Symbols.graphic_eq,
            active: false,
            onTap: () => showComingSoon(context, 'Spotify Dual sync', icon: Symbols.graphic_eq),
          ),
          tab(label: 'Watchlist (14)', icon: Symbols.bookmark, active: false, onTap: () => context.pushPop(const MovieNightScreen())),
        ],
      ),
    );
  }

  Widget _player(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const CoverImage(DemoImages.neonStreet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lo-Fi Beats & Chill Synthwave', style: AppText.smallBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Tag(label: 'YouTube Synced', icon: Symbols.sync, color: AppColors.mint, background: AppColors.mint.withValues(alpha: 0.2), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                        Text('1080p HD', style: AppText.label.copyWith(color: AppColors.mintBright)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const LiveBars(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(48)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RoundIconButton(icon: Symbols.replay_10, size: 36, iconSize: 20, color: Colors.transparent, semanticLabel: 'Back 10 seconds', onTap: () {}),
                Pressable(
                  onTap: () => setState(() => _playing = !_playing),
                  pressedScale: 0.86,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.playButton),
                    child: Sym(_playing ? Symbols.pause : Symbols.play_arrow, size: 22, color: Colors.white, fill: true),
                  ),
                ),
                RoundIconButton(icon: Symbols.forward_10, size: 36, iconSize: 20, color: Colors.transparent, semanticLabel: 'Forward 10 seconds', onTap: () {}),
                Text('03:24 / 06:18', style: AppText.mono.copyWith(color: AppColors.primary)),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactions(BuildContext context) {
    const options = [('🍿', 'Popcorn'), ('🥺', 'Aww'), ('🤣', 'Haha'), ('💖', 'Kiss')];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.muted(0.6),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Sym(Symbols.favorite, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Stream\nSpark:', style: AppText.labelSemi.copyWith(fontSize: 11, height: 1.3)),
          const Spacer(),
          for (var i = 0; i < options.length; i++)
            Builder(
              builder: (c) {
                final active = i == _reaction;
                return Pressable(
                  pressedScale: 0.85,
                  onTap: () {
                    setState(() => _reaction = i);
                    showEmojiBurst(c, options[i].$1);
                  },
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? AppColors.hotPink.withValues(alpha: 0.2) : AppColors.surfaceHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: active ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
                    ),
                    child: Text(
                      '${options[i].$1} ${options[i].$2}',
                      style: (active ? AppText.label : AppText.labelSemi).copyWith(color: active ? AppColors.primary : AppColors.onSurface, letterSpacing: 0),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _queueHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const Sym(Symbols.queue_music, size: 16, color: AppColors.onSurface),
          const SizedBox(width: 6),
          Text('Up Next in Shared Queue', style: AppText.smallBold),
          const SizedBox(width: 6),
          Tag(label: '$count queued', color: AppColors.mint, background: AppColors.surfaceHighest, padding: const EdgeInsets.symmetric(horizontal: 6)),
          const Spacer(),
          Pressable(
            onTap: () => showAmourSheet(context, builder: (_) => const AddMediaSheet()),
            child: Row(
              children: [
                const Sym(Symbols.add, size: 14, color: AppColors.mint),
                const SizedBox(width: 2),
                Text('Add', style: AppText.smallBold.copyWith(color: AppColors.mint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueTile(BuildContext context, QueueItem item) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                ClipOval(child: SizedBox.square(dimension: 44, child: Image(image: item.image, fit: BoxFit.cover))),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(16)),
                    child: Text(item.duration.length > 5 ? item.duration.substring(0, 5) : item.duration, style: AppText.labelRegular.copyWith(fontSize: 8, letterSpacing: 0, color: Colors.white, height: 1.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(item.title, style: AppText.smallStrong.copyWith(letterSpacing: 0), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Tag(label: 'YOUTUBE', color: AppColors.mint, background: AppColors.mintDeep.withValues(alpha: 0.3), padding: const EdgeInsets.symmetric(horizontal: 4), style: AppText.label.copyWith(fontSize: 8, letterSpacing: 0)),
                  ],
                ),
                Text('${item.subtitle} • Added by ${item.addedBy == 'Julian' ? 'You' : item.addedBy}', style: AppText.labelRegular.copyWith(letterSpacing: 0), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 6),
          RoundIconButton(
            icon: Symbols.favorite,
            size: 28,
            iconSize: 15,
            color: AppColors.surfaceHighest,
            iconColor: AppColors.primary,
            semanticLabel: 'Love this',
            onTap: () => showEmojiBurst(context, '💗', count: 4),
          ),
          const SizedBox(width: 4),
          RoundIconButton(icon: Symbols.drag_indicator, size: 28, iconSize: 15, color: AppColors.surfaceHighest, semanticLabel: 'Reorder', onTap: () {}),
        ],
      ),
    );
  }
}
