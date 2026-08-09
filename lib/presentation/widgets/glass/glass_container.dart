library;

import 'dart:ui';

import 'package:flutter/material.dart';

/// Panel translúcido estilo "vidrio esmerilado" (glassmorphism).
///
/// [blurBackground] controla si se aplica [BackdropFilter] en vivo (costoso
/// si se repite muchas veces a la vez, ej. en una lista larga). Úsalo en
/// `true` para elementos fijos en pantalla (AppBar, buscador, drawer) y en
/// `false` para elementos que se repiten (tarjetas de una lista), donde el
/// relleno translúcido + borde + sombra ya da el efecto sin el costo del blur.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool blurBackground;
  final double blurSigma;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.margin,
    this.blurBackground = true,
    this.blurSigma = 16,
    this.opacity = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = isDark ? Colors.black : Colors.white;
    final borderColor = Colors.white.withValues(alpha: isDark ? 0.08 : 0.5);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: opacity),
            tint.withValues(alpha: opacity - 0.15 < 0 ? opacity : opacity - 0.15),
          ],
        ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: blurBackground
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: content,
              )
            : content,
      ),
    );
  }
}
