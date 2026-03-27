library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/router/app_router.dart';
import 'package:laundry_manager/presentation/widgets/garment_card_widget.dart';
import 'package:laundry_manager/presentation/widgets/update_banner_widget.dart';

class GarmentListScreen extends ConsumerStatefulWidget {
  const GarmentListScreen({super.key});

  @override
  ConsumerState<GarmentListScreen> createState() => _GarmentListScreenState();
}

class _GarmentListScreenState extends ConsumerState<GarmentListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GarmentEntity> _filtered(List<GarmentEntity> all) {
    if (_query.isEmpty) return all;
    return all.where((g) =>
      g.name.toLowerCase().contains(_query.toLowerCase()) ||
      g.owner.toLowerCase().contains(_query.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(garmentNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const _AppDrawer(),
      appBar: AppBar(
        title: const Text('Laundry Manager',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          const UpdateBannerWidget(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar prendas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: garmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error is GarmentException
                    ? error.userMessage : 'Error inesperado: $error',
                onRetry: () => ref.invalidate(garmentNotifierProvider),
              ),
              data: (garments) {
                final filtered = _filtered(garments);
                if (garments.isEmpty) return const _EmptyView();
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text('No se encontraron prendas',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return _GarmentList(garments: filtered);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.add),
        icon: const Icon(Icons.add),
        label: const Text('Nueva prenda'),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: theme.colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_laundry_service,
                      size: 40, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(height: 8),
                  Text('Laundry Manager',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      )),
                  Text('v1.3.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Buscar'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.search);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Categorías'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.categories);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.settings);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GarmentList extends ConsumerWidget {
  final List<GarmentEntity> garments;
  const _GarmentList({required this.garments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
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
                  AppRoutes.detailPath(garment.id), extra: garment),
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
      BuildContext context, WidgetRef ref, GarmentEntity garment) async {
    final nextStatus = garment.status.nextStatus;
    if (nextStatus == null) return;
    try {
      await ref.read(garmentNotifierProvider.notifier).updateStatus(
        id: garment.id, from: garment.status, to: nextStatus,
      );
    } on GarmentException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userMessage),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }
}

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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_laundry_service_outlined, size: 72,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('No hay prendas registradas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Toca el botón + para agregar una prenda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}

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
            Icon(Icons.error_outline, size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}





