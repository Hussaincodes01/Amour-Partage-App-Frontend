import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/motion/motion.dart';
import '../core/motion/pressable.dart';
import '../core/motion/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/avatar.dart';
import '../core/widgets/logo.dart';
import '../core/widgets/pills.dart';
import '../core/widgets/surfaces.dart';
import '../core/widgets/symbol.dart';
import '../data/couple_state.dart';
import '../data/demo_images.dart';
import '../features/chat/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lounge/lounge_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/shield/ai_shield_screen.dart';
import '../features/vault/vault_map_screen.dart';

const _headerContent = 64.0;
const _navContent = 80.0;

/// Space taken by the floating header and nav, so tab content can scroll
/// underneath them (the header/nav are frosted glass over the content).
class ShellInsets extends InheritedWidget {
  const ShellInsets({super.key, required this.insets, required super.child});

  final EdgeInsets insets;

  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellInsets>()?.insets ?? MediaQuery.paddingOf(context);

  @override
  bool updateShouldNotify(ShellInsets old) => old.insets != insets;
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    // While typing, the body shrinks above the keyboard and the nav steps aside,
    // so focused fields (chat composer, Soul Spark answer) stay visible.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final insets = EdgeInsets.only(top: pad.top + _headerContent, bottom: keyboardOpen ? 0 : pad.bottom + _navContent);
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: BackdropGroup(
        child: ShellInsets(
          insets: insets,
          child: Stack(
            children: [
              Positioned.fill(
                child: _FadeThroughTabs(
                  index: state.tab,
                  builders: const [HomeScreen.new, LoungeScreen.new, ChatScreen.new, VaultMapScreen.new, AiShieldScreen.new],
                ),
              ),
              const Positioned(top: 0, left: 0, right: 0, child: AppHeader()),
              if (!keyboardOpen)
                Positioned(left: 0, right: 0, bottom: 0, child: _NavBar(index: state.tab, chatUnread: state.chatUnread, onSelect: state.selectTab)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps every visited tab alive and cross-fades + pops between them.
class _FadeThroughTabs extends StatefulWidget {
  const _FadeThroughTabs({required this.index, required this.builders});

  final int index;
  final List<Widget Function({Key? key})> builders;

  @override
  State<_FadeThroughTabs> createState() => _FadeThroughTabsState();
}

class _FadeThroughTabsState extends State<_FadeThroughTabs> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers = List.generate(
    widget.builders.length,
    (i) => AnimationController(vsync: this, duration: Motion.medium, value: i == widget.index ? 1 : 0),
  );
  late final List<Widget?> _pages = List.filled(widget.builders.length, null);

  late final List<Animation<double>> _fades = [
    for (final c in _controllers) CurvedAnimation(parent: c, curve: Curves.easeOutCubic),
  ];
  late final List<Animation<double>> _scales = [
    for (final c in _controllers) Tween(begin: 0.975, end: 1.0).animate(CurvedAnimation(parent: c, curve: Motion.emphasized)),
  ];

  @override
  void didUpdateWidget(_FadeThroughTabs old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      // The outgoing tab is hidden at once; only the incoming tab fades, so a
      // switch costs a single translucent layer instead of two.
      _controllers[old.index].value = 0;
      if (Motion.reduced(context)) {
        _controllers[widget.index].value = 1;
      } else {
        _controllers[widget.index].forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _pages[widget.index] ??= widget.builders[widget.index]();
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < _pages.length; i++)
          if (_pages[i] != null)
            Offstage(
              offstage: i != widget.index,
              // Paused tabs stop their looping animations (saves battery/GPU).
              child: TickerMode(
                enabled: i == widget.index,
                child: FadeTransition(
                  opacity: _fades[i],
                  child: ScaleTransition(scale: _scales[i], child: RepaintBoundary(child: _pages[i])),
                ),
              ),
            ),
      ],
    );
  }
}

/// Top bar: brand + E2EE status + partner avatar.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 4))]),
      child: FrostedBox(
        sigma: 16,
        color: AppColors.ink(0.8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top + 12, 16, 14),
          child: Row(
            children: [
              const AmourLogo(size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amour Partagé', maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: AppText.title.copyWith(letterSpacing: -0.5, height: 1.2)),
                    Text('Our Space', style: AppText.label.copyWith(color: AppColors.primary, height: 1.1)),
                  ],
                ),
              ),
              Pressable(
                onTap: () => AppScope.read(context).selectTab(4),
                child: Tag(
                  label: 'E2EE',
                  color: AppColors.mint,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  dot: const Dot(color: AppColors.mint, size: 8, glow: true),
                  style: AppText.label.copyWith(letterSpacing: 0.25),
                  glow: AppColors.mint.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 8),
              Pressable(
                onTap: () => context.pushPop(const ProfileScreen()),
                semanticLabel: 'Profile and settings',
                child: SizedBox(
                  width: 35,
                  height: 35,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Avatar(image: DemoImages.camille, size: 35, ring: AppGradients.avatarRing, ringWidth: 1.5),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.hotPink,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 2),
                          ),
                          child: const Sym(Symbols.favorite, size: 7, color: Colors.white, fill: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.size);

  final IconData icon;
  final String label;
  final double size;
}

const _navItems = [
  _NavItem(Symbols.favorite, 'Home', 24),
  _NavItem(Symbols.headphones, 'Lounge', 24),
  _NavItem(Symbols.auto_awesome, 'Chat', 24),
  _NavItem(Symbols.shield, 'Vault & Map', 24),
  _NavItem(Symbols.fingerprint, 'AI Shield', 24),
];

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.chatUnread, required this.onSelect});

  final int index;
  final bool chatUnread;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.08), blurRadius: 32, offset: const Offset(0, -8))]),
      child: FrostedBox(
        sigma: 16,
        color: AppColors.ink(0.85),
        child: Padding(
          padding: EdgeInsets.only(left: 4, right: 4, bottom: bottom),
          child: SizedBox(
            height: _navContent,
            child: Row(
              children: [
                for (var i = 0; i < _navItems.length; i++)
                  Expanded(
                    child: Center(
                      child: _NavButton(item: _navItems[i], selected: i == index, badge: i == 2 && chatUnread, onTap: () => onSelect(i)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.badge, required this.onTap});

  final _NavItem item;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;
    return Pressable(
      onTap: onTap,
      haptic: PressFeedback.selection,
      pressedScale: 0.9,
      semanticLabel: item.label,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        height: 56,
        constraints: const BoxConstraints(minWidth: 56),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.hotPink.withValues(alpha: 0.2) : AppColors.hotPink.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: selected ? 0.25 : 0), blurRadius: 16)],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: Motion.medium,
                  curve: Motion.pop,
                  scale: selected ? 1.08 : 1,
                  child: Sym(item.icon, size: item.size, color: color, fill: selected),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.fast,
                    style: AppText.label.copyWith(color: color),
                    child: Text(item.label, maxLines: 1, softWrap: false),
                  ),
                ),
              ],
            ),
            if (badge)
              const Positioned(top: 6, right: 4, child: Dot(color: AppColors.hotPink, size: 8, glow: true)),
          ],
        ),
      ),
    );
  }
}
