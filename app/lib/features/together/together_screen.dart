import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';
import 'add_media_sheet.dart';
import 'local_player.dart';
import 'movie_night_screen.dart';
import 'playlists_screen.dart';
import 'watch_together.dart';

/// Watch and listen together: one synced player and a shared queue.
class TogetherScreen extends StatefulWidget {
  const TogetherScreen({super.key});

  @override
  State<TogetherScreen> createState() => _TogetherScreenState();
}

class _TogetherScreenState extends State<TogetherScreen> with SingleTickerProviderStateMixin {
  late final LocalPlayer _player = LocalPlayer.create(this);
  WatchTogether? _watch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (_watch == null) {
      _watch = WatchTogether(backend: state.backend, player: _player, myId: state.account?.uid ?? 'me', queue: state.queue);
    } else {
      _watch!.queue = state.queue;
    }
    // Hidden tab or covered by another screen: pause here only.
    _watch!.visible = TickerMode.valuesOf(context).enabled && (ModalRoute.of(context)?.isCurrent ?? true);
  }

  @override
  void dispose() {
    _watch?.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final insets = ShellInsets.of(context);
    final watch = _watch!;
    final children = <Widget>[
      const TabHeader(title: 'Together', subtitle: 'Watch and listen in sync'),
      ListenableBuilder(listenable: watch, builder: (context, _) => _PlayerCard(watch: watch, partner: state.partnerName)),
      SectionHeader(title: 'Up next', action: 'Add', onAction: () => showAddMediaSheet(context)),
      if (state.queue.isEmpty)
        _EmptyQueue(onAdd: () => showAddMediaSheet(context))
      else
        ListenableBuilder(listenable: watch, builder: (context, _) => _QueueList(watch: watch)),
      Row(
        children: [
          Expanded(child: _Tile(icon: Symbols.queue_music, title: 'Playlists', onTap: () => context.pushPop(const PlaylistsScreen()))),
          const SizedBox(width: 12),
          Expanded(child: _Tile(icon: Symbols.movie, title: 'Movie night', onTap: () => context.pushPop(const MovieNightScreen()))),
        ],
      ),
    ];
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, insets.top, 16, insets.bottom + 24),
      itemCount: children.length,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(top: i <= 1 ? 8 : 18),
        child: FadePop.index(i, child: children[i]),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.watch, required this.partner});

  final WatchTogether watch;
  final String partner;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = watch.current;
    final player = watch.player;
    return AmourCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: const Color(0xFF000000), child: player.view(cover: item?.thumbnail ?? DemoImages.neonStreet)),
                Positioned(
                  left: 10,
                  top: 10,
                  child: _SyncChip(label: watch.shared == null ? 'Ready' : 'In sync with $partner', live: watch.playing),
                ),
                if (player.supportsFullscreen)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: RoundIconButton(
                      icon: Symbols.fullscreen,
                      onTap: player.toggleFullscreen,
                      size: 36,
                      iconSize: 20,
                      color: const Color(0x66000000),
                      iconColor: Colors.white,
                      semanticLabel: 'Full screen',
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item?.title ?? 'Nothing queued yet', style: AppText.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item == null ? 'Add a video to start' : 'Added by ${item.addedBy}', style: AppText.small.copyWith(color: c.textMuted)),
                const SizedBox(height: 12),
                _Scrubber(watch: watch),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RoundIconButton(icon: Symbols.replay_10, onTap: () => watch.skip(-10), color: Colors.transparent, semanticLabel: 'Back 10 seconds'),
                    RoundIconButton(
                      icon: watch.playing ? Symbols.pause : Symbols.play_arrow,
                      onTap: item == null ? null : watch.togglePlay,
                      size: 60,
                      iconSize: 32,
                      gradient: AppGradients.pinkViolet,
                      fill: true,
                      semanticLabel: watch.playing ? 'Pause' : 'Play',
                    ),
                    RoundIconButton(icon: Symbols.forward_10, onTap: () => watch.skip(10), color: Colors.transparent, semanticLabel: 'Forward 10 seconds'),
                    RoundIconButton(icon: Symbols.skip_next, onTap: watch.next, color: Colors.transparent, fill: true, semanticLabel: 'Next'),
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

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.label, required this.live});

  final String label;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0x8C000000), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) const PingDot(color: Color(0xFF4EDEA3), size: 6) else const Sym(Symbols.sync, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Scrubber extends StatefulWidget {
  const _Scrubber({required this.watch});

  final WatchTogether watch;

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final player = widget.watch.player;
    return ValueListenableBuilder<Duration>(
      valueListenable: player.position,
      builder: (context, pos, _) {
        final total = player.duration.inMilliseconds == 0 ? (widget.watch.current?.duration ?? Duration.zero) : player.duration;
        final f = _drag ?? (total.inMilliseconds == 0 ? 0.0 : (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0));
        return Column(
          children: [
            LayoutBuilder(
              builder: (context, box) {
                void update(double dx) => setState(() => _drag = (dx / box.maxWidth).clamp(0.0, 1.0));
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) => update(d.localPosition.dx),
                  onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
                  onHorizontalDragEnd: (_) {
                    final to = total * (_drag ?? 0);
                    setState(() => _drag = null);
                    widget.watch.seek(to);
                  },
                  onTapUp: (d) => widget.watch.seek(total * (d.localPosition.dx / box.maxWidth).clamp(0.0, 1.0)),
                  child: SizedBox(
                    height: 24,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(height: 4, decoration: BoxDecoration(color: c.surfaceHighest, borderRadius: BorderRadius.circular(999))),
                        Container(width: box.maxWidth * f, height: 4, decoration: BoxDecoration(gradient: AppGradients.pinkLilac, borderRadius: BorderRadius.circular(999))),
                        Positioned(
                          left: (box.maxWidth * f - 7).clamp(0.0, box.maxWidth - 14),
                          child: Container(width: 14, height: 14, decoration: BoxDecoration(color: c.pink, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                Text(formatClock(_drag != null ? total * _drag! : pos), style: AppText.mono.copyWith(color: c.textMuted)),
                const Spacer(),
                Text(formatClock(total), style: AppText.mono.copyWith(color: c.textMuted)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.watch});

  final WatchTogether watch;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final queue = state.queue;
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: queue.length,
      onReorderItem: (from, to) {
        final ids = [for (final q in queue) q.id];
        ids.insert(to, ids.removeAt(from));
        state.backend.reorderQueue(ids);
      },
      proxyDecorator: (child, _, _) => Material(type: MaterialType.transparency, child: child),
      itemBuilder: (context, i) {
        final item = queue[i];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey('dismiss-${item.id}'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => state.backend.removeFromQueue(item.id),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: context.colors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Sym(Symbols.delete, color: context.colors.danger),
            ),
            child: _QueueRow(item: item, index: i, current: watch.current?.id == item.id, onTap: () => watch.playItem(item)),
          ),
        );
      },
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item, required this.index, required this.current, required this.onTap});

  final QueueItem item;
  final int index;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: 'Play ${item.title}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: current ? c.pink.withValues(alpha: c.isDark ? 0.14 : 0.08) : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: current ? c.pink.withValues(alpha: 0.35) : c.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: item.thumbnail != null ? CoverImage(item.thumbnail!) : ColoredBox(color: c.surfaceHigh, child: Sym(Symbols.smart_display, color: c.textMuted)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppText.subhead, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    current ? 'Now playing' : '${item.durationLabel} · ${item.addedBy}',
                    style: AppText.small.copyWith(color: current ? c.accent : c.textMuted),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              child: Padding(padding: const EdgeInsets.all(8), child: Sym(Symbols.drag_indicator, color: c.textFaint)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourCard(
      child: Column(
        children: [
          Sym(Symbols.smart_display, size: 32, color: c.accent),
          const SizedBox(height: 8),
          Text('Your queue is empty', style: AppText.subhead),
          const SizedBox(height: 4),
          Text('Paste a YouTube link to watch or listen together.', textAlign: TextAlign.center, style: AppText.small.copyWith(color: c.textMuted)),
          const SizedBox(height: 14),
          TonalButton(label: 'Add a video', icon: Symbols.add, onTap: onAdd, expand: false),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticLabel: title,
      child: AmourCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconBadge(icon: icon, size: 36, iconSize: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AppText.subhead, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
