import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/logo.dart';
import '../../core/widgets/surfaces.dart';
import '../../data/demo_images.dart';
import 'welcome_screen.dart';

/// Animated launch: the neon heart pops in and glows, then the welcome flow.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    Timer(const Duration(milliseconds: 1900), _next);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Decode demo imagery while the splash plays so tabs open instantly.
      DemoImages.precache(context);
    }
  }

  void _next() {
    if (mounted) context.replaceWithPop(const WelcomeScreen());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0, 0.55, curve: Motion.pop));
    final glow = CurvedAnimation(parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeInOut));
    final text = CurvedAnimation(parent: _c, curve: const Interval(0.45, 0.9, curve: Motion.emphasized));
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: glow,
            builder: (context, _) => Opacity(
              opacity: glow.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(offset: const Offset(-60, -80), child: GlowBlob(color: AppColors.hotPink.withValues(alpha: 0.28), size: 340)),
                  Transform.translate(offset: const Offset(80, 90), child: GlowBlob(color: AppColors.violet.withValues(alpha: 0.38), size: 360)),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.4, end: 1.0).animate(pop),
                child: FadeTransition(
                  opacity: pop,
                  child: AnimatedBuilder(animation: glow, builder: (_, _) => AmourLogo(size: 112, glow: glow.value)),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: text,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(text),
                  child: Column(
                    children: [
                      Text('Amour Partagé', style: AppText.display.copyWith(fontSize: 30, height: 1.2, letterSpacing: -0.8)),
                      const SizedBox(height: 6),
                      Text('OUR SPACE • END-TO-END ENCRYPTED', style: AppText.label.copyWith(color: AppColors.primary, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
