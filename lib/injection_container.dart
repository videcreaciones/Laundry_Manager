/// Contenedor de inyección de dependencias.
///
/// Define el árbol completo de providers de Riverpod, respetando
/// el orden de dependencias entre capas:
///
///   Hive Box → DataSource → Repository → UseCases → Notifier
///
/// Restricciones de diseño:
/// - Los providers de dominio NO importan hive/ directamente.
/// - El [hiveBoxProvider] es el único punto de entrada de Hive al grafo.
/// - Se sobreescribe en tests con [ProviderScope(overrides: [...])].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/datasources/hive_garment_datasource.dart';
import 'package:laundry_manager/data/mappers/garment_mapper.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/data/repositories/garment_repository_impl.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/usecases/delete_garment_usecase.dart';
import 'package:laundry_manager/domain/usecases/get_all_garments_usecase.dart';
import 'package:laundry_manager/domain/usecases/save_garment_usecase.dart';
import 'package:laundry_manager/domain/usecases/update_garment_status_usecase.dart';

// ── Capa de Datos ─────────────────────────────────────────────────────────────

/// Box de Hive. Se sobreescribe en [main.dart] con el box ya abierto.
/// Lanza [UnimplementedError] si se usa sin override (protección en tests).
final hiveBoxProvider = Provider<Box<GarmentModel>>(
  (ref) => throw UnimplementedError(
    'hiveBoxProvider debe ser sobreescrito en ProviderScope con el box abierto.',
  ),
  name: 'hiveBoxProvider',
);

/// Mapper bidireccional — sin estado, singleton.
final garmentMapperProvider = Provider<GarmentMapper>(
  (_) => const GarmentMapper(),
  name: 'garmentMapperProvider',
);

/// DataSource que encapsula las operaciones CRUD de Hive.
final garmentDataSourceProvider = Provider<HiveGarmentDataSource>(
  (ref) => HiveGarmentDataSource(ref.read(hiveBoxProvider)),
  name: 'garmentDataSourceProvider',
);

/// Implementación concreta del repositorio.
final garmentRepositoryProvider = Provider<IGarmentRepository>(
  (ref) => GarmentRepositoryImpl(
    dataSource: ref.read(garmentDataSourceProvider),
    mapper: ref.read(garmentMapperProvider),
  ),
  name: 'garmentRepositoryProvider',
);

// ── Capa de Dominio — Use Cases ───────────────────────────────────────────────

final getAllGarmentsUseCaseProvider = Provider<GetAllGarmentsUseCase>(
  (ref) => GetAllGarmentsUseCase(ref.read(garmentRepositoryProvider)),
  name: 'getAllGarmentsUseCaseProvider',
);

final saveGarmentUseCaseProvider = Provider<SaveGarmentUseCase>(
  (ref) => SaveGarmentUseCase(ref.read(garmentRepositoryProvider)),
  name: 'saveGarmentUseCaseProvider',
);

final updateGarmentStatusUseCaseProvider = Provider<UpdateGarmentStatusUseCase>(
  (ref) => UpdateGarmentStatusUseCase(ref.read(garmentRepositoryProvider)),
  name: 'updateGarmentStatusUseCaseProvider',
);

final deleteGarmentUseCaseProvider = Provider<DeleteGarmentUseCase>(
  (ref) => DeleteGarmentUseCase(ref.read(garmentRepositoryProvider)),
  name: 'deleteGarmentUseCaseProvider',
);
