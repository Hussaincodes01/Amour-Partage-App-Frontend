import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/waveform.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';

const _partnerRadius = BorderRadius.only(
  topLeft: Radius.circular(32),
  topRight: Radius.circular(32),
  bottomRight: Radius.circular(32),
  bottomLeft: Radius.circular(2),
);
const _myRadius = BorderRadius.only(
  topLeft: Radius.circular(32),
  topRight: Radius.circular(32),
  bottomLeft: Radius.circular(32),
  bottomRight: Radius.circular(2),
);

/// Builds the right bubble for a message, aligned to its sender.
class MessageRow extends StatelessWidget {
  const MessageRow({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.sender == Sender.me;
    final maxW = MediaQuery.sizeOf(context).width * (message.kind == MessageKind.text ? 0.78 : 0.84);
    final bubble = switch (message.kind) {
      MessageKind.text => _TextBubble(message: message),
      MessageKind.lockedMoment => LockedMomentCard(message: message),
      MessageKind.voiceNote => VoiceNoteBubble(message: message),
      MessageKind.photo => _PhotoBubble(message: message),
    };
    final content = Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        const SizedBox(height: 4),
        _Meta(message: message),
      ],
    );
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: mine
            ? content
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(padding: EdgeInsets.only(bottom: 22), child: Avatar(image: DemoImages.camille, size: 24)),
                  const SizedBox(width: 4),
                  Flexible(child: content),
                ],
              ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.sender == Sender.me;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message.time, style: AppText.label.copyWith(color: AppColors.outline)),
          if (message.footnote != null) ...[
            const SizedBox(width: 4),
            Flexible(child: Text('• ${message.footnote}', style: AppText.label.copyWith(color: AppColors.lavender), overflow: TextOverflow.ellipsis)),
          ],
          if (!mine && message.reactions > 0) ...[
            const SizedBox(width: 4),
            for (var i = 0; i < message.reactions; i++) const Sym(Symbols.favorite, size: 11, color: AppColors.primary, fill: true),
          ],
          if (mine) ...[
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: Motion.medium,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Sym(
                message.seen ? Symbols.done_all : Symbols.done,
                key: ValueKey(message.seen),
                size: 14,
                color: message.seen ? AppColors.lavender : AppColors.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.sender == Sender.me;
    return GestureDetector(
      onDoubleTap: () {
        HapticFeedback.lightImpact();
        showEmojiBurst(context, '💗', count: 5);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? null : AppColors.muted(0.85),
          gradient: mine ? AppGradients.pinkDeep : null,
          borderRadius: mine ? _myRadius : _partnerRadius,
          boxShadow: mine
              ? [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
        ),
        child: Text(message.text ?? '', style: AppText.body.copyWith(color: mine ? Colors.white : AppColors.onSurface)),
      ),
    );
  }
}

