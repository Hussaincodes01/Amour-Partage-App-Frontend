import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';

Future<void> showNewMemorySheet(BuildContext context) => showAmourSheet<void>(context, builder: (_) => const _NewMemorySheet());

class _NewMemorySheet extends StatefulWidget {
  const _NewMemorySheet();

  @override
  State<_NewMemorySheet> createState() => _NewMemorySheetState();
}

class _NewMemorySheetState extends State<_NewMemorySheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  String? _photo;
  bool _locked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
      if (file != null) setState(() => _photo = file.path);
    } on PlatformException {
      if (mounted) showToast(context, 'Allow photo access in Settings', icon: Symbols.no_photography, color: context.colors.danger);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).backend.addMemory(title: _title.text.trim(), note: _note.text.trim(), photoPath: _photo, locked: _locked);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'Memory saved', icon: Symbols.photo_library);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, '$e', icon: Symbols.error, color: context.colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    InputDecoration deco(String hint) => InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: AppText.body.copyWith(color: c.textFaint));
    return AmourSheet(
      title: 'New memory',
      subtitle: 'Encrypted on your phone before it’s saved',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: _pick,
            pressedScale: 0.98,
            semanticLabel: 'Choose a photo',
            child: Container(
              height: 140,
              decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: _photo != null
                  ? Image.file(File(_photo!), fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Sym(Symbols.add_photo_alternate, size: 32, color: c.accent),
                        const SizedBox(height: 6),
                        Text('Add a photo', style: AppText.smallStrong.copyWith(color: c.textMuted)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
            child: TextField(controller: _title, textCapitalization: TextCapitalization.sentences, style: AppText.body.copyWith(color: c.text), decoration: deco('Title')),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
            child: TextField(controller: _note, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, style: AppText.body.copyWith(color: c.text), decoration: deco('A few words (optional)')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Sym(Symbols.fingerprint, color: c.accent),
              const SizedBox(width: 12),
              Expanded(child: Text('Keep private (needs fingerprint)', style: AppText.subhead)),
              AmourSwitch(value: _locked, onChanged: (v) => setState(() => _locked = v), semanticLabel: 'Keep private'),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Save memory', busy: _busy, onTap: _title.text.trim().isEmpty ? null : _save),
        ],
      ),
    );
  }
}
