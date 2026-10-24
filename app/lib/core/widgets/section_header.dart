import 'package:flutter/widgets.dart';

import '../theme/app_text.dart';
import 'buttons.dart';

/// Section title with an optional accent action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 0, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.headline, maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (action != null) TextAction(label: action!, onTap: onAction),
        ],
      ),
    );
  }
}