class _PhotoBubble extends StatelessWidget {
  const _PhotoBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final path = message.photoPath;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: _myRadius,
      child: SizedBox(
        width: 220,
        height: 260,
        child: path == null
            ? const CoverImage(DemoImages.kyoto)
            : Image.file(File(path), fit: BoxFit.cover, cacheWidth: (220 * dpr).round(), filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// Encrypted surprise that only unlocks with the couple's riddle answer.
class LockedMomentCard extends StatefulWidget {
  const LockedMomentCard({super.key, required this.message});

  final ChatMessage message;

  @override
  State<LockedMomentCard> createState() => _LockedMomentCardState();
}

class _LockedMomentCardState extends State<LockedMomentCard> with SingleTickerProviderStateMixin {
  final _answer = TextEditingController();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _answer.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _tryUnlock() {
    final guess = _answer.text.trim().toLowerCase();
    if (guess.isEmpty) return;
    if (guess.contains(widget.message.answer ?? '')) {
      HapticFeedback.heavyImpact();
      FocusScope.of(context).unfocus();
      AppScope.read(context).unlockMoment(widget.message.id);
      showEmojiBurst(context, '🍨', count: 8);
    } else {
      HapticFeedback.vibrate();
      _shake.forward(from: 0);
      showLoveToast(context, 'Not quite… think sunshine & Vespas', icon: Symbols.lock, color: AppColors.lavender);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = AppScope.of(context).unlockedMoments.contains(widget.message.id);
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(offset: Offset(math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value), 0), child: child),
      child: AmourCard(
        color: AppColors.raised(0.9),
        blooms: [
          Bloom(color: AppColors.primary.withValues(alpha: 0.2), size: 150, right: -40, top: -40),
          Bloom(color: AppColors.lavender.withValues(alpha: 0.15), size: 150, left: -40, bottom: -40),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.hotPink.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Sym(unlocked ? Symbols.lock_open : Symbols.lock, size: 13, color: AppColors.primary, fill: true),
                      const SizedBox(width: 6),
                      Text(unlocked ? 'UNLOCKED MOMENT' : 'LOCKED MOMENT', style: AppText.label.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('Self-destructs in 24h', style: AppText.label.copyWith(color: AppColors.lavenderFixed)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 176,
              child: ColoredBox(
                color: AppColors.bg,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Motion.emphasized,
                  transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(a), child: c)),
                  child: unlocked
                      ? const CoverImage(DemoImages.kyoto, key: ValueKey('open'))
                      : Stack(
                          key: const ValueKey('locked'),
                          fit: StackFit.expand,
                          children: [
                            // The teaser asset is pre-blurred, so no live blur pass is needed.
                            const Opacity(opacity: 0.7, child: CoverImage(DemoImages.lockedTeaser)),
                            ColoredBox(color: AppColors.ink(0.4)),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [AppColors.hotPink, AppColors.lavender]),
                                      boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.5), blurRadius: 12)],
                                    ),
                                    child: const Sym(Symbols.encrypted, size: 24, color: Colors.white, fill: true),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('ZERO-KNOWLEDGE VAULT', style: AppText.labelSemi.copyWith(color: AppColors.primaryFixed, letterSpacing: 1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.ink(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COUPLE RIDDLE CHALLENGE', style: AppText.label.copyWith(color: AppColors.primary, letterSpacing: 0.25)),
                  const SizedBox(height: 2),
                  Text(
                    unlocked ? '“Rome, by the Trevi fountain. You dropped your pistachio cone 🍦”' : '“${widget.message.riddle}”',
                    style: AppText.body.copyWith(height: 1.375),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: Motion.medium,
              curve: Motion.emphasized,
              child: unlocked
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
                              child: TextField(
                                controller: _answer,
                                style: AppText.small.copyWith(color: AppColors.onSurface),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _tryUnlock(),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: 'Type location (e.g. Rome)...',
                                  hintStyle: AppText.small.copyWith(color: AppColors.outline),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Pressable(
                            onTap: _tryUnlock,
                            haptic: PressFeedback.medium,
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: AppGradients.pinkBlush,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.35), blurRadius: 8)],
                              ),
                              child: Row(
                                children: [
                                  const Sym(Symbols.lock_open, size: 16, color: Colors.white, fill: true),
                                  const SizedBox(width: 4),
                                  Text('Unlock', style: AppText.smallBold.copyWith(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Voice note with a playable waveform and on-device transcription.
class VoiceNoteBubble extends StatefulWidget {
  const VoiceNoteBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _play = AnimationController(vsync: this, duration: widget.message.duration ?? const Duration(seconds: 12), value: 0.33);
  bool _expanded = true;

  static const _heights = <double>[12, 20, 28, 16, 32, 24, 12, 28, 20, 16, 28, 24, 12, 20, 16, 8];
  static const _colors = [
    AppColors.primary, AppColors.primary, AppColors.primary, AppColors.hotPink, AppColors.primary, AppColors.primary, AppColors.lavender, AppColors.lavender,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.message.transcript == null) _play.value = 0;
    _play.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _play.value = 0);
    });
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  String _fmt(double seconds) => '0:${seconds.floor().toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = (widget.message.duration ?? const Duration(seconds: 12)).inMilliseconds / 1000;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.raised(0.9),
        borderRadius: _myRadius,
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pressable(
                pressedScale: 0.88,
                onTap: () => setState(() => _play.isAnimating ? _play.stop() : _play.forward()),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.hotPink,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: Sym(_play.isAnimating ? Symbols.pause : Symbols.play_arrow, size: 26, color: Colors.white, fill: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _play,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 32,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Waveform(
                              heights: _heights,
                              colors: _colors,
                              progress: _play.value,
                              inactiveColor: AppColors.surfaceHighest,
                              live: _play.isAnimating,
                              maxHeight: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Text(_fmt(_play.value * total), style: AppText.label.copyWith(color: AppColors.outline)),
                            const Spacer(),
                            Text(_fmt(total), style: AppText.label.copyWith(color: AppColors.outline)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.message.transcript != null) ...[
            const SizedBox(height: 8),
            Pressable(
              pressedScale: 0.99,
              haptic: PressFeedback.selection,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppColors.ink(0.6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Sym(Symbols.auto_awesome, size: 14, color: AppColors.lavender),
                        const SizedBox(width: 4),
                        Text('Encrypted Transcription', style: AppText.label.copyWith(color: AppColors.lavender)),
                        const Spacer(),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: Motion.medium,
                          child: const Sym(Symbols.expand_more, size: 16, color: AppColors.lavender),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: Motion.medium,
                      curve: Motion.emphasized,
                      alignment: Alignment.topCenter,
                      child: _expanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(widget.message.transcript!, style: AppText.small.copyWith(fontStyle: FontStyle.italic)),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
