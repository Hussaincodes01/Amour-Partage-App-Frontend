import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/motion/motion.dart';
import '../core/motion/pressable.dart';
import '../core/motion/routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/widgets/avatar.dart';
import '../core/widgets/pills.dart';
import '../core/widgets/surfaces.dart';
import '../core/widgets/symbol.dart';
import '../data/couple_state.dart';
import '../features/chat/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/memories/memories_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/together/together_screen.dart';

const _navHeight = 68.0;

/// Space the nav bar takes, so tab content can scroll underneath it.
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
    final c = context.colors;
    final pad = MediaQuery.paddingOf(context);
    // While typing, the nav steps aside so the focused field stays visible.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final insets = EdgeInsets.only(top: pad.top, bottom: keyboardOpen ? 0 : pad.bottom + _navHeight);
    return Scaffold(
      backgroundColor: c.bg,
      resizeToAvoidBottomInset: true,
      body: BackdropGroup(
        child: ShellInsets(
          insets: insets,
          child: Stack(
            children: [
              const Positioned.fill(child: AmbientGlow()),
              Positioned.fill(
                child: _FadeThroughTabs(
                  index: state.tab,
                  builders: const [HomeScreen.new, TogetherScreen.new, ChatScreen.new, MemoriesScreen.new],
                ),
              ),
              if (!keyboardOpen)
                Positioned(left: 0, right: 0, bottom: 0, child: _NavBar(index: state.tab, chatUnread: state.chatUnread, onSelect: state.selectTab)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps visited tabs alive; the incoming tab fades and settles in.
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
  late final _fades = [for (final c in _controllers) CurvedAnimation(parent: c, curve: Curves.easeOutCubic)];
  late final _scales = [for (final c in _controllers) Tween(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: c, curve: Motion.emphasized))];

  @override
  void didUpdateWidget(_FadeThroughTabs old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      // Only the incoming tab animates: one translucent layer per switch.
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
              // Hidden tabs pause their animations (battery, GPU).
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

/// Large tab title with the profile avatar on the right.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.largeTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppText.small.copyWith(color: c.textMuted))],
              ],
            ),
          ),
          ?trailing,
          const SizedBox(width: 8),
          Pressable(
            onTap: () => context.pushPop(const ProfileScreen()),
            semanticLabel: 'Profile and settings',
            child: Avatar(image: state.couple?.me.photo ?? state.account?.photo, name: state.myName, size: 40),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

const _items = [
  _NavItem(Symbols.favorite, 'Home'),
  _NavItem(Symbols.play_circle, 'Together'),
  _NavItem(Symbols.chat_bubble, 'Chat'),
  _NavItem(Symbols.photo_library, 'Memories'),
];

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.chatUnread, required this.onSelect});

  final int index;
  final bool chatUnread;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
      child: FrostedBox(
        opacity: 0.88,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: SizedBox(
            height: _navHeight,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(child: _NavButton(item: _items[i], selected: i == index, badge: i == 2 && chatUnread, onTap: () => onSelect(i))),
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
    final c = context.colors;
    final color = selected ? c.accent : c.textMuted;
    return Pressable(
      onTap: onTap,
      haptic: PressFeedback.selection,
      pressedScale: 0.9,
      semanticLabel: item.label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: Motion.medium,
                curve: Motion.emphasized,
                width: selected ? 56 : 40,
                height: 30,
                decoration: BoxDecoration(color: selected ? c.pink.withValues(alpha: c.isDark ? 0.2 : 0.12) : c.pink.withValues(alpha: 0), borderRadius: BorderRadius.circular(999)),
                alignment: Alignment.center,
                child: AnimatedScale(
                  duration: Motion.medium,
                  curve: Motion.pop,
                  scale: selected ? 1.06 : 1,
                  child: Sym(item.icon, size: 22, color: color, fill: selected),
                ),
              ),
              if (badge) Positioned(top: 2, right: selected ? 10 : 4, child: Dot(color: c.pink, size: 9, border: c.bg)),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.label, maxLines: 1, style: AppText.caption.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}
