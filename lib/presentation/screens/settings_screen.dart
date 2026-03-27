library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  late AnimationController _peanutController;
  late Animation<double> _peanutScale;
  bool _showPeanut = false;

  @override
  void initState() {
    super.initState();
    _peanutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _peanutScale = CurvedAnimation(
      parent: _peanutController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _peanutController.dispose();
    super.dispose();
  }

  void _onVersionTap() {
    _tapCount++;
    if (_tapCount >= 10) {
      _tapCount = 0;
      setState(() => _showPeanut = true);
      _peanutController.forward(from: 0);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _peanutController.reverse();
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) setState(() => _showPeanut = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: Stack(
        children: [
          ListView(
            children: [
              // ASPECTO
              _SectionHeader(title: 'Aspecto'),
              SwitchListTile(
                secondary: Icon(
                  settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Modo oscuro'),
                subtitle: Text(settings.darkMode ? 'Activado' : 'Desactivado'),
                value: settings.darkMode,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleDarkMode(),
              ),
              const Divider(indent: 16, endIndent: 16),

              // RELLENO AUTOMATICO
              _SectionHeader(title: 'Relleno automatico'),
              SwitchListTile(
                secondary: Icon(
                  Icons.auto_awesome,
                  color: settings.autoFill
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
                title: const Text('Descripcion automatica'),
                subtitle: Text(
                  settings.autoFill
                      ? 'Se generara una descripcion al crear una prenda'
                      : 'Desactivado - la descripcion se ingresa manualmente',
                ),
                value: settings.autoFill,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleAutoFill(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
                child: Text(
                  'Cuando esta activado, al crear una prenda se generara '
                  'automaticamente una descripcion basada en el nombre, '
                  'la categoria y el propietario.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(indent: 16, endIndent: 16),

              // ACERCA DE
              _SectionHeader(title: 'Acerca de'),
              GestureDetector(
                onTap: _onVersionTap,
                child: ListTile(
                  leading: Icon(Icons.info_outline,
                      color: theme.colorScheme.primary),
                  title: const Text('Version'),
                  trailing: const Text('1.3.1',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),

          // Easter egg — cacahuate
          if (_showPeanut)
            Center(
              child: ScaleTransition(
                scale: _peanutScale,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🥜', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 12),
                      Text(
                        'Encontraste el cacahuate!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Eres un usuario curioso 👀',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
