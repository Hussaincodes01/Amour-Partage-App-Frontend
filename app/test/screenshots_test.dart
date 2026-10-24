@Tags(['screenshots'])
library;

import 'package:amour_partage/app/shell.dart';
import 'package:amour_partage/data/couple_state.dart';
import 'package:amour_partage/data/demo_images.dart';
import 'package:amour_partage/features/call/call_screen.dart';
import 'package:amour_partage/features/onboarding/onboarding_flow.dart';
import 'package:amour_partage/features/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

/// Renders each screen at the Figma frame width (390) for visual review.
void main() {
  setUpAll(loadAppFonts);

  Future<void> shoot(WidgetTester tester, String name, Widget screen, {double height = 844, double width = 390, Future<void> Function()? before}) async {
    usePhoneSurface(tester, width: width, height: height);
    await tester.pumpWidget(harness(screen, state: _state));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      for (final image in DemoImages.all) {
        await precacheImage(image, context);
      }
    });
    if (before != null) await before();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    await finish(tester);
  }

  testWidgets('home', (t) async {
    _state = CoupleState();
    await shoot(t, '1_home', const MainShell(), height: 1500);
  });
  testWidgets('lounge', (t) async {
    _state = CoupleState()..selectTab(1);
    await shoot(t, '2_lounge', const MainShell(), height: 1560);
  });
  testWidgets('onboarding sanctuary', (t) async {
    _state = CoupleState();
    await shoot(t, '3_onboarding_sanctuary', const OnboardingFlow(), height: 1300, before: () async {
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.text('Continue'));
      await settle(t);
    });
  });
  testWidgets('chat', (t) async {
    _state = CoupleState()..selectTab(2);
    await shoot(t, '4_chat', const MainShell(), height: 1560);
  });
  testWidgets('call watch', (t) async {
    _state = CoupleState();
    await shoot(t, '5_call_watch', const CallScreen(connected: true, openWatch: true));
  });
  testWidgets('call', (t) async {
    _state = CoupleState();
    await shoot(t, '6_call', const CallScreen(connected: true));
  });
  testWidgets('vault map', (t) async {
    _state = CoupleState()..selectTab(3);
    await shoot(t, '7_vault_map', const MainShell(), height: 1840);
  });
  testWidgets('ai shield', (t) async {
    _state = CoupleState()..selectTab(4);
    await shoot(t, '8_ai_shield', const MainShell(), height: 1500);
  });
  testWidgets('welcome', (t) async {
    _state = CoupleState();
    await shoot(t, '9_welcome', const WelcomeScreen());
  });
  testWidgets('home small phone', (t) async {
    _state = CoupleState();
    await shoot(t, '10_home_360', const MainShell(), width: 360, height: 1520);
  });
}

CoupleState _state = CoupleState();
