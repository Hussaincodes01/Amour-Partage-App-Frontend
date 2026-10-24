import 'package:amour_partage/app/shell.dart';
import 'package:amour_partage/backend/demo/demo_backend.dart';
import 'package:amour_partage/data/couple_state.dart';
import 'package:amour_partage/features/call/call_screen.dart';
import 'package:amour_partage/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('shell switches between the four tabs', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const MainShell()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining(', Julian'), findsOneWidget);
    expect(find.text('TODAY’S QUESTION'), findsOneWidget);

    await tester.tap(find.text('Together'));
    await settle(tester);
    expect(find.text('Up next'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await settle(tester);
    expect(find.textContaining('watch party tonight'), findsOneWidget);

    await tester.tap(find.text('Memories'));
    await settle(tester);
    expect(find.textContaining('days together'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('sending a chat message adds a bubble and the demo partner replies', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const MainShell()));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Chat'));
    await settle(tester);

    final state = AppScope.read(tester.element(find.byType(MainShell)));
    final before = state.messages.length;
    await tester.enterText(find.byType(TextField).last, 'See you at 8 ❤️');
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(state.messages.length, before + 1);
    expect(find.text('See you at 8 ❤️'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(state.messages.length, before + 2);
    await finish(tester);
  });

  testWidgets('answering today’s question reveals both answers', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const MainShell()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Answer'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Quelqu’un m’a dit, on the night train');
    await tester.pump();
    await tester.tap(find.text('Lock in my answer'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('La Vie en Rose'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('post-beta features show the coming-soon pop-up', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const MainShell()));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Chat'));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Share a photo'));
    await settle(tester);
    await tester.tap(find.text('GIF'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('COMING SOON'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('COMING SOON'), findsNothing);
    await finish(tester);
  });

  testWidgets('new user: welcome → sign in → name → promise → pair → emojis → home', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(null, backend: DemoBackend()));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('A private space for the two of you'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.text('What should your partner call you?'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Private by design'), findsOneWidget);

    await tester.tap(find.text('Sounds good'));
    await settle(tester);
    expect(find.text('Pair your phones'), findsOneWidget);

    await tester.tap(find.text('I have a code'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'CA11-0E7E');
    await tester.pump();
    await tester.tap(find.text('Pair'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Compare your emojis'), findsOneWidget);

    await tester.tap(find.text('They match'));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.textContaining(', Julian'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('video call connects and opens Watch Together', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const CallScreen()));
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('Calling'), findsNothing);
    expect(find.textContaining('Encrypted · 0:0'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('More'));
    await settle(tester);
    await tester.tap(find.text('Watch together'));
    await settle(tester);
    expect(find.bySemanticsLabel('Close player'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('theme switch in Profile changes to light', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(harness(const ProfileScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('Profile'))).brightness, Brightness.dark);

    await tester.tap(find.text('Light'));
    await settle(tester);
    expect(Theme.of(tester.element(find.text('Profile'))).brightness, Brightness.light);
    await finish(tester);
  });
}
