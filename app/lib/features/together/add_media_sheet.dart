import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import 'youtube_link.dart';

Future<void> showAddMediaSheet(BuildContext context) => showAmourSheet<void>(context, builder: (_) => const _AddMediaSheet());

/// Paste a YouTube link to add it to the shared queue.
class _AddMediaSheet extends StatefulWidget {
  const _AddMediaSheet();

  @override
  State<_AddMediaSheet> createState() => _AddMediaSheetState();
}

class _AddMediaSheetState extends State<_AddMediaSheet> {
  final _link = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _link.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _link.text = data!.text!.trim();
  }

  Future<void> _add() async {
    final text = _link.text.trim();
    if (text.contains('spotify.com')) {
      await showComingSoon(context, 'Spotify listening together', icon: Symbols.graphic_eq, detail: 'For now, paste YouTube or YouTube Music links. Synced Spotify playback comes after the beta.');
      return;
    }
    final id = youtubeVideoId(text);
    if (id == null) {
      setState(() => _error = 'That doesn’t look like a YouTube video link.');
      return;
    }
    setState(() => _busy = true);
    final state = AppScope.read(context);
    final info = await fetchYoutubeInfo(id);
    try {
      await state.backend.addToQueue(title: info?.title ?? 'YouTube video', subtitle: info?.channel ?? 'YouTube', mediaId: id);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'Added to your queue', icon: Symbols.queue_music);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourSheet(
      title: 'Add to queue',
      subtitle: 'Paste a YouTube or YouTube Music link',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(
              color: c.surfaceHigh,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _error != null ? c.danger : Colors.transparent),
            ),
            child: Row(
              children: [
                Sym(Symbols.link, size: 20, color: c.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _link,
                    autofocus: true,
                    keyboardType: TextInputType.url,
                    style: AppText.body.copyWith(color: c.text),
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(border: InputBorder.none, hintText: 'youtube.com/watch?v=…', hintStyle: AppText.body.copyWith(color: c.textFaint)),
                  ),
                ),
                TextAction(label: 'Paste', onTap: _paste),
              ],
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: AppText.small.copyWith(color: c.danger))],
          const SizedBox(height: 16),
          GradientButton(label: 'Add', icon: Symbols.add, busy: _busy, onTap: _link.text.trim().isEmpty ? null : _add),
        ],
      ),
    );
  }
}
