import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../backend/backend.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../data/couple_state.dart';
import '../features/call/incoming_call_listener.dart';
import '../features/onboarding/session_gate.dart';

class AmourApp extends StatefulWidget {
  const AmourApp({super.key, required this.backend, required this.theme, this.home});

  final Backend backend;
  final ThemeController theme;

  /// Overrides the first screen (tests and previews).
  final Widget? home;

  @override
  State<AmourApp> createState() => _AmourAppState();
}

class _AmourAppState extends State<AmourApp> {
  late final _state = CoupleState(widget.backend);
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void dispose() {
    _state.dispose();
    widget.backend.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: widget.theme,
      child: AppScope(
        state: _state,
        child: ListenableBuilder(
          listenable: widget.theme,
          builder: (context, _) => MaterialApp(
            title: 'Amour Partagé',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: widget.theme.mode,
            themeAnimationDuration: const Duration(milliseconds: 350),
            navigatorKey: _navigator,
            builder: (context, child) => _SystemBars(child: IncomingCallListener(navigator: _navigator, child: child!)),
            home: widget.home ?? const SessionGate(),
          ),
        ),
      ),
    );
  }
}

/// Status / navigation bar icons follow the theme.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.isDark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: icons,
      ),
      child: child,
    );
  }
}
