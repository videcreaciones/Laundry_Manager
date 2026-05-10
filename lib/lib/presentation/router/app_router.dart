library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
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
      builder: (context, state) =>
          GarmentDetailScreen(garment: state.extra as GarmentEntity),
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
