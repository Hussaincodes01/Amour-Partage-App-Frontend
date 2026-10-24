import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/fade_pop.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'buttons.dart';
import 'surfaces.dart';

/// Scaffold for pushed screens: frosted back bar + staggered content.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.blooms = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.gap = 16,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  /// Optional pinned footer (e.g. a primary CTA).
  final Widget? bottom;
  final bool blooms;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    const barHeight = 60.0;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackdropGroup(
        child: Stack(
          children: [
            if (blooms) ...[
              Positioned(left: -80, top: -60, child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.14), size: 300)),
              Positioned(right: -110, top: 320, child: GlowBlob(color: AppColors.violet.withValues(alpha: 0.22), size: 320)),
            ],
            ListView.builder(
              padding: padding.copyWith(top: pad.top + barHeight + 12, bottom: pad.bottom + (bottom != null ? 104 : 32)),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                sigma: 14,
                color: AppColors.ink(0.82),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, pad.top + 10, 12, 10),
                  child: SizedBox(
                    height: barHeight - 20,
                    child: Row(
                      children: [
                        RoundIconButton(
                          icon: Symbols.arrow_back,
                          size: 40,
                          iconSize: 20,
                          color: AppColors.surfaceHigh,
                          semanticLabel: 'Back',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppText.subhead, maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (subtitle != null) Text(subtitle!, style: AppText.label.copyWith(color: AppColors.primary), maxLines: 1),
                            ],
                          ),
                        ),
                        ...actions,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (bottom != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: pad.bottom + 16,
                child: FadePop(delay: const Duration(milliseconds: 200), child: bottom!),
              ),
          ],
        ),
      ),
    );
  }
}
