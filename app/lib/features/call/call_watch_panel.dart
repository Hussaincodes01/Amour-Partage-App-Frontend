import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/couple_state.dart';
import '../together/local_player.dart';
import '../together/watch_together.dart';

/// Compact synced player shown over a call.
class CallWatchPanel extends StatefulWidget {
  const CallWatchPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<CallWatchPanel> createState() => _CallWatchPanelState();
}

class _CallWatchPanelState extends State<CallWatchPanel> with SingleTickerProviderStateMixin {
  late final LocalPlayer _player = LocalPlayer.create(this);
  WatchTogether? _watch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
    if (_watch == null) {
      _watch = WatchTogether(backend: state.backend, player: _player, myId: state.account?.uid ?? 'me', queue: state.queue);
    } else {
      _watch!.queue = state.queue;
    }
  }

  @override
  void dispose() {
    _watch?.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final watch = _watch!;
    return ListenableBuilder(
      listenable: watch,
      builder: (context, _) {
        final item = watch.current;
        return AmourCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: Colors.black, child: _player.view(cover: item?.thumbnail))),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                child: Row(
                  children: [
                    Expanded(child: Text(item?.title ?? 'Queue is empty', style: AppText.smallStrong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    RoundIconButton(icon: watch.playing ? Symbols.pause : Symbols.play_arrow, size: 40, fill: true, gradient: AppGradients.pinkViolet, semanticLabel: watch.playing ? 'Pause' : 'Play', onTap: item == null ? null : watch.togglePlay),
                    RoundIconButton(icon: Symbols.skip_next, size: 40, color: Colors.transparent, iconColor: c.text, semanticLabel: 'Next', onTap: watch.next),
                    RoundIconButton(icon: Symbols.close, size: 40, color: Colors.transparent, iconColor: c.textMuted, semanticLabel: 'Close player', onTap: widget.onClose),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
