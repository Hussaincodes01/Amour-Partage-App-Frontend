import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
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
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../../data/models.dart';
import '../lounge/fullscreen_player.dart';
import 'soul_spark_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = ShellInsets.of(context);
    final sections = <Widget>[
      const _ConnectionHub(),
      const _PresenceCard(),
      const SoulSparkCard(),
      const _TogetherNow(),
      const _VaultHighlights(),
    ];
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, insets.top + 8, 16, insets.bottom + 24),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => FadePop.index(i, child: sections[i]),
    );
  }
}

class _ConnectionHub extends StatelessWidget {
  const _ConnectionHub();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.98,
      onTap: () => AppScope.read(context).selectTab(3),
      child: AmourCard(
        color: AppColors.raised(0.6),
        blooms: [
          Bloom(color: AppColors.hotPink.withValues(alpha: 0.22), size: 200, right: -76, top: -76),
          Bloom(color: AppColors.violet.withValues(alpha: 0.3), size: 200, left: -76, bottom: -76),
        ],
        child: Column(
          children: [
            Row(
              children: [
                const _CoupleAvatars(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${Mock.me} & ${Mock.partner}', style: AppText.title.copyWith(letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Sym(Symbols.favorite, size: 14, color: AppColors.hotPink, fill: true),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('IN LOVE FOR ${Mock.daysTogether} DAYS', style: AppText.label.copyWith(color: AppColors.primary)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const _BatteryPill(),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(color: AppColors.ink(0.4), borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  const PingDot(color: AppColors.primary, size: 8, glow: false),
                  const SizedBox(width: 12),
                  Text('2.4 miles away', style: AppText.smallStrong),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('• Heading home soon', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small),
                  ),
                  ActionPill(
                    label: 'Wave',
                    icon: Symbols.near_me,
                    iconSize: 13,
                    background: AppColors.primary.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    labelStyle: AppText.label.copyWith(color: AppColors.primary),
                    onTap: () {
                      showEmojiBurst(context, '👋', count: 5);
                      showLoveToast(context, 'Wave sent to ${Mock.partner}', icon: Symbols.waving_hand);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoupleAvatars extends StatelessWidget {
  const _CoupleAvatars();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 78,
      height: 48,
      child: Stack(
        children: [
          Positioned(left: 0, child: Avatar(image: DemoImages.julian, size: 46, status: AppColors.mint, statusSize: 12, statusBorder: AppColors.surfaceHigh)),
          Positioned(left: 30, child: Avatar(image: DemoImages.camille, size: 46, status: AppColors.hotPink, statusSize: 12, statusBorder: AppColors.surfaceHigh)),
        ],
      ),
    );
  }
}

class _BatteryPill extends StatelessWidget {
  const _BatteryPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.ink(0.7), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('C', style: AppText.label),
          const SizedBox(width: 4),
          Text('74%', style: AppText.label.copyWith(color: AppColors.mint)),
          const Sym(Symbols.bolt, size: 13, color: AppColors.mint, fill: true),
          const SizedBox(width: 6),
          const Dot(color: AppColors.outlineVariant, size: 4),
          const SizedBox(width: 6),
          Text('J', style: AppText.label),
          const SizedBox(width: 4),
          Text('88%', style: AppText.label.copyWith(color: AppColors.primary)),
          const Sym(Symbols.battery_5_bar, size: 13, color: AppColors.primary, fill: true),
        ],
      ),
    );
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard();

  @override
  Widget build(BuildContext context) {
    void send(String emoji, String message, IconData icon) {
      showEmojiBurst(context, emoji);
      showLoveToast(context, message, icon: icon);
    }

    return AmourCard(
      color: AppColors.muted(0.7),
      shadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Sym(Symbols.graphic_eq, size: 18, color: AppColors.lavender),
              const SizedBox(width: 8),
              Text("${Mock.partner.toUpperCase()}'S RESONANCE", style: AppText.label.copyWith(color: AppColors.lavender)),
              const Spacer(),
              Text('4m ago', style: AppText.small),
            ],
          ),
          const SizedBox(height: 8),
          Pressable(
            pressedScale: 0.98,
            onTap: () => AppScope.read(context).selectTab(1),
            child: Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.ink(0.5),
              child: Row(
                children: [
                  const IconBadge(icon: Symbols.headphones, color: AppColors.lavender, background: Color(0x666F00BE), size: 40, iconSize: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Listening to French Indie Pop', style: AppText.smallStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Feeling Cozy & Nostalgic ✨', style: AppText.small),
                      ],
                    ),
                  ),
                  const Sym(Symbols.chevron_right, size: 18, color: AppColors.outline),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ActionPill(
                  label: 'Send Spark',
                  icon: Symbols.favorite,
                  iconColor: AppColors.primary,
                  expand: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  onTap: () => send('💖', 'Spark sent to ${Mock.partner}', Symbols.favorite),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ActionPill(
                  label: 'Warm Hug',
                  icon: Symbols.volunteer_activism,
                  iconColor: AppColors.lavender,
                  expand: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  onTap: () => send('🤗', 'Warm hug on its way', Symbols.volunteer_activism),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ActionPill(
                  label: 'Love Chime',
                  icon: Symbols.notifications_active,
                  iconColor: AppColors.mint,
                  expand: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  onTap: () => send('🔔', '${Mock.partner}’s phone just chimed', Symbols.notifications_active),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TogetherNow extends StatelessWidget {
  const _TogetherNow();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Together Right Now',
          icon: Symbols.dynamic_feed,
          trailing: '${state.queue.length} Queued',
          onTrailingTap: () => state.selectTab(1),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 214,
          child: OverflowBox(
            maxWidth: MediaQuery.sizeOf(context).width,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _ActivityCard(
                  badge: const Tag(label: 'Live Stream', color: AppColors.mint, dot: Dot(color: AppColors.mint, size: 6), gap: 2),
                  icon: Symbols.headphones,
                  iconColor: AppColors.mint,
                  title: 'Midnight Jazz & Lo-Fi',
                  subtitle: '${Mock.partner} started listening in the Lounge 8m ago',
                  button: GradientButton(
                    label: '1-Tap Sync Audio',
                    leadingIcon: Symbols.sync,
                    iconSize: 14,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gradient: AppGradients.pinkLavender,
                    textStyle: AppText.smallStrong.copyWith(color: Colors.white),
                    onTap: () {
                      state.selectTab(1);
                      showLoveToast(context, 'Synced with ${Mock.partner}', icon: Symbols.sync, color: AppColors.mint);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _ActivityCard(
                  badge: Tag(label: 'Watch Party', background: AppColors.surfaceHighest, color: AppColors.onSurfaceVariant),
                  icon: Symbols.smart_display,
                  iconColor: AppColors.hotPink,
                  title: 'Tokyo Night Walk 4K',
                  subtitle: 'Queued on YouTube • Ready to play in sync',
                  button: _SoftButton(
                    icon: Symbols.play_circle,
                    label: 'Launch Screen',
                    onTap: () => context.pushPop(const FullscreenPlayer(title: 'Tokyo Night Walk 4K')),
                  ),
                ),
                const SizedBox(width: 8),
                _ActivityCard(
                  badge: Tag(label: 'Locked', color: AppColors.lavender, background: AppColors.violet.withValues(alpha: 0.2)),
                  icon: Symbols.lock,
                  iconColor: AppColors.lavender,
                  iconBg: AppColors.violet.withValues(alpha: 0.3),
                  title: 'Anniversary Capsule',
                  subtitle: 'Unlocks in 3 days • Contains audio memo & 4 letters',
                  button: _SoftButton(
                    icon: Symbols.schedule,
                    label: 'Unlocks Saturday',
                    muted: true,
                    onTap: () => showComingSoon(context, 'Time-locked capsules', icon: Symbols.lock_clock),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.badge,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.button,
    this.iconBg,
  });

  final Widget badge;
  final IconData icon;
  final Color iconColor;
  final Color? iconBg;
  final String title;
  final String subtitle;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10), spreadRadius: -3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: icon, color: iconColor, background: iconBg ?? iconColor.withValues(alpha: 0.18), size: 40, iconSize: 20),
              const Spacer(),
              badge,
            ],
          ),
          const Spacer(),
          Text(title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          button,
        ],
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.icon, required this.label, required this.onTap, this.muted = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.onSurfaceVariant : AppColors.onSurface;
    return ActionPill(
      label: label,
      icon: icon,
      iconColor: color,
      iconSize: 16,
      expand: true,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      background: muted ? AppColors.raised(0.6) : AppColors.surfaceHigh,
      labelStyle: AppText.smallStrong.copyWith(color: color),
      onTap: onTap,
    );
  }
}

class _VaultHighlights extends StatelessWidget {
  const _VaultHighlights();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: 'Our Vault Highlights',
          icon: Symbols.photo_library,
          trailing: 'View all (142)',
          trailingIcon: Symbols.chevron_right,
          onTrailingTap: () => AppScope.read(context).selectTab(3),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Polaroid(memory: Mock.vault[3], author: '${Mock.me}’s cam')),
            const SizedBox(width: 8),
            Expanded(child: _Polaroid(memory: Mock.vault[4], author: '${Mock.partner}’s cam')),
          ],
        ),
      ],
    );
  }
}

class _Polaroid extends StatefulWidget {
  const _Polaroid({required this.memory, required this.author});

  final Memory memory;
  final String author;

  @override
  State<_Polaroid> createState() => _PolaroidState();
}

class _PolaroidState extends State<_Polaroid> {
  bool _liked = true;

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 176,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverImage(m.image),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xD9100C18), Color(0x00100C18)],
                      stops: [0, 0.5],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Pressable(
                    onTap: () {
                      setState(() => _liked = !_liked);
                      if (_liked) showEmojiBurst(context, '💗', count: 4);
                    },
                    child: Container(
                      width: 26,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.ink(0.6), borderRadius: BorderRadius.circular(999)),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Sym(
                          Symbols.favorite,
                          key: ValueKey(_liked),
                          size: 15,
                          color: _liked ? AppColors.primary : AppColors.onSurfaceVariant,
                          fill: _liked,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: AppText.smallStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: Text('${m.date} • ${widget.author}', style: AppText.small)),
                    Text('Encrypted', style: AppText.small.copyWith(color: AppColors.mint)),
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
