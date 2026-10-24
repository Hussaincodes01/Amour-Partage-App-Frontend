import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../call/call_screen.dart';
import 'composer.dart';
import 'message_bubbles.dart';

/// AI-guarded, end-to-end encrypted chat with Camille.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scroll = ScrollController();
  int _lastCount = 0;
  Timer? _typingStop;
  Timer? _reply;

  static const _replies = ['Aww 🥹 you’re the best', 'Can’t wait!! 💞', 'Popcorn’s on me 🍿', 'Haha stop it 😂❤️', 'Counting the minutes ✨'];

  @override
  void initState() {
    super.initState();
    // Demo: Camille finishes "typing" a few seconds after you open the chat.
    _typingStop = Timer(const Duration(seconds: 6), () {
      if (mounted) AppScope.read(context).setPartnerTyping(false);
    });
  }

  @override
  void dispose() {
    _typingStop?.cancel();
    _reply?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.slow, curve: Motion.emphasized);
    });
  }

  void _simulateReply() {
    final state = AppScope.read(context);
    _reply?.cancel();
    _reply = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      state.setPartnerTyping(true);
      _reply = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        state.receivePartnerMessage(_replies[math.Random().nextInt(_replies.length)]);
        HapticFeedback.lightImpact();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final insets = ShellInsets.of(context);
    final composerBottom = insets.bottom + 8;
    if (state.messages.length != _lastCount) {
      final first = _lastCount == 0;
      _lastCount = state.messages.length;
      if (first) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      } else {
        _scrollToEnd();
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ListView.builder(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.fromLTRB(16, insets.top + 116, 16, composerBottom + 148),
            itemCount: state.messages.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return const _DateChip();
              final m = state.messages[i - 1];
              return Padding(
                key: ValueKey(m.id),
                padding: const EdgeInsets.only(top: 16),
                child: FadePop(delay: Motion.stagger * math.min(i, 6), child: MessageRow(message: m)),
              );
            },
          ),
        ),
        Positioned(
          top: insets.top + 4,
          left: 16,
          right: 16,
          child: Column(
            children: [
              const _SecurityPill(),
              const SizedBox(height: 8),
              _PartnerStrip(typing: state.partnerTyping),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: composerBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const QuickTouchStrip(),
              const SizedBox(height: 8),
              Composer(
                onSent: () {
                  _scrollToEnd();
                  _simulateReply();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(color: AppColors.muted(0.7), borderRadius: BorderRadius.circular(999)),
        child: Text('Today, October 24', style: AppText.label.copyWith(color: AppColors.outline)),
      ),
    );
  }
}

class _SecurityPill extends StatelessWidget {
  const _SecurityPill();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.98,
      onTap: () => AppScope.read(context).selectTab(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: AppColors.raised(0.9), borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            const Sym(Symbols.lock, size: 14, color: AppColors.mint, fill: true),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'AI-Guarded Channel • Zero-Knowledge E2EE • Screenshots Blocked',
                maxLines: 2,
                style: AppText.label.copyWith(letterSpacing: 0.25),
              ),
            ),
            const SizedBox(width: 6),
            const Dot(color: AppColors.mint, size: 6, glow: true),
          ],
        ),
      ),
    );
  }
}

class _PartnerStrip extends StatelessWidget {
  const _PartnerStrip({required this.typing});

  final bool typing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.ink(0.75), borderRadius: BorderRadius.circular(32)),
      child: Row(
        children: [
          const Avatar(image: DemoImages.camille, size: 28, ring: partnerRing, status: AppColors.mint, statusSize: 8),
          const SizedBox(width: 8),
          Text(Mock.partner, style: AppText.smallStrong.copyWith(color: AppColors.lavender)),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.medium,
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
              child: typing
                  ? Row(
                      key: const ValueKey('typing'),
                      children: [
                        Text('is typing', style: AppText.small),
                        const SizedBox(width: 6),
                        const TypingDots(color: AppColors.primary),
                      ],
                    )
                  : Text('online • E2EE', key: const ValueKey('online'), style: AppText.small.copyWith(color: AppColors.mint)),
            ),
          ),
          Pressable(
            onTap: () {
              HapticFeedback.heavyImpact();
              showLoveToast(context, 'Your hearts are in sync • 62 BPM', icon: Symbols.ecg_heart, color: AppColors.lavender);
            },
            child: Tag(
              label: '62 BPM',
              icon: Symbols.ecg_heart,
              iconSize: 13,
              color: AppColors.lavender,
              background: AppColors.violet.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          const SizedBox(width: 6),
          RoundIconButton(
            icon: Symbols.call,
            size: 32,
            iconSize: 16,
            color: AppColors.surfaceHigh,
            iconColor: AppColors.mint,
            fill: true,
            semanticLabel: 'Voice call',
            onTap: () => context.pushPop(const CallScreen(videoOn: false), slideUp: true),
          ),
          const SizedBox(width: 6),
          RoundIconButton(
            icon: Symbols.videocam,
            size: 32,
            iconSize: 16,
            gradient: AppGradients.pinkViolet,
            iconColor: Colors.white,
            fill: true,
            semanticLabel: 'Video call',
            onTap: () => context.pushPop(const CallScreen(), slideUp: true),
          ),
        ],
      ),
    );
  }
}
