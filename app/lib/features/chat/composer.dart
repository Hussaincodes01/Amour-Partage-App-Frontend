import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/waveform.dart';
import '../../data/couple_state.dart';
import '../../data/mock.dart';

/// Heartbeat · Live Touch · Whisper quick actions above the composer.
class QuickTouchStrip extends StatelessWidget {
  const QuickTouchStrip({super.key});

  Future<void> _heartbeat(BuildContext context) async {
    showEmojiBurst(context, '💓', count: 6);
    showLoveToast(context, 'Heartbeat sent to ${Mock.partner}', icon: Symbols.ecg_heart);
    for (var i = 0; i < 2; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 520));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, IconData icon, Color color, VoidCallback onTap) => Expanded(
          child: ActionPill(
            label: label,
            icon: icon,
            iconColor: color,
            iconSize: 18,
            height: 40,
            expand: true,
            background: AppColors.raised(0.9),
            onTap: onTap,
          ),
        );
    return Row(
      children: [
        Builder(builder: (c) => pill('Heartbeat', Symbols.ecg_heart, AppColors.hotPink, () => _heartbeat(c))),
        const SizedBox(width: 4),
        pill('Live Touch', Symbols.gesture, AppColors.lavender, () => showComingSoon(context, 'Live Touch drawing', icon: Symbols.gesture)),
        const SizedBox(width: 4),
        pill('Whisper', Symbols.hearing, AppColors.mint, () => showComingSoon(context, 'Whisper mode', icon: Symbols.hearing)),
      ],
    );
  }
}

/// Message composer: attach · emoji · text · camera · hold-to-record · send.
class Composer extends StatefulWidget {
  const Composer({super.key, required this.onSent});

  final VoidCallback onSent;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _picker = ImagePicker();
  bool _hasText = false;
  bool _recording = false;
  final _recordWatch = Stopwatch();
  Timer? _recordTick;

  @override
  void initState() {
    super.initState();
    _text.addListener(() {
      final has = _text.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _recordTick?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    AppScope.read(context).sendMessage(text);
    _text.clear();
    widget.onSent();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 2048, imageQuality: 88);
      if (file == null || !mounted) return;
      AppScope.read(context).sendPhoto(file.path);
      widget.onSent();
    } on PlatformException {
      if (mounted) showLoveToast(context, 'Allow photo access in Settings to share', icon: Symbols.no_photography, color: AppColors.error);
    }
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    setState(() => _recording = true);
    _recordWatch
      ..reset()
      ..start();
    _recordTick = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
  }

  void _stopRecording({bool cancel = false}) {
    _recordTick?.cancel();
    _recordWatch.stop();
    final length = _recordWatch.elapsed;
    setState(() => _recording = false);
    if (cancel || length < const Duration(milliseconds: 700)) {
      showLoveToast(context, 'Hold the mic to record a voice note', icon: Symbols.mic, color: AppColors.lavender);
      return;
    }
    HapticFeedback.lightImpact();
    AppScope.read(context).sendVoiceNote(length);
    widget.onSent();
  }

