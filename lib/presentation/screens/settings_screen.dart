library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [

          // ── ASPECTO ────────────────────────────────────────────────
          _SectionHeader(title: 'Aspecto'),
          SwitchListTile(
            secondary: Icon(
              settings.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Modo oscuro'),
            subtitle: Text(settings.darkMode ? 'Activado' : 'Desactivado'),
            value: settings.darkMode,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleDarkMode(),
          ),
          const Divider(indent: 16, endIndent: 16),

          // ── RELLENO AUTOMÁTICO ─────────────────────────────────────
          _SectionHeader(title: 'Relleno automático'),
          SwitchListTile(
            secondary: Icon(
              Icons.auto_awesome,
              color: settings.autoFill
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            title: const Text('Descripción automática'),
            subtitle: Text(
              settings.autoFill
                  ? 'Se generará una descripción al crear una prenda'
                  : 'Desactivado — la descripción se ingresa manualmente',
            ),
            value: settings.autoFill,
            onChanged: (_) => ref.read(settingsProvider.notifier).toggleAutoFill(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
            child: Text(
              'Cuando está activado, al crear una prenda se generará '
              'automáticamente una descripción basada en el nombre y la categoría.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(indent: 16, endIndent: 16),

          // ── ACERCA DE ──────────────────────────────────────────────
          _SectionHeader(title: 'Acerca de'),
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            title: const Text('Versión'),
            trailing: const Text('1.2.1',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

