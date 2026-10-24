import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/segmented.dart';
import '../../core/widgets/sheet.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/tiles.dart';
import '../../data/couple_state.dart';
import '../memories/memories_screen.dart';
import '../privacy/privacy_screen.dart';
import '../privacy/safety_emojis.dart';
import '../questions/questions_screen.dart';
import '../questions/quiz_screen.dart';

/// Profile and settings.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on Exception catch (e) {
      if (context.mounted) showToast(context, '$e', icon: Symbols.error, color: context.colors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = AppScope.of(context);
    final theme = ThemeScope.of(context);
    final couple = state.couple;
    final backend = state.backend;
    return SubPage(
      title: 'Profile',
      children: [
        AmourCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CoupleAvatars(me: couple?.me.photo, partner: couple?.partner.photo, meName: state.myName, partnerName: state.partnerName, size: 64),
              const SizedBox(height: 12),
              Text(couple == null ? state.myName : '${state.myName} & ${state.partnerName}', style: AppText.title),
              if (couple != null) ...[
                const SizedBox(height: 2),
                Text('Together since ${formatDate(couple.since)}', style: AppText.small.copyWith(color: c.textMuted)),
              ],
            ],
          ),
        ),
        SettingsGroup(
          title: 'Appearance',
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Segmented<ThemeMode>(
                value: theme.mode,
                onChanged: theme.setMode,
                segments: const [
                  Segment(ThemeMode.system, 'Auto', icon: Symbols.brightness_auto),
                  Segment(ThemeMode.light, 'Light', icon: Symbols.light_mode),
                  Segment(ThemeMode.dark, 'Dark', icon: Symbols.dark_mode),
                ],
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Privacy',
          children: [
            SettingsTile(icon: Symbols.shield_lock, title: 'Privacy & protections', subtitle: '${state.activeGuards} of 5 on', onTap: () => context.pushPop(const PrivacyScreen())),
            if (couple != null) SettingsTile(icon: Symbols.verified_user, title: 'Safety emojis', subtitle: 'Check you’re talking to ${state.partnerName}', onTap: () => showSafetyEmojis(context)),
          ],
        ),
        SettingsGroup(
          title: 'Us',
          children: [
            SettingsTile(icon: Symbols.auto_awesome, title: 'Daily questions', onTap: () => context.pushPop(const QuestionsScreen())),
            SettingsTile(
              icon: Symbols.quiz,
              title: 'How well do you know me?',
              soon: !backend.isDemo,
              onTap: backend.isDemo ? () => context.pushPop(const QuizScreen()) : () => showComingSoon(context, 'Couple quiz', icon: Symbols.quiz),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Account',
          children: [
            SettingsTile(icon: Symbols.badge, title: state.myName, subtitle: state.account?.email, onTap: () => _editName(context)),
            SettingsTile(
              icon: Symbols.logout,
              title: 'Sign out',
              chevron: false,
              onTap: () async {
                final ok = await confirmAction(context, title: 'Sign out?', message: 'Your messages stay encrypted on the server. Sign in again to read them on this phone.', confirm: 'Sign out');
                if (ok && context.mounted) await _run(context, backend.signOut);
              },
            ),
            if (couple != null)
              SettingsTile(
                icon: Symbols.heart_broken,
                title: 'Unlink ${state.partnerName}',
                color: c.danger,
                chevron: false,
                onTap: () async {
                  final ok = await confirmAction(
                    context,
                    title: 'Unlink ${state.partnerName}?',
                    message: 'Your shared space closes for both of you. Everything is deleted from the server after 24 hours unless you pair again.',
                    confirm: 'Unlink',
                    destructive: true,
                  );
                  if (ok && context.mounted) await _run(context, backend.unlink);
                },
              ),
            SettingsTile(
              icon: Symbols.delete_forever,
              title: 'Delete my account',
              color: c.danger,
              chevron: false,
              onTap: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Delete your account?',
                  message: 'This removes your account, unlinks your partner and deletes your data. It can’t be undone.',
                  confirm: 'Delete',
                  destructive: true,
                );
                if (ok && context.mounted) await _run(context, backend.deleteAccount);
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            backend.isDemo ? 'Amour Partagé · beta 0.1 · demo mode (no server connected)' : 'Amour Partagé · beta 0.1',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: c.textFaint),
          ),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final state = AppScope.read(context);
    final name = await showAmourSheet<String>(context, builder: (_) => _NameSheet(initial: state.myName));
    if (name == null || name.isEmpty || !context.mounted) return;
    await state.backend.updateName(name);
  }
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.initial});

  final String initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AmourSheet(
      title: 'Your name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(18)),
            child: TextField(
              controller: _text,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppText.body.copyWith(color: c.text),
              decoration: const InputDecoration(border: InputBorder.none),
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Save', onTap: () => Navigator.of(context).pop(_text.text.trim())),
        ],
      ),
    );
  }
}
