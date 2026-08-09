library;

import 'dart:ui';

import 'package:flutter/material.dart';

/// Fondo neutro con degradado sutil y "blobs" de color desenfocados,
/// pensado para servir de base a paneles [GlassContainer] por encima.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF14171C), Color(0xFF1D2127)]
                  : const [Color(0xFFF4F6F9), Color(0xFFE7EBF1)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _Blob(color: accent, diameter: 260, opacity: isDark ? 0.18 : 0.14),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: _Blob(color: accent, diameter: 280, opacity: isDark ? 0.14 : 0.10),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double diameter;
  final double opacity;

  const _Blob({required this.color, required this.diameter, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