  void _openAttach() {
    showAmourSheet(
      context,
      builder: (sheetContext) => AmourSheet(
        title: 'Share with ${Mock.partner}',
        subtitle: 'Everything is encrypted before it leaves your phone',
        icon: Symbols.add_circle,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _AttachTile(icon: Symbols.photo_library, label: 'Photos', color: AppColors.hotPink, onTap: () {
              Navigator.pop(sheetContext);
              _pick(ImageSource.gallery);
            }),
            _AttachTile(icon: Symbols.photo_camera, label: 'Camera', color: AppColors.lavender, onTap: () {
              Navigator.pop(sheetContext);
              _pick(ImageSource.camera);
            }),
            _AttachTile(icon: Symbols.location_on, label: 'Location', color: AppColors.mint, onTap: () {
              Navigator.pop(sheetContext);
              AppScope.read(context).selectTab(3);
            }),
            _AttachTile(icon: Symbols.lock, label: 'Locked Moment', color: AppColors.primary, onTap: () {
              Navigator.pop(sheetContext);
              showComingSoon(context, 'Create Locked Moments', icon: Symbols.lock);
            }),
            _AttachTile(icon: Symbols.queue_music, label: 'Song', color: AppColors.mint, onTap: () {
              Navigator.pop(sheetContext);
              AppScope.read(context).selectTab(1);
            }),
            _AttachTile(icon: Symbols.gif_box, label: 'GIFs', color: AppColors.lavender, onTap: () {
              Navigator.pop(sheetContext);
              showComingSoon(context, 'GIFs & stickers', icon: Symbols.gif_box);
            }),
          ],
        ),
      ),
    );
  }

  void _openEmoji() {
    const emojis = ['❤️', '💖', '🥰', '😘', '🥹', '😂', '🔥', '✨', '🍿', '🌙', '☕', '🌹', '💋', '🫶', '😴', '🎶', '🍷', '🍝', '🌧️', '🌅'];
    showAmourSheet(
      context,
      builder: (sheetContext) => AmourSheet(
        title: 'Reactions',
        icon: Symbols.mood,
        iconColor: AppColors.lavender,
        child: GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final e in emojis)
              Pressable(
                pressedScale: 0.8,
                onTap: () {
                  _text.text += e;
                  _text.selection = TextSelection.collapsed(offset: _text.text.length);
                  Navigator.pop(sheetContext);
                },
                child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
              ),
          ],
        ),
      ),
    );
  }

  void _openOptions() {
    showAmourSheet(
      context,
      builder: (sheetContext) => AmourSheet(
        title: 'Chat options',
        icon: Symbols.tune,
        iconColor: AppColors.lavender,
        child: Column(
          children: [
            _OptionRow(icon: Symbols.photo_library, label: 'Shared photos & moments', onTap: () {
              Navigator.pop(sheetContext);
              AppScope.read(context).selectTab(3);
            }),
            _OptionRow(icon: Symbols.search, label: 'Search messages', soon: true, onTap: () => showComingSoon(context, 'Encrypted message search', icon: Symbols.search)),
            _OptionRow(icon: Symbols.timer, label: 'Disappearing messages', soon: true, onTap: () => showComingSoon(context, 'Self-destruct on read', icon: Symbols.timer)),
            _OptionRow(icon: Symbols.wallpaper, label: 'Chat theme', soon: true, onTap: () => showComingSoon(context, 'Chat themes', icon: Symbols.wallpaper)),
            _OptionRow(icon: Symbols.shield_lock, label: 'Privacy guards', onTap: () {
              Navigator.pop(sheetContext);
              AppScope.read(context).selectTab(4);
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xF22C2834),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 32, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            child: Row(
              children: [
                Pressable(
                  onTap: () => showComingSoon(context, 'Self-destruct on read', icon: Symbols.timer),
                  child: Row(
                    children: [
                      const Dot(color: AppColors.mint, size: 8),
                      const SizedBox(width: 6),
                      Text('Self-Destruct on read: Off', style: AppText.label),
                    ],
                  ),
                ),
                const Spacer(),
                Pressable(
                  onTap: _openOptions,
                  child: Row(
                    children: [
                      Text('Options', style: AppText.label.copyWith(color: AppColors.primary)),
                      const SizedBox(width: 2),
                      const Sym(Symbols.tune, size: 13, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: AnimatedSwitcher(
              duration: Motion.medium,
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c)),
              child: _recording ? _recordingRow() : _inputRow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow() {
    return Row(
      key: const ValueKey('input'),
      children: [
        RoundIconButton(icon: Symbols.add_circle, size: 40, iconSize: 22, color: Colors.transparent, iconColor: AppColors.onSurfaceVariant, semanticLabel: 'Attach', onTap: _openAttach),
        RoundIconButton(icon: Symbols.mood, size: 40, iconSize: 22, color: Colors.transparent, iconColor: AppColors.onSurfaceVariant, semanticLabel: 'Emoji', onTap: _openEmoji),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    style: AppText.body,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Encrypted note to ${Mock.partner}...',
                      hintStyle: AppText.body.copyWith(color: AppColors.outline),
                    ),
                  ),
                ),
                RoundIconButton(icon: Symbols.photo_camera, size: 36, iconSize: 20, color: Colors.transparent, iconColor: AppColors.onSurfaceVariant, semanticLabel: 'Camera', onTap: () => _pick(ImageSource.camera)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          onTap: () => showLoveToast(context, 'Hold the mic to record a voice note', icon: Symbols.mic, color: AppColors.lavender),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const Sym(Symbols.mic, size: 22, color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 6),
        Pressable(
          onTap: _hasText ? _send : null,
          pressedScale: 0.86,
          semanticLabel: 'Send',
          child: AnimatedScale(
            duration: Motion.medium,
            curve: Motion.pop,
            scale: _hasText ? 1 : 0.9,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [AppColors.hotPink, AppColors.primary]),
                boxShadow: [BoxShadow(color: AppColors.hotPink.withValues(alpha: _hasText ? 0.5 : 0.3), blurRadius: 8)],
              ),
              child: const Sym(Symbols.send, size: 20, color: Colors.white, fill: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recordingRow() {
    final secs = _recordWatch.elapsed.inSeconds;
    return Container(
      key: const ValueKey('recording'),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.hotPink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const PingDot(color: AppColors.hotPink, size: 10, period: Duration(milliseconds: 900)),
          const SizedBox(width: 10),
          Text('0:${secs.toString().padLeft(2, '0')}', style: AppText.mono.copyWith(fontSize: 13, color: AppColors.primary)),
          const SizedBox(width: 12),
          const Expanded(
            child: Waveform(
              heights: [8, 14, 20, 12, 22, 16, 10, 18, 12, 20, 14, 8],
              colors: [AppColors.primary, AppColors.hotPink, AppColors.lavender],
              barWidth: 3,
              gap: 3,
              live: true,
              maxHeight: 22,
            ),
          ),
          Text('Release to send', style: AppText.label.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBadge(icon: icon, color: color, size: 44, iconSize: 22),
            const SizedBox(height: 8),
            Text(label, style: AppText.label.copyWith(color: AppColors.onSurface), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label, required this.onTap, this.soon = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(icon: icon, color: AppColors.primary, size: 36, iconSize: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.bodyStrong)),
            if (soon) const Tag(label: 'SOON', color: AppColors.lavender) else const Sym(Symbols.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
