import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/demo_images.dart';

class _Milestone {
  const _Milestone(this.date, this.title, this.detail, this.icon, this.color, {this.image, this.upcoming = false});

  final String date;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final ImageProvider? image;
  final bool upcoming;
}

const _milestones = [
  _Milestone('Jan 4, 2027', '500 days together', '72 days to go — plan something sweet', Symbols.celebration, AppColors.hotPink, upcoming: true),
  _Milestone('Oct 14, 2026', 'Rainy evening in Kyoto', 'Shared umbrella, too many onigiri', Symbols.photo_camera, AppColors.lavender, image: DemoImages.kyoto),
  _Milestone('Sep 29, 2026', 'Big Sur sunrise coffee', 'Fog, cliffs and the best latte ever', Symbols.coffee, AppColors.primary, image: DemoImages.bigSur),
  _Milestone('Aug 12, 2026', 'First Movie Night', 'Synced playlist + our digitized ticket', Symbols.theaters, AppColors.mint, image: DemoImages.movieNight),
  _Milestone('Oct 2025', 'Our Trip to Montmartre', 'Café crèmes near Sacré-Cœur', Symbols.flight, AppColors.lavender, image: DemoImages.montmartre),
  _Milestone('Aug 23, 2025', 'The day we met', 'A spilled gelato in Rome 🍦', Symbols.favorite, AppColors.hotPink),
];

/// Shared relationship timeline.
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Our Timeline',
      subtitle: '428 days • 142 memories',
      gap: 0,
      children: [
        for (var i = 0; i < _milestones.length; i++) _TimelineRow(m: _milestones[i], last: i == _milestones.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.m, required this.last});

  final _Milestone m;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: m.color.withValues(alpha: 0.2), shape: BoxShape.circle, boxShadow: [BoxShadow(color: m.color.withValues(alpha: 0.3), blurRadius: 10)]),
                  child: Sym(m.icon, size: 15, color: m.color, fill: true),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AmourCard(
                color: m.upcoming ? AppColors.raised(0.7) : AppColors.surfaceLow,
                radius: 24,
                shadow: false,
                padding: const EdgeInsets.all(14),
                border: m.upcoming ? Border.all(color: AppColors.hotPink.withValues(alpha: 0.35)) : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(m.date, style: AppText.label.copyWith(color: m.color)),
                              if (m.upcoming) ...[const SizedBox(width: 6), const Tag(label: 'UPCOMING', color: AppColors.hotPink)],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(m.title, style: AppText.bodyStrong),
                          Text(m.detail, style: AppText.small),
                        ],
                      ),
                    ),
                    if (m.image != null) ...[
                      const SizedBox(width: 10),
                      ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox.square(dimension: 56, child: CoverImage(m.image!))),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
