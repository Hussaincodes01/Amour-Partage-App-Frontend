import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/pulse.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../core/widgets/tiles.dart';
import '../../data/couple_state.dart';
import 'privacy_checkup_screen.dart';
import 'safety_emojis.dart';

class _GuardInfo {
  const _GuardInfo(this.guard, this.icon, this.title, this.subtitle);

  final Guard guard;
  final IconData icon;
  final String title;
  final String subtitle;
}

const _guards = [
  _GuardInfo(Guard.appLock, Symbols.fingerprint, 'App lock', 'Fingerprint or face after 30 s away'),
  _GuardInfo(Guard.screenshots, Symbols.screenshot_monitor, 'Block screenshots', 'Also hides the app in recent apps'),
  _GuardInfo(Guard.discreet, Symbols.notifications_off, 'Discreet notifications', 'No message text on the lock screen'),
  _GuardInfo(Guard.links, Symbols.phishing, 'Link guard', 'Warns about scam links, on this phone'),
  _GuardInfo(Guard.mediaBlur, Symbols.blur_on, 'Blur sensitive photos', 'Until you tap to see them'),
];

/// Privacy & protections: everything runs on your phones.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final all = state.activeGuards == _guards.length;
    return SubPage(
      title: 'Privacy',
      children: [
        AmourCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Breathing(
                breaths: 2,
                min: 0.95,
                max: 1.05,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: all ? AppGradients.pinkViolet : null, color: all ? null : c.surfaceHigh),
                  child: Sym(Symbols.shield, size: 28, color: all ? Colors.white : c.accent, fill: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(all ? 'You’re protected' : '${state.activeGuards} of ${_guards.length} protections on', style: AppText.headline),
                    const SizedBox(height: 4),
                    Text('Messages, photos, answers and locations are encrypted on your phones. Only the two of you can read them.', style: AppText.small.copyWith(color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SettingsGroup(
          title: 'Protections',
          children: [
            for (final g in _guards)
              SettingsTile(
                icon: g.icon,
                title: g.title,
                subtitle: g.subtitle,
                trailing: AmourSwitch(value: state.guard(g.guard), onChanged: (v) => state.setGuard(g.guard, v), semanticLabel: g.title),
              ),
            SettingsTile(icon: Symbols.visibility_off, title: 'Stealth mode', subtitle: 'Hide chats if someone looks over your shoulder', soon: true, onTap: () => showComingSoon(context, 'Stealth mode', icon: Symbols.visibility_off)),
          ],
        ),
        SettingsGroup(
          children: [
            if (state.couple != null) SettingsTile(icon: Symbols.verified_user, title: 'Safety emojis', subtitle: 'Compare them with ${state.partnerName}', onTap: () => showSafetyEmojis(context)),
            SettingsTile(icon: Symbols.checklist, title: 'Privacy check-up', subtitle: '3 quick questions', onTap: () => context.pushPop(const PrivacyCheckupScreen())),
            SettingsTile(icon: Symbols.download, title: 'Export our data', soon: true, onTap: () => showComingSoon(context, 'Data export', icon: Symbols.download)),
          ],
        ),
      ],
    );
  }
}
