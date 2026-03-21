library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';
import 'package:laundry_manager/presentation/providers/category_provider.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:laundry_manager/presentation/providers/image_picker_provider.dart';
import 'package:laundry_manager/presentation/widgets/image_preview_widget.dart';
import 'package:laundry_manager/presentation/widgets/status_action_button.dart';

class GarmentDetailScreen extends ConsumerStatefulWidget {
  final GarmentEntity garment;
  const GarmentDetailScreen({super.key, required this.garment});

  @override
  ConsumerState<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends ConsumerState<GarmentDetailScreen> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Limpiar imagen seleccionada previamente para que no aparezca
    // la foto de la prenda anterior al navegar al detalle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imagePickerProvider.notifier).clearImage();
    });
  }

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
        id: garment.id, from: garment.status, to: nextStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a "${nextStatus.displayLabel}"')),
        );
      }
    } on GarmentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleDelete() async {
    final garment = _currentGarment;
    if (garment.status == GarmentStatus.lavando) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se puede eliminar una prenda en lavandería'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar prenda'),
        content: Text('¿Eliminar "${garment.name}"?\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => ctx.pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(garmentNotifierProvider.notifier).deleteGarment(
        id: garment.id, currentStatus: garment.status,
      );
      if (mounted) context.pop();
    } on GarmentException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage),
              backgroundColor: Theme.of(context).colorScheme.error),
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
        title: Text(garment.name, overflow: TextOverflow.ellipsis),
        actions: [
          // Botón editar — siempre visible
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar prenda',
            onPressed: () => context.push(
              AppRoutes.editPath(garment.id),
              extra: garment,
            ),
          ),
          // Botón borrar — solo si no está en LAVANDO
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
            ImagePreviewWidget(existingImagePath: garment.imagePath),
            const SizedBox(height: 24),
            _InfoTile(icon: Icons.checkroom_outlined, label: 'Prenda', value: garment.name),
            _InfoTile(icon: Icons.person_outline, label: 'Propietario', value: garment.owner),
            _InfoTile(icon: Icons.flag_outlined, label: 'Estado actual', value: garment.status.displayLabel),
            _CategoryInfoTile(categoryId: garment.categoryId),
            if (garment.notes != null && garment.notes!.isNotEmpty)
              _InfoTile(icon: Icons.notes_outlined, label: 'Notas', value: garment.notes!),
            _InfoTile(icon: Icons.calendar_today_outlined, label: 'Registrada el', value: _formatDate(garment.createdAt)),
            if (garment.updatedAt != garment.createdAt)
              _InfoTile(icon: Icons.update_outlined, label: 'Última actualización', value: _formatDate(garment.updatedAt)),
            const SizedBox(height: 32),
            StatusActionButton(
              currentStatus: garment.status,
              isLoading: _isUpdating,
              onPressed: _handleStatusChange,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

class _CategoryInfoTile extends ConsumerWidget {
  final String? categoryId;
  const _CategoryInfoTile({this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) return const SizedBox.shrink();
    final categories = ref.watch(categoryProvider);
    final cat = categories.where((c) => c.id == categoryId).firstOrNull;
    if (cat == null) return const SizedBox.shrink();
    return _InfoTile(
      icon: Icons.label_outline,
      label: "Categoría",
      value: cat.name,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

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
                Text(label, style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
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





