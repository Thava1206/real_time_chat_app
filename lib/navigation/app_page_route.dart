import 'package:flutter/material.dart';

const _pageTransitionDuration = Duration(milliseconds: 360);

/// Removes outgoing content before revealing the incoming page so text from
/// two routes never visually overlaps.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        transitionDuration: _pageTransitionDuration,
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final incomingOpacity = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.38, 1, curve: Curves.easeOutCubic),
            reverseCurve: const Interval(0, 0.62, curve: Curves.easeInCubic),
          );
          final outgoingOpacity = ReverseAnimation(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Interval(0, 0.38, curve: Curves.easeOutCubic),
              reverseCurve: const Interval(0.62, 1, curve: Curves.easeInCubic),
            ),
          );
          final scale = Tween<double>(begin: 0.985, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return ClipRect(
            child: FadeTransition(
              opacity: outgoingOpacity,
              child: FadeTransition(
                opacity: incomingOpacity,
                child: ScaleTransition(scale: scale, child: child),
              ),
            ),
          );
        },
      );
}

Future<T?> pushAppPage<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push<T>(AppPageRoute<T>(builder: builder));

Widget buildFadeThroughTransition(Widget child, Animation<double> animation) {
  final opacity = CurvedAnimation(
    parent: animation,
    curve: const Interval(0.5, 1, curve: Curves.easeOutCubic),
  );
  final scale = Tween<double>(
    begin: 0.99,
    end: 1,
  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
  return ClipRect(
    child: FadeTransition(
      opacity: opacity,
      child: ScaleTransition(scale: scale, child: child),
    ),
  );
}
