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
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _peanutController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _peanutScale = CurvedAnimation(
      parent: _peanutController, curve: Curves.elasticOut);
    _nameController = TextEditingController(
      text: ref.read(settingsProvider).singleUserName);
  }

  @override
  void dispose() {
    _peanutController.dispose();
    _nameController.dispose();
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
    final notifier = ref.read(settingsProvider.notifier);
    final theme    = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: Stack(
        children: [
          ListView(
            children: [

              // ── ASPECTO ────────────────────────────────────────────
              _SectionHeader(title: 'Aspecto'),
              SwitchListTile(
                secondary: Icon(
                  settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.primary),
                title: const Text('Modo oscuro'),
                subtitle: Text(settings.darkMode
                    ? 'La app usa colores oscuros'
                    : 'La app usa colores claros'),
                value: settings.darkMode,
                onChanged: (_) => notifier.toggleDarkMode(),
              ),
              const Divider(indent: 16, endIndent: 16),

              // ── TIPO DE CUENTA ─────────────────────────────────────
              _SectionHeader(title: 'Tipo de cuenta'),
              SwitchListTile(
                secondary: Icon(Icons.business_outlined,
                    color: theme.colorScheme.primary),
                title: const Text('Modo empresa'),
                subtitle: Text(settings.companyMode
                    ? 'Cada prenda tiene un propietario — puedes filtrar por usuario'
                    : 'La app es para un solo usuario — el campo propietario se puede ocultar'),
                value: settings.companyMode,
                onChanged: (_) => notifier.toggleCompanyMode(),
              ),

              if (!settings.companyMode) ...[
                const Divider(indent: 72, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Opciones para usuario unico',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tu nombre',
                      hintText: 'Ej: Juan Perez',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      helperText: 'Este nombre se usara como propietario de todas tus prendas',
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: notifier.setSingleUserName,
                  ),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.auto_fix_high_outlined,
                      color: settings.singleUserName.trim().isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant),
                  title: const Text('Rellenar propietario automaticamente'),
                  subtitle: Text(settings.autoFillOwner
                      ? 'Al crear una prenda, el campo propietario se llena solo con tu nombre'
                      : 'Debes escribir el propietario cada vez que creas una prenda'),
                  value: settings.autoFillOwner,
                  onChanged: settings.singleUserName.trim().isEmpty
                      ? null
                      : (_) => notifier.toggleAutoFillOwner(),
                ),
                if (settings.autoFillOwner)
                  SwitchListTile(
                    secondary: Icon(Icons.visibility_off_outlined,
                        color: theme.colorScheme.primary),
                    title: const Text('Ocultar campo propietario'),
                    subtitle: Text(settings.showOwnerField
                        ? 'El campo propietario aparece al crear prendas (puedes cambiarlo)'
                        : 'El campo propietario esta oculto — se llena solo con tu nombre'),
                    value: !settings.showOwnerField,
                    onChanged: (_) => notifier.toggleShowOwnerField(),
                  ),
              ],
              const Divider(indent: 16, endIndent: 16),

              // ── CAMBIO DE ESTADO ───────────────────────────────────
              _SectionHeader(title: 'Como cambiar el estado de una prenda'),
              RadioListTile<bool>.adaptive(
                secondary: const Icon(Icons.arrow_forward_rounded),
                title: const Text('Con la flecha'),
                subtitle: const Text(
                    'Un boton avanza la prenda al siguiente estado en orden: '
                    'Guardada → Lavando → Devuelta → Guardada'),
                value: false,
                groupValue: settings.useStatusSelector,
                onChanged: (_) {
                  if (settings.useStatusSelector) {
                    notifier.toggleUseStatusSelector();
                  }
                },
              ),
              RadioListTile<bool>.adaptive(
                secondary: const Icon(Icons.tune_outlined),
                title: const Text('Con un selector'),
                subtitle: const Text(
                    'Ves los tres estados como botones y eliges directamente '
                    'a cual quieres cambiar la prenda'),
                value: true,
                groupValue: settings.useStatusSelector,
                onChanged: (_) {
                  if (!settings.useStatusSelector) {
                    notifier.toggleUseStatusSelector();
                  }
                },
              ),
              const Divider(indent: 16, endIndent: 16),

              // ── CONTADOR DE PRENDAS ────────────────────────────────
              _SectionHeader(title: 'Contador de prendas'),
              SwitchListTile(
                secondary: Icon(Icons.format_list_numbered_outlined,
                    color: theme.colorScheme.primary),
                title: const Text('Mostrar cantidad por estado'),
                subtitle: Text(settings.showGarmentCounter
                    ? 'Se muestra un numero al lado de cada grupo indicando cuantas prendas hay'
                    : 'Los grupos se muestran sin numero de prendas'),
                value: settings.showGarmentCounter,
                onChanged: (_) => notifier.toggleShowGarmentCounter(),
              ),
              const Divider(indent: 16, endIndent: 16),

              // ── DESCRIPCION AUTOMATICA ─────────────────────────────
              _SectionHeader(title: 'Descripcion automatica'),
              SwitchListTile(
                secondary: Icon(Icons.auto_awesome,
                    color: settings.autoFill
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant),
                title: const Text('Generar descripcion al crear una prenda'),
                subtitle: Text(settings.autoFill
                    ? 'Si dejas el campo de notas vacio, se genera una descripcion '
                      'automatica basada en el nombre y la categoria'
                    : 'Las notas se escriben manualmente o se dejan vacias'),
                value: settings.autoFill,
                onChanged: (_) => notifier.toggleAutoFill(),
              ),
              const Divider(indent: 16, endIndent: 16),

              // ── ACERCA DE ──────────────────────────────────────────
              _SectionHeader(title: 'Acerca de'),
              GestureDetector(
                onTap: _onVersionTap,
                child: ListTile(
                  leading: Icon(Icons.info_outline,
                      color: theme.colorScheme.primary),
                  title: const Text('Version'),
                  trailing: const Text('1.4.0',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),

          // Easter egg
          if (_showPeanut)
            Center(
              child: ScaleTransition(
                scale: _peanutScale,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🥜', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 12),
                      Text('Encontraste el cacahuate!',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Eres un usuario curioso 👀',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
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
      child: Text(title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2)),
    );
  }
}

