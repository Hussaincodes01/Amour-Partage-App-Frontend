import 'package:amour_partage/app/shell.dart';
import 'package:amour_partage/data/couple_state.dart';
import 'package:amour_partage/features/onboarding/onboarding_flow.dart';
import 'package:amour_partage/features/call/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shell switches between all five tabs', (tester) async {
    usePhoneSurface(tester);
    final state = CoupleState();
    await tester.pumpWidget(harness(const MainShell(), state: state));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Amour Partagé'), findsOneWidget);
    expect(find.text('Together Right Now'), findsOneWidget);

    await tester.tap(find.text('Lounge'));
    await tester.pump(const Duration(seconds: 1));
    expect(state.tab, 1);
    expect(find.text('Shared Queue'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pump(const Duration(seconds: 1));
    expect(state.chatUnread, isFalse);
    expect(find.textContaining('Are we still doing the YouTube'), findsOneWidget);

    await tester.tap(find.text('Vault & Map'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2.4 miles apart'), findsOneWidget);

    await tester.tap(find.text('AI Shield'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Vault Protocols'), findsOneWidget);

    await finish(tester);
  });

  testWidgets('sending a chat message adds a bubble', (tester) async {
    usePhoneSurface(tester);
    final state = CoupleState()..selectTab(2);
    await tester.pumpWidget(harness(const MainShell(), state: state));
    await tester.pump(const Duration(seconds: 1));

    final before = state.messages.length;
    await tester.enterText(find.byType(TextField).last, 'See you at 8 ❤️');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.messages.length, before + 1);
    expect(find.text('See you at 8 ❤️'), findsOneWidget);

    // Demo partner reply arrives a few seconds later.
    await tester.pump(const Duration(seconds: 4));
    expect(state.messages.length, before + 2);
    await finish(tester);
  });

  testWidgets('daily Soul Spark unlocks both answers', (tester) async {
    usePhoneSurface(tester);
    final state = CoupleState();
    await tester.pumpWidget(harness(const MainShell(), state: state));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).first, 'Quelqu’un m’a dit, on the night train');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(seconds: 1));
    expect(state.spark.myAnswer, isNotNull);
    expect(find.textContaining('La Vie en Rose'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('coming-soon features show the pop-up', (tester) async {
    usePhoneSurface(tester);
    final state = CoupleState()..selectTab(1);
    await tester.pumpWidget(harness(const MainShell(), state: state));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Spotify Dual'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('COMING SOON'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('COMING SOON'), findsNothing);
    await finish(tester);
  });

  testWidgets('onboarding walks through all four steps', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const OnboardingFlow()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('STEP 01 OF 04'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('AI Privacy Sanctuary'), findsOneWidget);

    await tester.tap(find.text('Authorize AI Privacy & Pair Devices'));
    await settle(tester);
    expect(find.text('Pair your phones'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'CA11-0E7E');
    await tester.pump();
    await tester.tap(find.text('Pair with Camille'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Compare your emojis'), findsOneWidget);

    await tester.tap(find.text('They match'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Enter Our Space'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('video call connects and opens Watch Together', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const CallScreen()));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Calling…'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Watch together'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Watch Together'), findsOneWidget);
    await finish(tester);
  });
}
