import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/fade_pop.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Scaffold for pushed screens: back button + title bar, staggered content.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.bottom,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.gap = 16,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  /// Optional pinned footer (e.g. a primary button).
  final Widget? bottom;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pad = MediaQuery.paddingOf(context);
    const bar = 56.0;
    return Scaffold(
      backgroundColor: c.bg,
      body: BackdropGroup(
        child: Stack(
          children: [
            const Positioned.fill(child: AmbientGlow()),
            ListView.builder(
              padding: padding.copyWith(top: pad.top + bar + 8, bottom: pad.bottom + (bottom != null ? 100 : 32)),
              itemCount: children.length,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : gap),
                child: FadePop.index(i, child: children[i]),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FrostedBox(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, pad.top + 6, 12, 6),
                  child: SizedBox(
                    height: bar - 12,
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Symbols.arrow_back,
                          size: 40,
                          iconSize: 22,
                          color: Colors.transparent,
                          semanticLabel: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: Text(title, style: AppText.headline, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ...actions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (bottom != null)
              Positioned(left: 20, right: 20, bottom: pad.bottom + 16, child: FadePop(delay: const Duration(milliseconds: 150), child: bottom!)),
          ],
        ),
      ),
    );
  }
}
