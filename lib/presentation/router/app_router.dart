/// ConfiguraciÃ³n de rutas de la aplicaciÃ³n con go_router.
///
/// Rutas definidas:
///   /           â†’ GarmentListScreen (pantalla principal)
///   /add        â†’ AddGarmentScreen
///   /detail/:id â†’ GarmentDetailScreen
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/presentation/screens/add_garment_screen.dart';
import 'package:laundry_manager/presentation/screens/garment_detail_screen.dart';
import 'package:laundry_manager/presentation/screens/garment_list_screen.dart';

/// Rutas nombradas para evitar strings mÃ¡gicos en el cÃ³digo.
abstract final class AppRoutes {
  static const list   = '/';
  static const add    = '/add';
  static const detail = '/detail/:id';

  static String detailPath(String id) => '/detail/$id';
}

/// Router principal de la aplicaciÃ³n.
final appRouter = GoRouter(
  initialLocation: AppRoutes.list,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.list,
      builder: (_, __) => const GarmentListScreen(),
    ),
    GoRoute(
      path: AppRoutes.add,
      builder: (_, __) => const AddGarmentScreen(),
    ),
    GoRoute(
      path: AppRoutes.detail,
      builder: (context, state) {
        final garment = state.extra as GarmentEntity;
        return GarmentDetailScreen(garment: garment);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Ruta no encontrada: ${state.uri}'),
    ),
  ),
);
