import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import '../call/call_screen.dart';
import '../privacy/privacy_screen.dart';
import 'composer.dart';
import 'message_bubbles.dart';

/// End-to-end encrypted chat with your partner.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  int _lastCount = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The list is reversed, so offset 0 is the newest message.
  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: Motion.slow, curve: Motion.emphasized);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final insets = ShellInsets.of(context);
    final messages = state.messages;
    if (messages.length != _lastCount) {
      if (_lastCount >= 0) WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      _lastCount = messages.length;
    }
    const barHeight = 64.0;
    return Stack(
      children: [
        Positioned.fill(
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(14, 12, 14, insets.top + barHeight + 12),
            itemCount: messages.length + 1,
            itemBuilder: (context, i) {
              if (i == messages.length) return const _EncryptionNote();
              final m = messages[messages.length - 1 - i];
              final older = messages.length - 2 - i >= 0 ? messages[messages.length - 2 - i] : null;
              final newer = i > 0 ? messages[messages.length - i] : null;
              final showDay = older == null || !_sameDay(older.sentAt, m.sentAt);
              final lastInGroup = newer == null || newer.mine != m.mine || newer.sentAt.difference(m.sentAt).inMinutes > 5;
              return Column(
                key: ValueKey(m.id),
                children: [
                  if (showDay) _DayChip(date: m.sentAt),
                  Padding(
                    padding: EdgeInsets.only(top: older != null && older.mine == m.mine && !showDay ? 3 : 12),
                    child: FadePop(offsetY: 8, child: MessageRow(message: m, showMeta: lastInGroup)),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _ChatBar(height: barHeight, presence: state.presence)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, insets.bottom + 10),
            child: Composer(onSent: _scrollToEnd),
          ),
        ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ChatBar extends StatelessWidget {
  const _ChatBar({required this.height, required this.presence});

  final double height;
  final Presence presence;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final partner = state.couple?.partner;
    final top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: FrostedBox(
        opacity: 0.9,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top + 8, 8, 8),
          child: SizedBox(
            height: height - 16,
            child: Row(
              children: [
                Avatar(image: partner?.photo, name: partner?.name ?? '', size: 40, online: presence.online),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner?.name ?? 'Partner', style: AppText.headline, maxLines: 1),
                      AnimatedSwitcher(
                        duration: Motion.medium,
                        layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                        child: presence.typing
                            ? Row(
                                key: const ValueKey('typing'),
                                children: [
                                  Text('typing', style: AppText.caption.copyWith(color: c.accent)),
                                  const SizedBox(width: 6),
                                  TypingDots(color: c.accent),
                                ],
                              )
                            : _Tap(
                                key: const ValueKey('secure'),
                                onTap: () => context.pushPop(const PrivacyScreen()),
                                child: Row(
                                  children: [
                                    Sym(Symbols.lock, size: 12, color: c.success, fill: true),
                                    const SizedBox(width: 4),
                                    Text(presence.online ? 'Online · end-to-end encrypted' : 'End-to-end encrypted', style: AppText.caption.copyWith(color: c.textMuted)),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                RoundIconButton(icon: Symbols.call, color: Colors.transparent, iconColor: c.text, semanticLabel: 'Voice call', onTap: () => context.pushPop(const CallScreen(video: false), slideUp: true)),
                RoundIconButton(icon: Symbols.videocam, color: Colors.transparent, iconColor: c.text, semanticLabel: 'Video call', onTap: () => context.pushPop(const CallScreen(), slideUp: true)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal tap wrapper without the press scale (keeps the bar text steady).
class _Tap extends StatelessWidget {
  const _Tap({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.date});

  final DateTime date;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${_months[date.month - 1]} ${date.day}${date.year != now.year ? ', ${date.year}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(999)),
          child: Text(_label(), style: AppText.caption.copyWith(color: c.textMuted)),
        ),
      ),
    );
  }
}

class _EncryptionNote extends StatelessWidget {
  const _EncryptionNote();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Sym(Symbols.lock, size: 14, color: c.textFaint),
          const SizedBox(width: 6),
          Flexible(
            child: Text('Only the two of you can read these messages.', textAlign: TextAlign.center, style: AppText.caption.copyWith(color: c.textFaint)),
          ),
        ],
      ),
    );
  }
}
