import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';
import 'youtube_link.dart';

/// Shared playlists ("Our songs", "Watch later").
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return StreamBuilder<List<Playlist>>(
      stream: state.backend.playlists,
      builder: (context, snap) {
        final lists = snap.data ?? const <Playlist>[];
        return SubPage(
          title: 'Playlists',
          actions: [
            RoundIconButton(icon: Symbols.add, color: Colors.transparent, semanticLabel: 'New playlist', onTap: () => _newPlaylist(context)),
          ],
          children: [
            for (final p in lists)
              Pressable(
                onTap: () => context.pushPop(PlaylistScreen(playlistId: p.id)),
                pressedScale: 0.98,
                semanticLabel: p.name,
                child: AmourCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _Cover(items: p.items),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: AppText.headline),
                            const SizedBox(height: 2),
                            Text('${p.items.length} ${p.items.length == 1 ? 'item' : 'items'}', style: AppText.small.copyWith(color: context.colors.textMuted)),
                          ],
                        ),
                      ),
                      Sym(Symbols.chevron_right, color: context.colors.textFaint),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _newPlaylist(BuildContext context) async {
    final name = await showAmourSheet<String>(context, builder: (_) => const _TextSheet(title: 'New playlist', hint: 'Name it', action: 'Create'));
    if (name == null || name.isEmpty || !context.mounted) return;
    await AppScope.read(context).backend.createPlaylist(name);
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.items});

  final List<QueueItem> items;

  @override
  Widget build(BuildContext context) {
    final thumb = items.where((i) => i.thumbnail != null).map((i) => i.thumbnail!).firstOrNull;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 60,
        height: 60,
        child: thumb != null
            ? CoverImage(thumb)
            : const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.pinkViolet), child: Center(child: Sym(Symbols.queue_music, color: Colors.white))),
      ),
    );
  }
}

/// One playlist: play everything or add/remove items.
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final c = context.colors;
    return StreamBuilder<List<Playlist>>(
      stream: state.backend.playlists,
      builder: (context, snap) {
        final p = snap.data?.where((p) => p.id == playlistId).firstOrNull;
        if (p == null) return const SubPage(title: 'Playlist', children: []);
        return SubPage(
          title: p.name,
          actions: [
            RoundIconButton(icon: Symbols.add, color: Colors.transparent, semanticLabel: 'Add a video', onTap: () => _add(context)),
          ],
          bottom: p.items.isEmpty
              ? null
              : GradientButton(
                  label: 'Add all to queue',
                  icon: Symbols.queue_play_next,
                  onTap: () async {
                    for (final i in p.items) {
                      await state.backend.addToQueue(title: i.title, subtitle: i.subtitle, mediaId: i.mediaId, duration: i.duration);
                    }
                    if (!context.mounted) return;
                    showToast(context, 'Added ${p.items.length} to your queue', icon: Symbols.queue_music);
                    state.selectTab(1);
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
          children: [
            if (p.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Sym(Symbols.queue_music, size: 36, color: c.accent),
                    const SizedBox(height: 8),
                    Text('Nothing here yet', style: AppText.subhead),
                    const SizedBox(height: 14),
                    TonalButton(label: 'Add a video', icon: Symbols.add, expand: false, onTap: () => _add(context)),
                  ],
                ),
              ),
            for (final item in p.items)
              Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => state.backend.removeFromPlaylist(p.id, item.id),
                background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: Sym(Symbols.delete, color: c.danger)),
                child: AmourCard(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(width: 52, height: 52, child: item.thumbnail != null ? CoverImage(item.thumbnail!) : ColoredBox(color: c.surfaceHigh)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: AppText.subhead, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(item.subtitle.isEmpty ? 'Added by ${item.addedBy}' : item.subtitle, style: AppText.small.copyWith(color: c.textMuted), maxLines: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _add(BuildContext context) async {
    final link = await showAmourSheet<String>(context, builder: (_) => const _TextSheet(title: 'Add a video', hint: 'Paste a YouTube link', action: 'Add'));
    if (link == null || !context.mounted) return;
    final id = youtubeVideoId(link);
    if (id == null) {
      showToast(context, 'That isn’t a YouTube video link', icon: Symbols.link_off, color: context.colors.danger);
      return;
    }
    final info = await fetchYoutubeInfo(id);
    if (!context.mounted) return;
    await AppScope.read(context).backend.addToPlaylist(playlistId, title: info?.title ?? 'YouTube video', subtitle: info?.channel ?? '', mediaId: id);
  }
}

/// One text field + button sheet; pops with the entered text.
class _TextSheet extends StatefulWidget {
  const _TextSheet({required this.title, required this.hint, required this.action});

  final String title;
  final String hint;
  final String action;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourSheet(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
            child: TextField(
              controller: _text,
              autofocus: true,
              style: AppText.body.copyWith(color: c.text),
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
              decoration: InputDecoration(border: InputBorder.none, hintText: widget.hint, hintStyle: AppText.body.copyWith(color: c.textFaint)),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(label: widget.action, onTap: () => Navigator.of(context).pop(_text.text.trim())),
        ],
      ),
    );
  }
}
