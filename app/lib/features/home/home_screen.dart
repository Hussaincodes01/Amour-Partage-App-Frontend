import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';
import '../call/call_screen.dart';
import '../map/map_screen.dart';
import 'spark_card.dart';

/// Home: your partner, today's question, and what you're watching together.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String greeting(DateTime now) => switch (now.hour) {
        < 5 => 'Good night',
        < 12 => 'Good morning',
        < 18 => 'Good afternoon',
        _ => 'Good evening',
      };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final insets = ShellInsets.of(context);
    final couple = state.couple;
    final children = <Widget>[
      TabHeader(
        title: '${greeting(DateTime.now())}, ${state.myName}',
        subtitle: couple == null ? null : 'You & ${couple.partner.name} · ${couple.daysTogether} days together',
      ),
      const _PartnerCard(),
      const SparkCard(),
      const _TogetherCard(),
    ];
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, insets.top, 16, insets.bottom + 24),
      itemCount: children.length,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(top: i <= 1 ? 8 : 16),
        child: FadePop.index(i, child: children[i]),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard();

  String _status(Presence p) {
    if (p.typing) return 'Typing…';
    if (p.online) return 'Online now';
    final seen = p.lastSeen;
    if (seen == null) return 'Offline';
    final ago = DateTime.now().difference(seen);
    if (ago.inMinutes < 1) return 'Seen just now';
    if (ago.inHours < 1) return 'Seen ${ago.inMinutes} min ago';
    if (ago.inDays < 1) return 'Seen ${ago.inHours} h ago';
    return 'Seen ${ago.inDays} d ago';
  }

  Future<void> _sendLove(BuildContext context) async {
    final state = AppScope.read(context);
    HapticFeedback.heavyImpact();
    showEmojiBurst(context, '💗', count: 8);
    showToast(context, 'Love sent to ${state.partnerName}');
    try {
      await state.backend.sendLove();
    } on Exception {
      // A missed nudge isn't worth an error message.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final partner = state.couple?.partner;
    final location = state.partnerLocation;
    return AmourCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Avatar(image: partner?.photo, name: partner?.name ?? '', size: 56, ring: true, online: state.presence.online),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partner?.name ?? 'Your partner', style: AppText.title),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (state.presence.online) ...[PingDot(color: c.success, size: 7), const SizedBox(width: 6)],
                        Flexible(child: Text(_status(state.presence), style: AppText.small.copyWith(color: state.presence.online ? c.success : c.textMuted))),
                      ],
                    ),
                  ],
                ),
              ),
              Pressable(
                  onTap: () => context.pushPop(const MapScreen()),
                  semanticLabel: 'Open map',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Sym(Symbols.location_on, size: 16, color: c.accent, fill: true),
                        const SizedBox(width: 4),
                        Text(location == null ? 'Map' : formatDistance(location.distanceKm), style: AppText.smallStrong),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Action(icon: Symbols.call, label: 'Call', onTap: () => context.pushPop(const CallScreen(video: false), slideUp: true)),
              _Action(icon: Symbols.videocam, label: 'Video', onTap: () => context.pushPop(const CallScreen(), slideUp: true)),
              Builder(builder: (context) => _Action(icon: Symbols.favorite, label: 'Send love', primary: true, onTap: () => _sendLove(context))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Distance in the user's likely unit (miles for the demo, km otherwise).
String formatDistance(double? km) {
  if (km == null) return 'Nearby';
  if (km < 0.2) return 'Together';
  final miles = km * 0.621371;
  return '${miles < 10 ? miles.toStringAsFixed(1) : miles.round()} mi';
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.primary = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      semanticLabel: label,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary ? null : c.surfaceHigh,
                gradient: primary ? AppGradients.pinkViolet : null,
                shape: BoxShape.circle,
              ),
              child: Sym(icon, size: 24, color: primary ? Colors.white : c.text, fill: primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: AppText.caption.copyWith(color: c.textMuted), maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _TogetherCard extends StatelessWidget {
  const _TogetherCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final item = state.nowPlaying;
    final playing = state.playback?.playing ?? false;
    return Pressable(
      onTap: () => state.selectTab(1),
      pressedScale: 0.98,
      semanticLabel: 'Open Together',
      child: AmourCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 76,
                height: 76,
                child: item?.thumbnail != null ? CoverImage(item!.thumbnail!) : const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.pinkViolet), child: Center(child: Sym(Symbols.play_arrow, color: Colors.white, size: 32))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playing ? 'PLAYING TOGETHER' : 'WATCH TOGETHER', style: AppText.label.copyWith(color: c.lavender)),
                  const SizedBox(height: 4),
                  Text(item?.title ?? 'Pick something to watch', style: AppText.subhead, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    item == null ? 'Add a YouTube video or playlist' : '${state.queue.length} in your queue',
                    style: AppText.small.copyWith(color: c.textMuted),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Sym(Symbols.chevron_right, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
