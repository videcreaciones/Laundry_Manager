/// Pantalla principal: lista todas las prendas agrupadas por estado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:laundry_manager/presentation/widgets/garment_card_widget.dart';

class GarmentListScreen extends ConsumerWidget {
  const GarmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(garmentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laundry Manager',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Acerca de',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: garmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is GarmentException
              ? error.userMessage
              : 'Error inesperado: $error',
          onRetry: () => ref.invalidate(garmentNotifierProvider),
        ),
        data: (garments) => garments.isEmpty
            ? const _EmptyView()
            : _GarmentList(garments: garments),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.add),
        icon: const Icon(Icons.add),
        label: const Text('Nueva prenda'),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Laundry Manager',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Gestión de prendas de lavandería',
    );
  }
}

/// Lista de prendas con separadores por estado.
class _GarmentList extends ConsumerWidget {
  final List<GarmentEntity> garments;
  const _GarmentList({required this.garments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: garments.length,
      itemBuilder: (context, index) {
        final garment = garments[index];
        final prevGarment = index > 0 ? garments[index - 1] : null;
        final showHeader = prevGarment?.status != garment.status;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _StatusHeader(status: garment.status),
            GarmentCard(
              garment: garment,
              onTap: () => context.push(
                AppRoutes.detailPath(garment.id),
                extra: garment,
              ),
              onStatusChange: garment.status.nextStatus != null
                  ? () => _handleStatusChange(context, ref, garment)
                  : null,
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleStatusChange(
    BuildContext context,
    WidgetRef ref,
    GarmentEntity garment,
  ) async {
    final nextStatus = garment.status.nextStatus;
    if (nextStatus == null) return;

    try {
      await ref.read(garmentNotifierProvider.notifier).updateStatus(
        id: garment.id,
        from: garment.status,
        to: nextStatus,
      );
    } on GarmentException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.userMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Header de sección por estado.
class _StatusHeader extends StatelessWidget {
  final GarmentStatus status;
  const _StatusHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Text(
        status.displayLabel.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Vista de lista vacía con call-to-action.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_laundry_service_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay prendas registradas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar una prenda',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vista de error con botón de reintento.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
