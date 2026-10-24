import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/security/biometric.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/models.dart';
import 'memory_detail_screen.dart';
import 'new_memory_sheet.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// Next round-number milestone after [days].
int nextMilestone(int days) {
  for (final m in const [100, 200, 365, 500, 730, 1000, 1500, 2000]) {
    if (days < m) return m;
  }
  return ((days ~/ 1000) + 1) * 1000;
}

/// Your shared memories, newest first. Locked ones need biometrics.
class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  Future<void> _open(BuildContext context, Memory memory) async {
    final state = AppScope.read(context);
    if (memory.locked && !state.vaultUnlocked) {
      final result = await Biometric.unlock('Unlock your private memories');
      if (!context.mounted) return;
      if (result == BiometricResult.failed) {
        showToast(context, 'Not unlocked', icon: Symbols.lock, color: context.colors.danger);
        return;
      }
      state.setVaultUnlocked(true);
    }
    if (context.mounted) await context.pushPop(MemoryDetailScreen(memory: memory));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final insets = ShellInsets.of(context);
    final days = state.couple?.daysTogether ?? 0;
    final memories = state.memories;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, insets.top + 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    const FadePop(child: TabHeader(title: 'Memories')),
                    const SizedBox(height: 8),
                    FadePop(delay: const Duration(milliseconds: 60), child: _Milestone(days: days)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (memories.isEmpty)
              const SliverToBoxAdapter(child: _Empty())
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, insets.bottom + 96),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78),
                  itemCount: memories.length,
                  itemBuilder: (context, i) => FadePop.index(
                    i + 2,
                    child: _MemoryTile(memory: memories[i], hidden: memories[i].locked && !state.vaultUnlocked, onTap: () => _open(context, memories[i])),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: insets.bottom + 16,
          child: FadePop(
            delay: const Duration(milliseconds: 200),
            child: GradientButton(label: 'New memory', icon: Symbols.add, expand: false, height: 48, onTap: () => showNewMemorySheet(context)),
          ),
        ),
      ],
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final next = nextMilestone(days);
    final previous = switch (next) { 100 => 0, 200 => 100, 365 => 200, 500 => 365, 730 => 500, 1000 => 730, 1500 => 1000, 2000 => 1500, _ => next - 1000 };
    final f = ((days - previous) / (next - previous)).clamp(0.0, 1.0);
    return AmourCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(icon: Symbols.celebration, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$days days together', style: AppText.subhead),
                const SizedBox(height: 2),
                Text('${next - days} days until $next', style: AppText.small.copyWith(color: c.textMuted)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 5,
                    child: Stack(
                      children: [
                        Container(color: c.surfaceHighest),
                        FractionallySizedBox(widthFactor: f, child: Container(decoration: const BoxDecoration(gradient: AppGradients.pinkLilac))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory, required this.hidden, required this.onTap});

  final Memory memory;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget image = memory.image != null ? CoverImage(memory.image!) : const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.pinkViolet));
    if (hidden) image = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: image);
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticLabel: memory.title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.45, 1], colors: [Color(0x00000000), Color(0xB3000000)]),
              ),
            ),
            if (hidden)
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                  child: const Sym(Symbols.lock, color: Colors.white, fill: true),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hidden ? 'Private memory' : memory.title, style: AppText.subhead.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(formatDate(memory.date), style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border))))),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          Sym(Symbols.photo_library, size: 40, color: c.accent),
          const SizedBox(height: 10),
          Text('Your first memory', style: AppText.headline),
          const SizedBox(height: 4),
          Text('Save photos and notes only the two of you can see.', textAlign: TextAlign.center, style: AppText.small.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}
