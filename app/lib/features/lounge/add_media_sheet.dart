import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';

/// Add a YouTube video/playlist (or a Spotify link) to the shared queue.
class AddMediaSheet extends StatefulWidget {
  const AddMediaSheet({super.key});

  @override
  State<AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends State<AddMediaSheet> {
  final _link = TextEditingController();

  static const _suggestions = [
    ('Lo-fi Paris Café Jazz', 'YouTube • 1:02:11', DemoImages.queueParis, '1:02:11'),
    ('Rainy Kyoto Night Walk', 'YouTube 4K • 48:30', DemoImages.kyoto, '48:30'),
    ('Ghibli Piano for Two', 'YouTube • 38:05', DemoImages.queueGhibli, '38:05'),
  ];

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _add(String title, String subtitle, ImageProvider image, String duration) {
    final state = AppScope.read(context);
    state.addToQueue(QueueItem(
      id: 'added-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      duration: duration,
      image: image,
      addedBy: 'Julian',
    ));
    Navigator.of(context).pop();
    showLoveToast(context, 'Added to your shared queue', icon: Symbols.queue_music, color: AppColors.mint);
  }

  void _addLink() {
    final url = _link.text.trim();
    if (url.isEmpty) return;
    final isSpotify = url.contains('spotify');
    _add(isSpotify ? 'Spotify link' : 'Shared YouTube video', isSpotify ? 'Opens in Spotify' : url, DemoImages.neonStreet, '00:00');
  }

  @override
  Widget build(BuildContext context) {
    return AmourSheet(
      title: 'Add to Shared Queue',
      subtitle: 'Paste a YouTube link — it plays in sync for both of you.',
      icon: Symbols.add_circle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                const Sym(Symbols.link, size: 18, color: AppColors.outline),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _link,
                    style: AppText.body,
                    keyboardType: TextInputType.url,
                    onSubmitted: (_) => _addLink(),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'youtube.com/watch?v=…',
                      hintStyle: AppText.body.copyWith(color: AppColors.outline),
                    ),
                  ),
                ),
                RoundIconButton(icon: Symbols.add, size: 40, iconSize: 20, gradient: const LinearGradient(colors: [AppColors.hotPink, AppColors.primary]), iconColor: Colors.white, onTap: _addLink),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('SUGGESTED FOR TONIGHT', style: AppText.label.copyWith(color: AppColors.lavender)),
          const SizedBox(height: 10),
          for (var i = 0; i < _suggestions.length; i++)
            FadePop.index(
              i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Pressable(
                  pressedScale: 0.98,
                  onTap: () => _add(_suggestions[i].$1, _suggestions[i].$2, _suggestions[i].$3, _suggestions[i].$4),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 40, child: CoverImage(_suggestions[i].$3))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_suggestions[i].$1, style: AppText.smallStrong),
                              Text(_suggestions[i].$2, style: AppText.small),
                            ],
                          ),
                        ),
                        const Sym(Symbols.add_circle, size: 22, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
