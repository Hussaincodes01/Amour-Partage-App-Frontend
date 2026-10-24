import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/fade_pop.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/pills.dart';
import '../../data/models.dart';
import 'memories_screen.dart';

class MemoryDetailScreen extends StatelessWidget {
  const MemoryDetailScreen({super.key, required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: pad.bottom + 32),
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: memory.image != null
                    ? Image(image: memory.image!, fit: BoxFit.cover)
                    : const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.pinkViolet)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: FadePop(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memory.title, style: AppText.display),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Tag(label: formatDate(memory.date), icon: Symbols.calendar_today),
                          if (memory.place != null) Tag(label: memory.place!, icon: Symbols.location_on),
                          if (memory.locked) Tag(label: 'Private', icon: Symbols.lock, color: c.lavender),
                        ],
                      ),
                      if (memory.note.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(memory.note, style: AppText.body.copyWith(color: c.textMuted)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: pad.top + 8,
            left: 12,
            child: RoundIconButton(icon: Symbols.arrow_back, color: const Color(0x66000000), iconColor: Colors.white, semanticLabel: 'Back', onTap: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }
}
