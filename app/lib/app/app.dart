import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/couple_state.dart';
import '../features/onboarding/splash_screen.dart';

class AmourApp extends StatefulWidget {
  const AmourApp({super.key, this.home});

  /// Overrides the first screen (used by tests and screenshots).
  final Widget? home;

  @override
  State<AmourApp> createState() => _AmourAppState();
}

class _AmourAppState extends State<AmourApp> {
  final _state = CoupleState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'Amour Partagé',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: widget.home ?? const SplashScreen(),
      ),
    );
  }
}
