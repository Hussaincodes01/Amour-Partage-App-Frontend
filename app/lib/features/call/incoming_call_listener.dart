import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/couple_state.dart';
import '../../data/models.dart';
import 'call_screen.dart';

/// Shows the incoming-call screen whenever the partner rings.
class IncomingCallListener extends StatefulWidget {
  const IncomingCallListener({super.key, required this.navigator, required this.child});

  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  String? _shownId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final call = AppScope.of(context).incomingCall;
    if (call != null && call.id != _shownId) {
      _shownId = call.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigator.currentState?.push(PopRoute<void>(builder: (_) => IncomingCallScreen(call: call), slideUp: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key, required this.call});

  final CallInfo call;

  Future<void> _answer(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final state = AppScope.read(context);
    final session = await state.backend.answerCall(call);
    if (context.mounted) await Navigator.of(context).pushReplacement(PopRoute<void>(builder: (_) => CallScreen(video: call.video, session: session)));
  }

  Future<void> _decline(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await AppScope.read(context).backend.declineCall(call);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final partner = state.couple?.partner;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF120C1C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(left: -120, top: 60, child: GlowBlob(color: Brand.pink.withValues(alpha: 0.3), size: 420)),
          Positioned(right: -140, bottom: 120, child: GlowBlob(color: Brand.violet.withValues(alpha: 0.45), size: 440)),
          Padding(
            padding: EdgeInsets.fromLTRB(24, pad.top + 80, 24, pad.bottom + 48),
            child: Column(
              children: [
                Breathing(min: 0.96, max: 1.05, child: Avatar(image: partner?.photo, name: partner?.name ?? '', size: 140, ring: true)),
                const SizedBox(height: 24),
                Text(partner?.name ?? 'Partner', style: AppText.largeTitle.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(call.video ? 'Incoming video call' : 'Incoming call', style: AppText.body.copyWith(color: Colors.white70)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Choice(icon: Symbols.call_end, label: 'Decline', color: const Color(0xFFE5394B), onTap: () => _decline(context)),
                    _Choice(icon: call.video ? Symbols.videocam : Symbols.call, label: 'Answer', color: const Color(0xFF22B573), onTap: () => _answer(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoundIconButton(icon: icon, size: 72, iconSize: 32, color: color, iconColor: Colors.white, fill: true, semanticLabel: label, onTap: onTap),
        const SizedBox(height: 8),
        Text(label, style: AppText.smallStrong.copyWith(color: Colors.white)),
      ],
    );
  }
}
