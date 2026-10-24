import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/amour_switch.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/demo_images.dart';
import '../../data/mock.dart';
import '../call/call_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../questions/questions_screen.dart';
import '../vault/timeline_screen.dart';

/// Our profile, notifications and app settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _sparks = true;
  bool _calls = true;
  bool _location = true;

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Us',
      subtitle: '${Mock.me} & ${Mock.partner} • ${Mock.daysTogether} days',
      children: [
        AmourCard(
          color: AppColors.raised(0.6),
          blooms: [
            Bloom(color: AppColors.hotPink.withValues(alpha: 0.22), size: 220, right: -80, top: -80),
            Bloom(color: AppColors.violet.withValues(alpha: 0.3), size: 220, left: -80, bottom: -90),
          ],
          child: Column(
            children: [
              const SizedBox(
                width: 150,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(left: 8, child: Avatar(image: DemoImages.julian, size: 80, ring: AppGradients.avatarRing, ringWidth: 2)),
                    Positioned(right: 8, child: Avatar(image: DemoImages.camille, size: 80, ring: AppGradients.avatarRing, ringWidth: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('${Mock.me} & ${Mock.partner}', style: AppText.title),
              Text('Together since August 22, 2025', style: AppText.small),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _Stat(value: '${Mock.daysTogether}', label: 'Days')),
                  const Expanded(child: _Stat(value: '142', label: 'Memories')),
                  const Expanded(child: _Stat(value: '182', label: 'Sparks')),
                ],
              ),
            ],
          ),
        ),
        _Section(
          title: 'Our space',
          children: [
            _Row(icon: Symbols.timeline, label: 'Our timeline', onTap: () => context.pushPop(const TimelineScreen())),
            _Row(icon: Symbols.auto_awesome, label: 'Soul Sparks & quiz', onTap: () => context.pushPop(const QuestionsScreen())),
            _Row(icon: Symbols.shield_lock, label: 'AI Shield & privacy', onTap: () {
              AppScope.read(context).selectTab(4);
              Navigator.of(context).pop();
            }),
            _Row(icon: Symbols.palette, label: 'Light theme', soon: true, onTap: () => showComingSoon(context, 'Golden Hour light theme', icon: Symbols.palette)),
          ],
        ),
        _Section(
          title: 'Notifications',
          children: [
            _Toggle(icon: Symbols.favorite, label: 'Sparks, hugs & chimes', value: _sparks, onChanged: (v) => setState(() => _sparks = v)),
            _Toggle(icon: Symbols.call, label: 'Incoming calls', value: _calls, onChanged: (v) => setState(() => _calls = v)),
            _Toggle(icon: Symbols.location_on, label: 'Arrivals & “On my way”', value: _location, onChanged: (v) => setState(() => _location = v)),
          ],
        ),
        _Section(
          title: 'Beta lab',
          children: [
            _Row(icon: Symbols.ring_volume, label: 'Preview incoming call', onTap: () => context.pushPop(const IncomingCallScreen(), slideUp: true)),
            _Row(icon: Symbols.bug_report, label: 'Send beta feedback', onTap: () => showLoveToast(context, 'Thanks! Shake your phone anytime to report', icon: Symbols.bug_report, color: AppColors.lavender)),
          ],
        ),
        _Section(
          title: 'Account',
          children: [
            _Row(icon: Symbols.mail, label: 'julian@amourpartage.app', onTap: () {}),
            _Row(icon: Symbols.logout, label: 'Sign out', danger: true, onTap: () async {
              final ok = await confirmAction(context, title: 'Sign out?', message: 'Your encrypted space stays safe. You’ll need your phone’s biometrics to get back in.', confirm: 'Sign out');
              if (ok && context.mounted) context.resetTo(const WelcomeScreen());
            }),
          ],
        ),
        Center(child: Text('Amour Partagé • Beta 0.1.0', style: AppText.label.copyWith(color: AppColors.outline))),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.title.copyWith(color: AppColors.primary)),
        Text(label.toUpperCase(), style: AppText.label),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AmourCard(
      color: AppColors.surfaceLow,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: AppText.label.copyWith(color: AppColors.lavender, letterSpacing: 1)),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.soon = false, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return Pressable(
      pressedScale: 0.98,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color, size: 36, iconSize: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.bodyStrong.copyWith(color: danger ? AppColors.error : AppColors.onSurface))),
            if (soon) const Tag(label: 'SOON', color: AppColors.lavender) else const Sym(Symbols.chevron_right, size: 20, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, required this.value, required this.onChanged});

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.primary, size: 36, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppText.bodyStrong)),
          AmourSwitch(value: value, onChanged: onChanged, semanticLabel: label),
        ],
      ),
    );
  }
}
