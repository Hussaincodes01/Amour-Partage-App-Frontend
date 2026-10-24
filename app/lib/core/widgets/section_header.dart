import 'package:flutter/widgets.dart';

import '../motion/pressable.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'symbol.dart';

/// "Together Right Now · 3 Queued" style section title row.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.trailingIcon,
    this.onTrailingTap,
    this.titleStyle = AppText.headline,
    this.badge,
    this.trailingStyle,
  });

  final String title;
  final IconData? icon;
  final String? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final TextStyle titleStyle;
  final Widget? badge;
  final TextStyle? trailingStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[Sym(icon!, size: 20, color: AppColors.primary), const SizedBox(width: 8)],
                Flexible(child: Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (badge != null) ...[const SizedBox(width: 8), badge!],
              ],
            ),
          ),
          if (trailing != null)
            Pressable(
              onTap: onTrailingTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(trailing!, style: trailingStyle ?? AppText.label.copyWith(color: AppColors.primary)),
                    if (trailingIcon != null) ...[const SizedBox(width: 2), Sym(trailingIcon!, size: 12, color: AppColors.primary)],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
