library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';
import 'package:laundry_manager/presentation/providers/update_provider.dart';
import 'package:laundry_manager/presentation/widgets/glass/glass_container.dart';
import 'package:laundry_manager/presentation/widgets/glass/glass_scaffold.dart';

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
  late final TextEditingController _nameController;

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
    _nameController =
        TextEditingController(text: ref.read(settingsProvider).singleUserName);
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
    final version  = ref.watch(packageInfoProvider).whenOrNull(data: (p) => p.version);

    return GlassScaffold(
      title: const Text('Configuracion'),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              // ASPECTO
              _SectionHeader(title: 'Aspecto'),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                blurBackground: false,
                child: SwitchListTile(
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
              ),

              // RELLENO AUTOMATICO
              _SectionHeader(title: 'Relleno automatico'),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                blurBackground: false,
                child: Column(
                  children: [
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Cuando esta activado, al crear una prenda se generara '
                          'automaticamente una descripcion basada en el nombre, '
                          'la categoria y el propietario.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // TIPO DE CUENTA
              _SectionHeader(title: 'Tipo de cuenta'),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                blurBackground: false,
                child: Column(
                  children: [
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
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Opciones para usuario único',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tu nombre',
                            hintText: 'Ej: Juan Pérez',
                            prefixIcon: Icon(Icons.person_outline),
                            helperText:
                                'Este nombre se usará como propietario de todas tus prendas',
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
                        title: const Text('Rellenar propietario automáticamente'),
                        subtitle: Text(settings.autoFillOwner
                            ? 'Al crear una prenda, el propietario se llena solo con tu nombre'
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
                              : 'El campo propietario está oculto — se llena solo con tu nombre'),
                          value: !settings.showOwnerField,
                          onChanged: (_) => notifier.toggleShowOwnerField(),
                        ),
                    ],
                  ],
                ),
              ),

              // CAMBIO DE ESTADO
              _SectionHeader(title: 'Cómo cambiar el estado de una prenda'),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                blurBackground: false,
                child: RadioGroup<bool>(
                  groupValue: settings.useStatusSelector,
                  onChanged: (v) {
                    if (v != null && v != settings.useStatusSelector) {
                      notifier.toggleUseStatusSelector();
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<bool>(
                        secondary: Icon(Icons.arrow_forward_rounded),
                        title: Text('Con la flecha'),
                        subtitle: Text(
                            'Un botón avanza la prenda al siguiente estado en orden: '
                            'Guardada → Lavando → Devuelta → Guardada'),
                        value: false,
                      ),
                      RadioListTile<bool>(
                        secondary: Icon(Icons.tune_outlined),
                        title: Text('Con un selector'),
                        subtitle: Text(
                            'Ves los tres estados como botones y eliges directamente '
                            'a cuál quieres cambiar la prenda'),
                        value: true,
                      ),
                    ],
                  ),
                ),
              ),

              // CONTADOR DE PRENDAS
              _SectionHeader(title: 'Contador de prendas'),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                blurBackground: false,
                child: SwitchListTile(
                  secondary: Icon(Icons.format_list_numbered_outlined,
                      color: theme.colorScheme.primary),
                  title: const Text('Mostrar cantidad por estado'),
                  subtitle: Text(settings.showGarmentCounter
                      ? 'Se muestra un número al lado de cada grupo indicando cuántas prendas hay'
                      : 'Los grupos se muestran sin número de prendas'),
                  value: settings.showGarmentCounter,
                  onChanged: (_) => notifier.toggleShowGarmentCounter(),
                ),
              ),

              // ACERCA DE
              _SectionHeader(title: 'Acerca de'),
              GlassContainer(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                blurBackground: false,
                child: GestureDetector(
                  onTap: _onVersionTap,
                  child: ListTile(
                    leading: Icon(Icons.info_outline,
                        color: theme.colorScheme.primary),
                    title: const Text('Version'),
                    trailing: Text(version ?? '…',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
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
