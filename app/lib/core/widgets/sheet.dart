import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'buttons.dart';

/// Bottom drawer styled like the Figma "Watch Together" sheet: frosted
/// surface, glowing gradient top edge, drag handle and header.
class AmourSheet extends StatelessWidget {
  const AmourSheet({super.key, required this.title, required this.child, this.subtitle, this.icon, this.iconColor = AppColors.hotPink, this.trailing});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 8, right: 8, bottom: bottom > 0 ? bottom : 8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xF22C2834),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: const [BoxShadow(color: AppColors.bg, blurRadius: 50, offset: Offset(0, 25), spreadRadius: -12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 4,
              child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.lavender, AppColors.primary, AppColors.hotPink]))),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: AppColors.outlineVariant.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (icon != null) ...[IconBadge(icon: icon!, color: iconColor, size: 32, iconSize: 18), const SizedBox(width: 10)],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppText.subhead),
                              if (subtitle != null) Text(subtitle!, style: AppText.small),
                            ],
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
