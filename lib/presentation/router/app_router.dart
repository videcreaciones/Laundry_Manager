library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/presentation/providers/garment_provider.dart';
import 'package:laundry_manager/presentation/screens/add_garment_screen.dart';
import 'package:laundry_manager/presentation/screens/categories_screen.dart';
import 'package:laundry_manager/presentation/screens/edit_garment_screen.dart';
import 'package:laundry_manager/presentation/screens/garment_detail_screen.dart';
import 'package:laundry_manager/presentation/screens/garment_list_screen.dart';
import 'package:laundry_manager/presentation/screens/search_screen.dart';
import 'package:laundry_manager/presentation/screens/settings_screen.dart';

abstract final class AppRoutes {
  static const list       = '/';
  static const add        = '/add';
  static const detail     = '/detail/:id';
  static const edit       = '/edit/:id';
  static const search     = '/search';
  static const categories = '/categories';
  static const settings   = '/settings';

  static String detailPath(String id) => '/detail/$id';
  static String editPath(String id)   => '/edit/$id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.list,
  routes: [
    GoRoute(path: AppRoutes.list,       builder: (_, __) => const GarmentListScreen()),
    GoRoute(path: AppRoutes.add,        builder: (_, __) => const AddGarmentScreen()),
    GoRoute(path: AppRoutes.search,     builder: (_, __) => const SearchScreen()),
    GoRoute(path: AppRoutes.categories, builder: (_, __) => const CategoriesScreen()),
    GoRoute(path: AppRoutes.settings,   builder: (_, __) => const SettingsScreen()),
    GoRoute(
      path: AppRoutes.detail,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is GarmentEntity) {
          return GarmentDetailScreen(garment: extra);
        }
        // Sin `extra` (ej. se abrio desde una notificacion) — buscar la
        // prenda por id una vez que la lista cargue.
        return _GarmentDetailById(id: state.pathParameters['id']!);
      },
    ),
    GoRoute(
      path: AppRoutes.edit,
      builder: (context, state) =>
          EditGarmentScreen(garment: state.extra as GarmentEntity),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
  ),
);

/// Carga una prenda por id desde el estado ya cacheado del provider —
/// usado cuando se navega al detalle sin pasar la entidad por `extra`
/// (deep link desde una notificacion, por ejemplo).
class _GarmentDetailById extends ConsumerWidget {
  final String id;
  const _GarmentDetailById({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(garmentNotifierProvider);
    return garmentsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        body: Center(child: Text('No se pudo cargar la prenda "$id"')),
      ),
      data: (garments) {
        final garment = garments.where((g) => g.id == id).firstOrNull;
        if (garment == null) {
          return const Scaffold(
            body: Center(child: Text('Prenda no encontrada')),
          );
        }
        return GarmentDetailScreen(garment: garment);
      },
    );
  }
}
