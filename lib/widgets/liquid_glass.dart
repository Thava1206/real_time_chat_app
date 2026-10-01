import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LiquidGlassBackground extends StatelessWidget {
  const LiquidGlassBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.surfaces.isGlass) return child;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111A35), Color(0xFF20153A), Color(0xFF071522)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -120,
            right: -80,
            child: _Glow(color: Color(0x665C8DFF), size: 340),
          ),
          const Positioned(
            bottom: -150,
            left: -100,
            child: _Glow(color: Color(0x668E4CC7), size: 380),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}

class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding,
    this.color,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final contents = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? surfaces.surface,
        borderRadius: borderRadius,
        border: Border.all(color: surfaces.glassBorder),
        boxShadow: surfaces.isGlass
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
    if (!surfaces.isGlass) return contents;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: contents,
      ),
    );
  }
}
