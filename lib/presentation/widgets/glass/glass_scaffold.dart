library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:laundry_manager/presentation/widgets/glass/glass_background.dart';

/// Scaffold con AppBar translúcido/blur y fondo [GlassBackground],
/// para no repetir el mismo patrón en cada pantalla.
class GlassScaffold extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;

  const GlassScaffold({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: drawer,
      appBar: AppBar(
        leading: leading,
        actions: actions,
        title: title,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: theme.colorScheme.surface.withValues(alpha: isDark ? 0.35 : 0.45),
            ),
          ),
        ),
      ),
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              Expanded(child: body),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
