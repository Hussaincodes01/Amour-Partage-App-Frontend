import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Bottom sheet body: handle, title, optional subtitle, content.
class AmourSheet extends StatelessWidget {
  const AmourSheet({super.key, required this.title, required this.child, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(left: 8, right: 8, bottom: bottom > 0 ? bottom : 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: c.isDark ? 0.5 : 0.15), blurRadius: 40, offset: const Offset(0, 12))],
        ),
        child: DefaultTextStyle(
          style: AppText.body.copyWith(color: c.text),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.surfaceHighest, borderRadius: BorderRadius.circular(999))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppText.title),
                          if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppText.small.copyWith(color: c.textMuted))],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
