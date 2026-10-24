@Tags(['screenshots'])
library;

import 'package:amour_partage/app/shell.dart';
import 'package:amour_partage/backend/demo/demo_backend.dart';
import 'package:amour_partage/data/couple_state.dart';
import 'package:amour_partage/data/demo_images.dart';
import 'package:amour_partage/features/call/call_screen.dart';
import 'package:amour_partage/features/map/map_screen.dart';
import 'package:amour_partage/features/onboarding/onboarding_flow.dart';
import 'package:amour_partage/features/onboarding/welcome_screen.dart';
import 'package:amour_partage/features/privacy/privacy_screen.dart';
import 'package:amour_partage/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// Renders each screen in both themes to test/goldens/ for visual review:
/// `flutter test --run-skipped --tags screenshots --update-goldens`
void main() {
  setUpAll(loadAppFonts);

  Future<void> shoot(WidgetTester tester, String name, Widget screen, ThemeMode mode, {int tab = 0, double height = 844, Future<void> Function()? before}) async {
    usePhoneSurface(tester, height: height);
    await tester.pumpWidget(harness(screen, mode: mode));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      for (final image in DemoImages.all) {
        await precacheImage(image, context);
      }
    });
    if (tab != 0) {
      AppScope.read(tester.element(find.byType(MainShell))).selectTab(tab);
    }
    if (before != null) await before();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      // Let resized images finish decoding (real async work).
      if (i == 3) await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${mode.name}_$name.png'));
    await finish(tester);
  }

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    group(mode.name, () {
      testWidgets('home', (t) => shoot(t, '1_home', const MainShell(), mode));
      testWidgets('together', (t) => shoot(t, '2_together', const MainShell(), mode, tab: 1, height: 1000));
      testWidgets('chat', (t) => shoot(t, '3_chat', const MainShell(), mode, tab: 2));
      testWidgets('memories', (t) => shoot(t, '4_memories', const MainShell(), mode, tab: 3));
      testWidgets('map', (t) => shoot(t, '5_map', const MapScreen(), mode));
      testWidgets('call', (t) => shoot(t, '6_call', const CallScreen(), mode));
      testWidgets('profile', (t) => shoot(t, '7_profile', const ProfileScreen(), mode, height: 1100));
      testWidgets('privacy', (t) => shoot(t, '8_privacy', const PrivacyScreen(), mode, height: 1000));
      testWidgets('welcome', (t) => shoot(t, '9_welcome', const WelcomeScreen(), mode));
      testWidgets('pairing', (t) async {
        usePhoneSurface(t);
        await t.pumpWidget(harness(OnboardingFlow(onFinished: () {}), backend: DemoBackend(), mode: mode));
        await t.pump(const Duration(seconds: 1));
        await t.enterText(find.byType(TextField), 'Julian');
        await t.pump();
        await t.tap(find.text('Continue'));
        await settle(t);
        await t.tap(find.text('Sounds good'));
        await settle(t);
        for (var i = 0; i < 4; i++) {
          await t.pump(const Duration(milliseconds: 300));
        }
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/${mode.name}_10_pairing.png'));
        await finish(t);
      });
    });
  }
}
