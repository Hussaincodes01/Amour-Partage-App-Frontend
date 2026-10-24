import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import 'add_media_sheet.dart';
import 'media_stage.dart';
import 'movie_night_screen.dart';
import 'player_controller.dart';
import 'playlists_screen.dart';

/// Watch & listen together: synced player, live reactions and shared queue.
class LoungeScreen extends StatefulWidget {
  const LoungeScreen({super.key});

  @override
  State<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends State<LoungeScreen> with TickerProviderStateMixin {
  late final PlayerController _player = PlayerController(vsync: this);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = ShellInsets.of(context);
    final sections = <Widget>[
      const _SourceToggle(),
      const SyncStatusPill(),
      MediaStage(player: _player),
      const _LiveSparksDock(),
      _SharedQueue(player: _player),
      _MomentMarker(player: _player),
      const _LibraryRow(),
    ];
    const gaps = <double>[8, 16, 16, 24, 16, 16];
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, insets.top + 12, 16, insets.bottom + 24),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: sections.length,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : gaps[i - 1]),
        child: FadePop.index(i, child: sections[i]),
      ),
    );
  }
}

class _SourceToggle extends StatelessWidget {
  const _SourceToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.ink(0.7),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Expanded(child: _SourceButton(label: 'YouTube Party', icon: Symbols.smart_display, active: true)),
          Expanded(
            child: _SourceButton(
              label: 'Spotify Dual',
              icon: Symbols.graphic_eq,
              active: false,
              onTap: () => showComingSoon(
                context,
                'Spotify Dual sync',
                icon: Symbols.graphic_eq,
                detail: 'Synced Spotify playback needs Spotify’s extended API access. Until then, share Spotify links in your queue and they open right in Spotify.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({required this.label, required this.icon, required this.active, this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.onSurfaceVariant;
    return Pressable(
      onTap: onTap ?? () {},
      haptic: PressFeedback.selection,
      child: AnimatedContainer(
        duration: Motion.medium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.hotPink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active ? [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.35), blurRadius: 8)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Sym(icon, size: 18, color: color, fill: active),
            const SizedBox(width: 8),
            Text(label, style: AppText.smallStrong.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _LiveSparksDock extends StatefulWidget {
  const _LiveSparksDock();

  @override
  State<_LiveSparksDock> createState() => _LiveSparksDockState();
}

class _LiveSparksDockState extends State<_LiveSparksDock> {
  static const _emojis = ['❤️', '🔥', '🥹', '✨', '😂'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink(0.8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10), spreadRadius: -3)],
      ),
      child: Row(
        children: [
          const Sym(Symbols.auto_awesome, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('LIVE SPARKS', style: AppText.label)),
          for (final e in _emojis) ...[
            const SizedBox(width: 8),
            Builder(
              builder: (btnContext) => Pressable(
                pressedScale: 0.82,
                onTap: () => showEmojiBurst(btnContext, e),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
                  child: Text(e, style: const TextStyle(fontSize: 18, height: 1.2)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SharedQueue extends StatelessWidget {
  const _SharedQueue({required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Shared Queue',
          titleStyle: AppText.titleBold,
          badge: Tag(
            label: '${state.queue.length} Up Next',
            color: AppColors.primary,
            background: AppColors.surfaceHigh,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
          trailing: 'Add Media',
          trailingStyle: AppText.smallStrong.copyWith(color: AppColors.primary),
          onTrailingTap: () => showAmourSheet(context, builder: (_) => const AddMediaSheet()),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: state.queue.length,
          onReorderItem: state.reorderQueue,
          proxyDecorator: (child, _, animation) => ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: animation, curve: Motion.pop)),
            child: Material(type: MaterialType.transparency, child: child),
          ),
          itemBuilder: (context, i) {
            final item = state.queue[i];
            return Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.only(bottom: 8),
              child: Dismissible(
                key: ValueKey('dismiss-${item.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  state.removeFromQueue(item.id);
                  showLoveToast(context, 'Removed from queue', icon: Symbols.playlist_remove, color: AppColors.lavender);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                  child: const Sym(Symbols.delete, size: 22, color: AppColors.error),
                ),
                child: _QueueTile(
                  item: item,
                  index: i,
                  onTap: () {
                    player.load(item.title, parseClock(item.duration));
                    player.play();
                    showLoveToast(context, 'Now playing for both of you', icon: Symbols.play_circle, color: AppColors.mint);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item, required this.index, required this.onTap});

  final QueueItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Widget tagIcon, String tagText, Color tagColor) = switch (item.addedBy) {
      'Camille' => (const InitialAvatar(text: 'C', color: AppColors.lavender, textColor: AppColors.onLavender), 'Added by Camille', AppColors.lavender),
      'Julian' => (const InitialAvatar(text: 'J', color: AppColors.hotPink), 'Added by Julian', AppColors.primary),
      _ => (const Sym(Symbols.favorite, size: 12, color: AppColors.mint), 'Shared Wishlist', AppColors.mint),
    };
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xCC1D1A26), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            ClipOval(child: SizedBox.square(dimension: 48, child: Image(image: item.image, fit: BoxFit.cover))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppText.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(item.subtitle, style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      tagIcon,
                      const SizedBox(width: 6),
                      Text(tagText, style: AppText.labelRegular.copyWith(color: tagColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(item.duration, style: AppText.mono),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 4, 8),
                child: Sym(Symbols.drag_handle, size: 20, color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentMarker extends StatefulWidget {
  const _MomentMarker({required this.player});

  final PlayerController player;

  @override
  State<_MomentMarker> createState() => _MomentMarkerState();
}

class _MomentMarkerState extends State<_MomentMarker> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.player.position,
      builder: (context, pos, _) => AmourCard(
        color: AppColors.raised(0.4),
        radius: 16,
        shadow: false,
        child: Row(
          children: [
            const IconBadge(icon: Symbols.bookmark_heart, color: AppColors.lavender, size: 40, iconSize: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Timestamp Memory Tag', style: AppText.headline),
                  Text('Save ${formatClock(pos)} to your private Vault', style: AppText.small),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              onTap: () {
                setState(() => _saved = true);
                showLoveToast(context, 'Moment saved to your Vault', icon: Symbols.bookmark_added, color: AppColors.lavender);
              },
              child: AnimatedContainer(
                duration: Motion.medium,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _saved ? AppColors.mint.withValues(alpha: 0.15) : AppColors.surfaceHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedSwitcher(
                  duration: Motion.fast,
                  child: Text(
                    _saved ? 'Saved ✓' : 'Save Tag',
                    key: ValueKey(_saved),
                    style: AppText.smallStrong.copyWith(color: _saved ? AppColors.mint : AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LibraryCard(
            icon: Symbols.queue_music,
            color: AppColors.primary,
            title: 'Our Playlists',
            subtitle: '3 shared lists',
            onTap: () => context.pushPop(const PlaylistsScreen()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LibraryCard(
            icon: Symbols.theaters,
            color: AppColors.lavender,
            title: 'Movie Night',
            subtitle: 'Watchlist & sync start',
            onTap: () => context.pushPop(const MovieNightScreen()),
          ),
        ),
      ],
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.96,
      child: AmourCard(
        color: AppColors.surfaceLow,
        radius: 24,
        shadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, color: color, size: 36, iconSize: 18),
            const SizedBox(height: 12),
            Text(title, style: AppText.bodyStrong),
            Text(subtitle, style: AppText.small),
          ],
        ),
      ),
    );
  }
}
