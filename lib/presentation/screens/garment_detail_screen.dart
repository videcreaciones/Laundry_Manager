/// Pantalla de detalle de una prenda.
///
/// Permite ver todos los datos, avanzar el estado (RN-01) y
/// eliminar la prenda si no estÃ¡ en LAVANDO (RN-02).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/widgets/image_preview_widget.dart';
import 'package:laundry_manager/presentation/widgets/status_action_button.dart';

class GarmentDetailScreen extends ConsumerStatefulWidget {
  final GarmentEntity garment;
  const GarmentDetailScreen({super.key, required this.garment});

  @override
  ConsumerState<GarmentDetailScreen> createState() =>
      _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends ConsumerState<GarmentDetailScreen> {
  bool _isUpdating = false;

  /// Obtiene la versiÃ³n mÃ¡s actualizada de la prenda desde el provider.
  /// Esto garantiza que los botones reflejen el estado real tras una
  /// actualizaciÃ³n mientras esta pantalla estÃ¡ abierta.
  GarmentEntity get _currentGarment {
    final list = ref.watch(garmentNotifierProvider).value ?? [];
    return list.firstWhere(
      (e) => e.id == widget.garment.id,
      orElse: () => widget.garment,
    );
  }

  Future<void> _handleStatusChange() async {
    final garment = _currentGarment;
    final nextStatus = garment.status.nextStatus;
    if (nextStatus == null) return;

    setState(() => _isUpdating = true);
    try {
      await ref.read(garmentNotifierProvider.notifier).updateStatus(
        id: garment.id,
        from: garment.status,
        to: nextStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a "${nextStatus.displayLabel}"'),
          ),
        );
      }
    } on GarmentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleDelete() async {
    final garment = _currentGarment;

    // RN-02: no permitir borrar si estÃ¡ en LAVANDO
    if (garment.status == GarmentStatus.lavando) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se puede eliminar una prenda en lavanderÃ­a'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar prenda'),
        content: Text(
          'Â¿Eliminar "${garment.name}"?\nEsta acciÃ³n no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => ctx.pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(garmentNotifierProvider.notifier).deleteGarment(
        id: garment.id,
        currentStatus: garment.status,
      );
      if (mounted) context.pop();
    } on GarmentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final garment = _currentGarment;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          garment.name,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Borrar solo si no estÃ¡ en LAVANDO
          if (garment.status != GarmentStatus.lavando)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar prenda',
              color: theme.colorScheme.error,
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Foto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            ImagePreviewWidget(
              existingImagePath: garment.imagePath,
            ),
            const SizedBox(height: 24),

            // â”€â”€ Datos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _InfoTile(
              icon: Icons.checkroom_outlined,
              label: 'Prenda',
              value: garment.name,
            ),
            _InfoTile(
              icon: Icons.person_outline,
              label: 'Propietario',
              value: garment.owner,
            ),
            _InfoTile(
              icon: Icons.flag_outlined,
              label: 'Estado actual',
              value: garment.status.displayLabel,
            ),
            if (garment.notes != null && garment.notes!.isNotEmpty)
              _InfoTile(
                icon: Icons.notes_outlined,
                label: 'Notas',
                value: garment.notes!,
              ),
            _InfoTile(
              icon: Icons.calendar_today_outlined,
              label: 'Registrada el',
              value: _formatDate(garment.createdAt),
            ),
            if (garment.updatedAt != garment.createdAt)
              _InfoTile(
                icon: Icons.update_outlined,
                label: 'Ãšltima actualizaciÃ³n',
                value: _formatDate(garment.updatedAt),
              ),

            const SizedBox(height: 32),

            // â”€â”€ BotÃ³n de acciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            StatusActionButton(
              currentStatus: garment.status,
              isLoading: _isUpdating,
              onPressed: _handleStatusChange,
            ),

            // Mensaje informativo para estado terminal
            if (garment.status != GarmentStatus.lavando)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Prenda devuelta al propietario',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
