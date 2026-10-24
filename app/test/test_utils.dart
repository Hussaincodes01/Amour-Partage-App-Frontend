import 'package:amour_partage/app/app.dart';
import 'package:amour_partage/backend/backend.dart';
import 'package:amour_partage/backend/demo/demo_backend.dart';
import 'package:amour_partage/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads the real fonts so screenshots show actual text and icons.
Future<void> loadAppFonts() async {
  SharedPreferences.setMockInitialValues({});
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

/// A phone-sized surface (390 × 844 dp, like the Figma frames).
void usePhoneSurface(WidgetTester tester, {double width = 390, double height = 844, double dpr = 2}) {
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = FakeViewPadding(top: 24 * dpr, bottom: 16 * dpr);
  tester.view.viewPadding = FakeViewPadding(top: 24 * dpr, bottom: 16 * dpr);
  addTearDown(tester.view.reset);
}

/// The real app around [home], on the demo backend (paired by default).
Widget harness(Widget? home, {Backend? backend, ThemeMode mode = ThemeMode.dark}) =>
    AmourApp(backend: backend ?? DemoBackend.paired(), theme: ThemeController(mode), home: home);

/// Unmounts the tree (cancelling timers) and drains pending work.
Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

/// Lets a newly started animation run to its end. Routes and switchers start
/// animating a frame after the change, hence several pumps.
Future<void> settle(WidgetTester tester, [Duration d = const Duration(seconds: 1)]) async {
  await tester.pump();
  await tester.pump(d ~/ 2);
  await tester.pump(d ~/ 2);
}
