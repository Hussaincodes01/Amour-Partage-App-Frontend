import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/segmented.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';

/// Choose how long to share your live location.
class ShareLocationSheet extends StatefulWidget {
  const ShareLocationSheet({super.key});

  @override
  State<ShareLocationSheet> createState() => _ShareLocationSheetState();
}

class _ShareLocationSheetState extends State<ShareLocationSheet> {
  Duration? _duration = const Duration(hours: 1);
  bool _approximate = false;
  bool _busy = false;

  Future<void> _start() async {
    setState(() => _busy = true);
    final state = AppScope.read(context);
    try {
      await state.backend.startSharing(duration: _duration, approximate: _approximate);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'Sharing with ${state.partnerName}', icon: Symbols.near_me);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, '$e', icon: Symbols.location_off, color: context.colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final partner = AppScope.read(context).partnerName;
    return AmourSheet(
      title: 'Share my location',
      subtitle: 'Only $partner can see it. You can stop at any time.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Segmented<Duration?>(
            value: _duration,
            onChanged: (d) => setState(() => _duration = d),
            segments: const [
              Segment(Duration(hours: 1), '1 hour'),
              Segment(Duration(hours: 8), '8 hours'),
              Segment(null, 'Until I stop'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Sym(Symbols.blur_on, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Approximate only', style: AppText.subhead),
                    Text('Shows the area, not the street', style: AppText.small.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
              AmourSwitch(value: _approximate, onChanged: (v) => setState(() => _approximate = v), semanticLabel: 'Approximate only'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Sym(Symbols.info, size: 16, color: c.textFaint),
              const SizedBox(width: 8),
              Expanded(child: Text('Your location is encrypted on this phone. A notification stays visible the whole time you share.', style: AppText.caption.copyWith(color: c.textFaint))),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Start sharing', icon: Symbols.near_me, busy: _busy, onTap: _start),
        ],
      ),
    );
  }
}
