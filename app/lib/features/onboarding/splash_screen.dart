import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/demo_images.dart';

/// Launch animation: the neon heart pops in and glows.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  Timer? _done;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _done = Timer(const Duration(milliseconds: 1600), widget.onDone);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Decode imagery while the splash plays so tabs open instantly.
      DemoImages.precache(context);
    }
  }

  @override
  void dispose() {
    _done?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0, 0.55, curve: Motion.pop));
    final glow = CurvedAnimation(parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeInOut));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.45, 0.9, curve: Motion.emphasized));
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(opacity: glow, child: const AmbientGlow()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.4, end: 1.0).animate(pop),
                child: FadeTransition(
                  opacity: pop,
                  child: AnimatedBuilder(animation: glow, builder: (_, _) => AmourLogo(size: 104, glow: glow.value)),
                ),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: text,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(text),
                  child: Text('Amour Partagé', style: AppText.display.copyWith(fontSize: 28)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
