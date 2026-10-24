import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/waveform.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';

String formatTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

/// One message, aligned left (partner) or right (me), with time + status.
class MessageRow extends StatelessWidget {
  const MessageRow({super.key, required this.message, this.showMeta = true});

  final ChatMessage message;
  final bool showMeta;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = message;
    final bubble = switch (m.kind) {
      MessageKind.text => _TextBubble(message: m),
      MessageKind.photo => _PhotoBubble(message: m),
      MessageKind.voice => _VoiceBubble(message: m),
      MessageKind.lockedMoment => _LockedBubble(message: m),
    };
    return Column(
      crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onDoubleTap: () {
            HapticFeedback.lightImpact();
            AppScope.read(context).backend.heartMessage(m.id);
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                bubble,
                if (m.hearts > 0)
                  Positioned(
                    bottom: -10,
                    left: m.mine ? -6 : null,
                    right: m.mine ? null : -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.border)),
                      child: const Text('❤️', style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showMeta)
          Padding(
            padding: EdgeInsets.only(top: m.hearts > 0 ? 14 : 4, left: 6, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatTime(m.sentAt), style: AppText.caption.copyWith(color: c.textFaint, fontSize: 11)),
                if (m.mine) ...[
                  const SizedBox(width: 4),
                  Sym(
                    switch (m.status) {
                      MessageStatus.sending => Symbols.schedule,
                      MessageStatus.sent => Symbols.check,
                      MessageStatus.read => Symbols.done_all,
                      MessageStatus.failed => Symbols.error,
                    },
                    size: 14,
                    color: m.status == MessageStatus.read ? c.accent : (m.status == MessageStatus.failed ? c.danger : c.textFaint),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

BorderRadius _radius(bool mine) => BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );

class _TextBubble extends StatelessWidget {
  const _TextBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = message.mine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: mine ? c.bubbleMine : c.bubblePartner, borderRadius: _radius(mine)),
      child: Text(message.text ?? '', style: AppText.body.copyWith(color: mine ? Colors.white : c.text)),
    );
  }
}

class _PhotoBubble extends StatelessWidget {
  const _PhotoBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final image = message.image;
    return Pressable(
      pressedScale: 0.98,
      onTap: image == null ? null : () => context.pushPop(_PhotoViewer(image: image)),
      child: ClipRRect(
        borderRadius: _radius(message.mine),
        child: SizedBox(
          width: 220,
          height: 260,
          child: image == null
              ? ColoredBox(color: context.colors.surfaceHigh)
              : Image(image: image, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => ColoredBox(color: context.colors.surfaceHigh)),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: InteractiveViewer(child: Center(child: Image(image: image, fit: BoxFit.contain)))),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 8,
            child: RoundIconButton(icon: Symbols.close, color: const Color(0x66000000), iconColor: Colors.white, semanticLabel: 'Close', onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }
}

class _VoiceBubble extends StatefulWidget {
  const _VoiceBubble({required this.message});

  final ChatMessage message;

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> with SingleTickerProviderStateMixin {
  static const _bars = <double>[8, 14, 20, 12, 24, 16, 10, 22, 18, 12, 26, 14, 8, 18, 22, 12, 16, 10, 20, 14, 8, 12];
  late final AnimationController _progress = AnimationController(vsync: this, duration: widget.message.duration ?? const Duration(seconds: 10));
  AudioPlayer? _player;
  StreamSubscription<Duration>? _posSub;
  bool _loading = false;

  @override
  void dispose() {
    _posSub?.cancel();
    _player?.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final load = widget.message.audio;
    if (load == null) {
      // Demo: simulate playback.
      _progress.isAnimating ? _progress.stop() : _progress.forward(from: _progress.value >= 1 ? 0 : _progress.value);
      setState(() {});
      return;
    }
    final player = _player;
    if (player != null) {
      player.playing ? await player.pause() : await player.play();
      if (mounted) setState(() {});
      return;
    }
    setState(() => _loading = true);
    try {
      final path = await load();
      if (path == null || !mounted) return;
      final p = AudioPlayer();
      await p.setFilePath(path);
      final total = p.duration ?? widget.message.duration ?? const Duration(seconds: 1);
      _posSub = p.positionStream.listen((pos) => _progress.value = (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0));
      p.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          p.pause();
          p.seek(Duration.zero);
        }
        if (mounted) setState(() {});
      });
      _player = p;
      await p.play();
    } on Exception {
      if (mounted) showToast(context, 'Couldn’t play this voice note', icon: Symbols.error, color: context.colors.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mine = widget.message.mine;
    final playing = _player?.playing ?? _progress.isAnimating;
    final fg = mine ? Colors.white : c.text;
    final length = widget.message.duration ?? Duration.zero;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
      decoration: BoxDecoration(color: mine ? c.bubbleMine : c.bubblePartner, borderRadius: _radius(mine)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundIconButton(
            icon: _loading ? Symbols.hourglass_empty : (playing ? Symbols.pause : Symbols.play_arrow),
            onTap: _toggle,
            size: 38,
            iconSize: 22,
            fill: true,
            color: mine ? Colors.white.withValues(alpha: 0.22) : c.pink,
            iconColor: Colors.white,
            semanticLabel: playing ? 'Pause voice note' : 'Play voice note',
          ),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _progress,
            builder: (context, _) => Waveform(
              heights: _bars,
              colors: [fg],
              barWidth: 3,
              gap: 2.5,
              maxHeight: 26,
              progress: _progress.value == 0 && !playing ? null : _progress.value,
              inactiveColor: fg.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 10),
          Text('${length.inMinutes}:${(length.inSeconds % 60).toString().padLeft(2, '0')}', style: AppText.caption.copyWith(color: fg.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// A photo sealed behind a question only the partner can answer.
class _LockedBubble extends StatelessWidget {
  const _LockedBubble({required this.message});

  final ChatMessage message;

  Future<void> _unlock(BuildContext context) async {
    final ok = await showAmourSheet<bool>(context, builder: (_) => _UnlockSheet(message: message));
    if (ok == true && context.mounted) {
      AppScope.read(context).unlockMoment(message.id);
      HapticFeedback.mediumImpact();
      showEmojiBurst(context, '🔓', count: 6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unlocked = AppScope.of(context).unlockedMoments.contains(message.id);
    return Container(
      width: 240,
      decoration: BoxDecoration(color: c.bubblePartner, borderRadius: _radius(message.mine)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (message.image != null)
                  AnimatedSwitcher(
                    duration: Motion.slow,
                    child: unlocked
                        ? Image(key: const ValueKey('open'), image: message.image!, fit: BoxFit.cover)
                        : ImageFiltered(
                            key: const ValueKey('locked'),
                            imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Image(image: message.image!, fit: BoxFit.cover),
                          ),
                  ),
                if (!unlocked)
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.pinkViolet),
                      child: const Sym(Symbols.lock, color: Colors.white, fill: true),
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
                Text(unlocked ? 'Unlocked 💞' : 'Locked moment', style: AppText.caption.copyWith(color: c.accent, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(message.riddle ?? '', style: AppText.smallStrong),
                if (!unlocked) ...[
                  const SizedBox(height: 10),
                  TonalButton(label: 'Answer to unlock', icon: Symbols.key, height: 40, onTap: () => _unlock(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockSheet extends StatefulWidget {
  const _UnlockSheet({required this.message});

  final ChatMessage message;

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  final _text = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _check() {
    final answer = _text.text.trim().toLowerCase();
    if (answer.isNotEmpty && answer.contains(widget.message.answer ?? '\u0000')) {
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _wrong = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourSheet(
      title: 'Locked moment',
      subtitle: widget.message.riddle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18), border: Border.all(color: _wrong ? c.danger : Colors.transparent)),
            child: TextField(
              controller: _text,
              autofocus: true,
              onChanged: (_) => setState(() => _wrong = false),
              onSubmitted: (_) => _check(),
              style: AppText.body.copyWith(color: c.text),
              decoration: InputDecoration(border: InputBorder.none, hintText: 'Your answer', hintStyle: AppText.body.copyWith(color: c.textFaint)),
            ),
          ),
          if (_wrong) ...[const SizedBox(height: 8), Text('Not quite. Try again 💭', style: AppText.small.copyWith(color: c.danger))],
          const SizedBox(height: 16),
          GradientButton(label: 'Unlock', icon: Symbols.lock_open, onTap: _check),
        ],
      ),
    );
  }
}
