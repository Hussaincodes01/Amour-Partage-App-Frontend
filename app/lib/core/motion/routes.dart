import 'package:flutter/material.dart';

import 'motion.dart';

/// Screen transition: the new page fades in and "pops" up from 94% scale.
class PopRoute<T> extends PageRouteBuilder<T> {
  PopRoute({required WidgetBuilder builder, super.settings, super.fullscreenDialog, this.slideUp = false})
      : super(
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.medium,
          pageBuilder: (context, _, _) => builder(context),
        );

  /// Slide from below instead of scaling (used for the call screen).
  final bool slideUp;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (Motion.reduced(context)) return FadeTransition(opacity: animation, child: child);
    final fade = CurvedAnimation(parent: animation, curve: Motion.fadeIn, reverseCurve: Motion.fadeOut);
    final pop = CurvedAnimation(parent: animation, curve: Motion.emphasized, reverseCurve: Curves.easeInCubic);
    // The page underneath recedes slightly while another sits on top.
    final behind = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: secondaryAnimation, curve: Motion.emphasized));
    Widget page = FadeTransition(
      opacity: fade,
      child: slideUp
          ? SlideTransition(position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(pop), child: child)
          : ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(pop), child: child),
    );
    return ScaleTransition(scale: behind, child: page);
  }
}

extension NavX on BuildContext {
  Future<T?> pushPop<T>(Widget page, {bool slideUp = false}) =>
      Navigator.of(this).push<T>(PopRoute<T>(builder: (_) => page, slideUp: slideUp));

  Future<T?> replaceWithPop<T>(Widget page) =>
      Navigator.of(this).pushReplacement<T, void>(PopRoute<T>(builder: (_) => page));

  Future<T?> resetTo<T>(Widget page) => Navigator.of(this).pushAndRemoveUntil<T>(PopRoute<T>(builder: (_) => page), (_) => false);
}

/// Bottom sheet that slides + fades in, styled like the design's drawers.
Future<T?> showAmourSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    sheetAnimationStyle: const AnimationStyle(duration: Motion.slow, reverseDuration: Motion.medium, curve: Motion.emphasized),
    builder: builder,
  );
}
