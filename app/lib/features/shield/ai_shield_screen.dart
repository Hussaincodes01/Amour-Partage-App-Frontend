import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/shell.dart';
import '../../core/motion/fade_pop.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/routes.dart';
import '../../core/security/biometric.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/surfaces.dart';
import '../../core/widgets/symbol.dart';
import '../../data/couple_state.dart';
import '../../data/mock.dart';
import 'privacy_checkup_screen.dart';
import 'shield_widgets.dart';

/// AI Shield — the couple's privacy center.
class AiShieldScreen extends StatelessWidget {
  const AiShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final insets = ShellInsets.of(context);
    final sections = <Widget>[
      const _ShieldHero(),
      const _GuardsCard(),
      const MutualKeyCard(),
      const _CheckupCard(),
      const _DataCard(),
    ];
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, insets.top + 8, 16, insets.bottom + 24),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) => FadePop.index(i, child: sections[i]),
    );
  }
}

class _ShieldHero extends StatelessWidget {
  const _ShieldHero();

  @override
  Widget build(BuildContext context) {
    final active = AppScope.of(context).activeGuards;
    return AmourCard(
      color: AppColors.surfaceLow,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      blooms: [
        Bloom(color: AppColors.hotPink.withValues(alpha: 0.18), size: 260, left: -90, top: -110),
        Bloom(color: AppColors.violet.withValues(alpha: 0.28), size: 260, right: -110, bottom: -120),
      ],
      child: Column(
        children: [
          const PulsingShield(),
          const SizedBox(height: 16),
          Tag(
            label: 'ZERO-KNOWLEDGE COUPLE VAULT',
            dot: const Dot(color: AppColors.mint, size: 8, glow: true),
            color: AppColors.onSurfaceVariant,
            background: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            style: AppText.label.copyWith(letterSpacing: 1),
            gap: 2,
          ),
          const SizedBox(height: 10),
          Text('AI Shield', style: AppText.display),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: Motion.medium,
            child: Text(
              '$active of 5 guards active',
              key: ValueKey(active),
              style: AppText.smallBold.copyWith(color: active == 5 ? AppColors.mint : AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Everything you share is encrypted on your phones. Our AI runs on-device, so it protects you without ever reading your messages.',
            textAlign: TextAlign.center,
            style: AppText.small.copyWith(color: AppColors.outline, height: 1.6),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Stat(icon: Symbols.chat, label: 'Messages', value: 'E2EE')),
              SizedBox(width: 8),
              Expanded(child: _Stat(icon: Symbols.location_on, label: 'Location', value: 'Encrypted')),
              SizedBox(width: 8),
              Expanded(child: _Stat(icon: Symbols.screenshot_monitor, label: 'Screens', value: 'Shielded')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppColors.ink(0.6), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Sym(icon, size: 18, color: AppColors.mint, fill: true),
          const SizedBox(height: 4),
          Text(value, style: AppText.smallBold.copyWith(color: AppColors.mint)),
          Text(label, style: AppText.label),
        ],
      ),
    );
  }
}

class _GuardsCard extends StatelessWidget {
  const _GuardsCard();

  Future<void> _toggleBiometric(BuildContext context) async {
    final state = AppScope.read(context);
    if (!state.biometricLock) {
      final result = await Biometric.unlock('Confirm it’s you to turn on Biometric Couple Lock');
      if (!context.mounted) return;
      if (result == BiometricResult.failed) return;
      if (result == BiometricResult.unavailable) {
        showLoveToast(context, 'Add a fingerprint or face unlock in Android settings', icon: Symbols.fingerprint, color: AppColors.lavender);
      }
    }
    state.toggle('biometric');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AmourCard(
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Sym(Symbols.enhanced_encryption, size: 20, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(child: Text('Vault Protocols', style: AppText.headline)),
              Tag(label: 'E2EE Active', color: AppColors.mint, background: AppColors.mintDeep.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 12),
          GuardRow(
            icon: Symbols.fingerprint,
            title: 'Biometric Couple Lock',
            subtitle: 'Fingerprint or face to open the app & secret albums',
            value: state.biometricLock,
            onChanged: (_) => _toggleBiometric(context),
          ),
          GuardRow(
            icon: Symbols.screenshot_monitor,
            title: 'Screenshot Shield',
            subtitle: 'Blocks screenshots & screen recording',
            value: state.screenshotShield,
            onChanged: (_) => state.toggle('screenshot'),
          ),
          GuardRow(
            icon: Symbols.phishing,
            title: 'Link & Scam Guard',
            subtitle: 'On-device AI flags phishing links in chat',
            value: state.linkGuard,
            onChanged: (_) => state.toggle('link'),
          ),
          GuardRow(
            icon: Symbols.blur_on,
            title: 'Sensitive Media Blur',
            subtitle: 'Intimate photos stay blurred until tapped',
            value: state.mediaBlur,
            onChanged: (_) => state.toggle('media'),
          ),
          GuardRow(
            icon: Symbols.notifications_off,
            title: 'Discreet Notifications',
            subtitle: 'Hides message text on the lock screen',
            value: state.discreetNotifications,
            onChanged: (_) => state.toggle('discreet'),
          ),
          GuardRow(
            icon: Symbols.visibility_off,
            title: 'Anti-Snoop Stealth Mode',
            subtitle: 'Auto-blurs if an unfamiliar face peers over',
            value: false,
            soon: true,
            onChanged: (_) => showComingSoon(
              context,
              'Anti-Snoop Stealth Mode',
              icon: Symbols.visibility_off,
              detail: 'On-device face detection that blurs the screen when someone else looks over your shoulder. Arriving after beta hardening.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckupCard extends StatelessWidget {
  const _CheckupCard();

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.98,
      onTap: () => context.pushPop(const PrivacyCheckupScreen()),
      child: AmourCard(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1640), AppColors.surfaceLow]),
        blooms: [Bloom(color: AppColors.hotPink.withValues(alpha: 0.2), size: 180, right: -60, top: -60)],
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topRight, colors: [AppColors.violet, AppColors.hotPink]),
                boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.4), blurRadius: 12)],
              ),
              child: const Sym(Symbols.psychology, size: 24, color: Colors.white, fill: true),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AMOUR AI • 2-MIN CHECK-UP', style: AppText.label.copyWith(color: AppColors.lavender)),
                  const SizedBox(height: 2),
                  Text('How private is our space?', style: AppText.headline),
                  Text('A playful quiz that tunes your guards', style: AppText.small),
                ],
              ),
            ),
            const Sym(Symbols.chevron_right, size: 24, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard();

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String label, Color color, VoidCallback onTap, {bool soon = false}) => Pressable(
          pressedScale: 0.98,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                IconBadge(icon: icon, color: color, size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: AppText.bodyStrong.copyWith(color: color == AppColors.error ? AppColors.error : AppColors.onSurface))),
                if (soon) const Tag(label: 'SOON', color: AppColors.lavender) else Sym(Symbols.chevron_right, size: 20, color: AppColors.outline),
              ],
            ),
          ),
        );
    return AmourCard(
      color: AppColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your data', style: AppText.headline),
          const SizedBox(height: 4),
          row(Symbols.download, 'Export our data', AppColors.mint, () => showComingSoon(context, 'Encrypted data export', icon: Symbols.download), soon: true),
          row(Symbols.devices, 'Devices & sessions', AppColors.lavender, () => showLoveToast(context, '2 devices • both verified', icon: Symbols.devices, color: AppColors.mint)),
          row(Symbols.link_off, 'Unlink from ${Mock.partner}', AppColors.error, () async {
            final ok = await confirmAction(
              context,
              title: 'Unlink your space?',
              message: 'Shared chats, memories and keys are wiped from our servers for both of you. You have 24 hours to undo.',
              confirm: 'Unlink',
              destructive: true,
            );
            if (ok && context.mounted) showLoveToast(context, 'Unlink scheduled • undo within 24h', icon: Symbols.link_off, color: AppColors.error);
          }),
        ],
      ),
    );
  }
}
