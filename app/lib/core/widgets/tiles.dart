import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pills.dart';
import 'surfaces.dart';
import 'symbol.dart';

/// A titled card holding a list of [SettingsTile]s separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(title!.toUpperCase(), style: AppText.label.copyWith(color: c.textFaint)),
          ),
        AmourCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Padding(padding: const EdgeInsets.only(left: 60), child: Container(height: 1, color: c.border)),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings row: icon, title, optional subtitle and trailing widget.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color,
    this.soon = false,
    this.chevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Icon / title colour (e.g. danger for destructive rows).
  final Color? color;

  /// Shows a "Soon" tag (the tap opens the coming-soon pop-up).
  final bool soon;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.text;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Sym(icon, size: 22, color: color ?? c.accent),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.subhead.copyWith(color: fg)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppText.small.copyWith(color: c.textMuted)),
                  ],
                ],
              ),
            ),
            if (soon) ...[const SizedBox(width: 8), Tag(label: 'Soon', color: c.lavender)],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!]
            else if (onTap != null && chevron && !soon) ...[const SizedBox(width: 8), Sym(Symbols.chevron_right, size: 20, color: c.textFaint)],
          ],
        ),
      ),
    );
  }
}
