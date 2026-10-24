import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import 'add_media_sheet.dart';

class _Playlist {
  const _Playlist(this.name, this.count, this.image, this.color, this.icon, this.tracks);

  final String name;
  final String count;
  final ImageProvider image;
  final Color color;
  final IconData icon;
  final List<(String, String, String)> tracks;
}

const _playlists = [
  _Playlist('Our Songs', '24 songs • 1h 38m', DemoImages.queueApocalypse, AppColors.hotPink, Symbols.favorite, [
    ('Apocalypse', 'Cigarettes After Sex', 'YouTube'),
    ('La Vie en Rose', 'Édith Piaf', 'YouTube'),
    ('Quelqu’un m’a dit', 'Carla Bruni', 'Spotify link'),
    ('Space Song', 'Beach House', 'Spotify link'),
  ]),
  _Playlist('Watch Later', '9 videos • 4h 12m', DemoImages.queueParis, AppColors.lavender, Symbols.smart_display, [
    ('Paris Sunset 4K Walk', 'YouTube 4K', 'YouTube'),
    ('Tokyo Night Walk 4K', 'YouTube 4K', 'YouTube'),
    ('Cooking pasta together', 'Bon Appétit', 'YouTube'),
  ]),
  _Playlist('Late Night Lo-Fi', '31 tracks • 2h 05m', DemoImages.queueGhibli, AppColors.mint, Symbols.bedtime, [
    ('Studio Ghibli Ambient Mix', 'Joe Hisaishi', 'YouTube'),
    ('Midnight Jazz & Lo-Fi', 'Lofi Girl', 'YouTube'),
  ]),
];

/// Shared playlists ("Our Songs", "Watch Later", …).
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Our Playlists',
      subtitle: 'Shared • end-to-end encrypted',
      actions: [
        RoundIconButton(
          icon: Symbols.add,
          size: 40,
          iconSize: 20,
          gradient: AppGradients.pinkViolet,
          iconColor: Colors.white,
          semanticLabel: 'Add media',
          onTap: () => showAmourSheet(context, builder: (_) => const AddMediaSheet()),
        ),
      ],
      children: [
        for (final p in _playlists) _PlaylistCard(playlist: p),
        Pressable(
          onTap: () => showComingSoon(context, 'Import Spotify library', icon: Symbols.library_music),
          child: AmourCard(
            color: AppColors.surface,
            radius: 24,
            shadow: false,
            child: Row(
              children: [
                const IconBadge(icon: Symbols.library_add, color: AppColors.mint, size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Import from Spotify', style: AppText.bodyStrong),
                      Text('Bring your saved playlists over', style: AppText.small),
                    ],
                  ),
                ),
                const Tag(label: 'SOON', color: AppColors.lavender),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaylistCard extends StatefulWidget {
  const _PlaylistCard({required this.playlist});

  final _Playlist playlist;

  @override
  State<_PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<_PlaylistCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.playlist;
    return AmourCard(
      color: AppColors.surfaceLow,
      radius: 28,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Pressable(
            pressedScale: 0.98,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox.square(dimension: 64, child: CoverImage(p.image))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Sym(p.icon, size: 14, color: p.color, fill: true), const SizedBox(width: 6), Text(p.name, style: AppText.headline)]),
                        const SizedBox(height: 2),
                        Text(p.count, style: AppText.small),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: Symbols.play_arrow,
                    size: 40,
                    iconSize: 22,
                    fill: true,
                    gradient: AppGradients.playButton,
                    iconColor: Colors.white,
                    semanticLabel: 'Play ${p.name} together',
                    onTap: () {
                      AppScope.read(context).selectTab(1);
                      Navigator.of(context).pop();
                      showLoveToast(context, 'Playing “${p.name}” for both', icon: Symbols.play_circle, color: AppColors.mint);
                    },
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      children: [
                        for (final t in p.tracks)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Sym(t.$3 == 'YouTube' ? Symbols.smart_display : Symbols.open_in_new, size: 16, color: t.$3 == 'YouTube' ? AppColors.hotPink : AppColors.mint),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.$1, style: AppText.smallStrong),
                                      Text(t.$2, style: AppText.small),
                                    ],
                                  ),
                                ),
                                Text(t.$3, style: AppText.label),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
