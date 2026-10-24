import 'package:amour_partage/data/couple_state.dart';
import 'package:amour_partage/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real fonts so screenshots show actual text and icons.
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('PlusJakartaSans', [
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-Italic.ttf',
    'assets/fonts/PlusJakartaSans-Medium.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
    'assets/fonts/PlusJakartaSans-ExtraBold.ttf',
  ]);
  await load('Cousine', ['assets/fonts/Cousine-Bold.ttf']);
  await load('packages/material_symbols_icons/MaterialSymbolsOutlined', ['packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf']);
}

/// A phone-sized surface (Figma frame width 390, Pixel-like 844 tall).
void usePhoneSurface(WidgetTester tester, {double width = 390, double height = 844, double dpr = 2}) {
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 16 * dpr);
  tester.view.viewPadding = FakeViewPadding(top: 24 * dpr, bottom: 16 * dpr);
  addTearDown(tester.view.reset);
}

/// Wraps [child] with the app's state + theme, like the real app.
Widget harness(Widget child, {CoupleState? state}) => AppScope(
      state: state ?? CoupleState(),
      child: MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.dark, home: child),
    );

/// Unmounts the tree (cancelling widget timers) and drains pending work.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

/// Lets a newly started animation run to its end (two frames: start + end).
Future<void> settle(WidgetTester tester, [Duration d = const Duration(seconds: 1)]) async {
  await tester.pump();
  await tester.pump(d);
}
