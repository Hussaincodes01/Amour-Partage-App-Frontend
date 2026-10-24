import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';

/// Create a memory capsule: photos + a note, sealed into the shared vault.
class NewCapsuleSheet extends StatefulWidget {
  const NewCapsuleSheet({super.key});

  @override
  State<NewCapsuleSheet> createState() => _NewCapsuleSheetState();
}

class _NewCapsuleSheetState extends State<NewCapsuleSheet> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  int _photos = 0;
  bool _biometric = true;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    try {
      final files = await ImagePicker().pickMultiImage(maxWidth: 2048, imageQuality: 88);
      if (files.isNotEmpty && mounted) setState(() => _photos += files.length);
    } on PlatformException {
      if (mounted) showLoveToast(context, 'Allow photo access in Settings', icon: Symbols.no_photography, color: AppColors.error);
    }
  }

  void _save() {
    final title = _title.text.trim().isEmpty ? 'Untitled moment' : _title.text.trim();
    AppScope.read(context).addMemory(Memory(
      title: title,
      subtitle: _note.text.trim().isEmpty ? '$_photos photos • sealed just now' : _note.text.trim(),
      date: 'Today',
      image: DemoImages.bigSur,
      tag: 'New',
    ));
    Navigator.of(context).pop();
    showEmojiBurst(context, '💌', count: 8);
    showLoveToast(context, 'Capsule sealed in your Vault', icon: Symbols.lock, color: AppColors.mint);
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.bg,
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: AppColors.outline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.hotPink.withValues(alpha: 0.5))),
      );

  @override
  Widget build(BuildContext context) {
    return AmourSheet(
      title: 'New Memory Capsule',
      subtitle: 'Encrypted on your phone before it’s saved',
      icon: Symbols.add_photo_alternate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _title, style: AppText.body, textCapitalization: TextCapitalization.sentences, decoration: _decoration('Name this memory')),
          const SizedBox(height: 10),
          TextField(controller: _note, style: AppText.body, minLines: 2, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: _decoration('A little note for future you two…')),
          const SizedBox(height: 12),
          Pressable(
            pressedScale: 0.98,
            onTap: _addPhotos,
            child: AnimatedContainer(
              duration: Motion.medium,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (_photos > 0 ? AppColors.mint : AppColors.outlineVariant).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Sym(_photos > 0 ? Symbols.check_circle : Symbols.add_photo_alternate, size: 22, color: _photos > 0 ? AppColors.mint : AppColors.primary, fill: _photos > 0),
                  const SizedBox(width: 8),
                  Text(_photos > 0 ? '$_photos photos added • add more' : 'Add photos & videos', style: AppText.bodyStrong.copyWith(color: _photos > 0 ? AppColors.mint : AppColors.primary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const IconBadge(icon: Symbols.fingerprint, color: AppColors.lavender, size: 36, iconSize: 18),
              const SizedBox(width: 12),
              Expanded(child: Text('Require biometric to open', style: AppText.bodyStrong)),
              AmourSwitch(value: _biometric, onChanged: (v) => setState(() => _biometric = v)),
            ],
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: () => showComingSoon(context, 'Time-locked capsules', icon: Symbols.lock_clock),
            child: Row(
              children: [
                const IconBadge(icon: Symbols.lock_clock, color: AppColors.primary, size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(child: Text('Unlock on a future date', style: AppText.bodyStrong)),
                const Tag(label: 'SOON', color: AppColors.lavender),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Seal capsule', leadingIcon: Symbols.lock, gradient: AppGradients.pinkViolet, onTap: _save),
        ],
      ),
    );
  }
}
