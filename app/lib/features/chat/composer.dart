import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';

/// Message box: attach · text · hold-to-record voice / send.
class Composer extends StatefulWidget {
  const Composer({super.key, required this.onSent});

  final VoidCallback onSent;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _text = TextEditingController();
  final _picker = ImagePicker();
  bool _hasText = false;
  Timer? _typingIdle;
  bool _typingSent = false;

  // Voice notes
  AudioRecorder? _recorder;
  bool _recording = false;
  final _recordWatch = Stopwatch();
  Timer? _recordTick;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
  }

  @override
  void dispose() {
    _typingIdle?.cancel();
    _recordTick?.cancel();
    _recorder?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onText() {
    final has = _text.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    // Typing indicator: on while typing, off after 4 s idle.
    final backend = AppScope.read(context).backend;
    if (has && !_typingSent) {
      _typingSent = true;
      backend.setTyping(true);
    }
    _typingIdle?.cancel();
    _typingIdle = Timer(const Duration(seconds: 4), _stopTyping);
  }

  void _stopTyping() {
    if (!_typingSent) return;
    _typingSent = false;
    AppScope.read(context).backend.setTyping(false);
  }

  Future<void> _run(Future<void> Function() send) async {
    try {
      await send();
      widget.onSent();
    } on Exception catch (e) {
      if (mounted) showToast(context, '$e', icon: Symbols.error, color: context.colors.danger);
    }
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    _text.clear();
    _typingIdle?.cancel();
    _stopTyping();
    _run(() => AppScope.read(context).backend.sendText(text));
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 2048, imageQuality: 85);
      if (file == null || !mounted) return;
      await _run(() => AppScope.read(context).backend.sendPhoto(file.path));
    } on PlatformException {
      if (mounted) showToast(context, 'Allow photo access in Settings to share photos', icon: Symbols.no_photography, color: context.colors.danger);
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.mediumImpact();
    setState(() => _recording = true);
    _recordWatch
      ..reset()
      ..start();
    _recordTick = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        _cancelRecording();
        if (mounted) showToast(context, 'Allow the microphone to record voice notes', icon: Symbols.mic_off, color: context.colors.danger);
        return;
      }
      final dir = await getTemporaryDirectory();
      _recordPath = '${dir.path}/voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(), path: _recordPath!);
    } on Exception {
      // No recorder (tests / desktop): only the length is sent.
      _recordPath = null;
    }
  }

  void _cancelRecording() {
    _recordTick?.cancel();
    _recordWatch.stop();
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    _recordTick?.cancel();
    _recordWatch.stop();
    final length = _recordWatch.elapsed;
    setState(() => _recording = false);
    String? path;
    try {
      path = await _recorder?.stop();
    } on Exception {
      path = null;
    }
    if (!mounted) return;
    if (length < const Duration(milliseconds: 700)) {
      if (path != null) File(path).delete().ignore();
      showToast(context, 'Hold the mic to record a voice note', icon: Symbols.mic);
      return;
    }
    HapticFeedback.lightImpact();
    await _run(() => AppScope.read(context).backend.sendVoice(path ?? _recordPath ?? '', length));
  }

  void _attach() {
    showAmourSheet<void>(
      context,
      builder: (sheet) => AmourSheet(
        title: 'Share',
        child: Column(
          children: [
            _AttachRow(icon: Symbols.photo_library, label: 'Photo', onTap: () {
              Navigator.of(sheet).pop();
              _pick(ImageSource.gallery);
            }),
            _AttachRow(icon: Symbols.photo_camera, label: 'Camera', onTap: () {
              Navigator.of(sheet).pop();
              _pick(ImageSource.camera);
            }),
            _AttachRow(icon: Symbols.lock, label: 'Locked moment', soon: true, onTap: () => showComingSoon(sheet, 'Locked moments', icon: Symbols.lock, detail: 'Send a photo that only unlocks when your partner answers your question.')),
            _AttachRow(icon: Symbols.gif_box, label: 'GIF', soon: true, onTap: () => showComingSoon(sheet, 'GIFs', icon: Symbols.gif_box)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final secs = _recordWatch.elapsed.inSeconds;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: c.isDark ? 0.4 : 0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          RoundIconButton(icon: Symbols.add, onTap: _attach, size: 40, color: c.surfaceHigh, semanticLabel: 'Share a photo'),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.fast,
              child: _recording
                  ? Row(
                      key: const ValueKey('rec'),
                      children: [
                        const SizedBox(width: 6),
                        PingDot(color: c.danger, size: 8),
                        const SizedBox(width: 10),
                        Text('Recording ${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}', style: AppText.body.copyWith(color: c.text)),
                        const Spacer(),
                        Text('Release to send', style: AppText.caption.copyWith(color: c.textMuted)),
                        const SizedBox(width: 6),
                      ],
                    )
                  : TextField(
                      key: const ValueKey('text'),
                      controller: _text,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: AppText.body.copyWith(color: c.text),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Message',
                        hintStyle: AppText.body.copyWith(color: c.textFaint),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: Motion.fast,
            transitionBuilder: (child, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Motion.pop), child: child),
            child: _hasText
                ? RoundIconButton(key: const ValueKey('send'), icon: Symbols.send, onTap: _send, size: 40, iconSize: 20, gradient: AppGradients.pinkViolet, fill: true, semanticLabel: 'Send')
                : GestureDetector(
                    key: const ValueKey('mic'),
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    onTap: () => showToast(context, 'Hold the mic to record a voice note', icon: Symbols.mic),
                    child: Semantics(
                      button: true,
                      label: 'Hold to record a voice note',
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        width: _recording ? 48 : 40,
                        height: _recording ? 48 : 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _recording ? c.danger : c.surfaceHigh, shape: BoxShape.circle),
                        child: Sym(Symbols.mic, size: 22, color: _recording ? Colors.white : c.text, fill: _recording),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttachRow extends StatelessWidget {
  const _AttachRow({required this.icon, required this.label, required this.onTap, this.soon = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(icon: icon, size: 40),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.subhead)),
            if (soon) Text('Soon', style: AppText.caption.copyWith(color: c.lavender, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
