/// Contenedor de inyecciÃ³n de dependencias.
///
/// Define el Ã¡rbol completo de providers de Riverpod, respetando
/// el orden de dependencias entre capas:
///
///   Hive Box â†’ DataSource â†’ Repository â†’ UseCases â†’ Notifier
///
/// Restricciones de diseÃ±o:
/// - Los providers de dominio NO importan hive/ directamente.
/// - El [hiveBoxProvider] es el Ãºnico punto de entrada de Hive al grafo.
/// - Se sobreescribe en tests con [ProviderScope(overrides: [...])].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/datasources/garment_image_storage.dart';
import 'package:laundry_manager/data/datasources/hive_garment_datasource.dart';
import 'package:laundry_manager/data/mappers/garment_mapper.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/data/repositories/garment_repository_impl.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/usecases/delete_garment_usecase.dart';
import 'package:laundry_manager/domain/usecases/get_all_garments_usecase.dart';
import 'package:laundry_manager/domain/usecases/save_garment_usecase.dart';
import 'package:laundry_manager/domain/usecases/update_garment_status_usecase.dart';
import 'package:laundry_manager/domain/usecases/update_garment_usecase.dart';

// â”€â”€ Capa de Datos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Box de Hive. Se sobreescribe en [main.dart] con el box ya abierto.
/// Lanza [UnimplementedError] si se usa sin override (protecciÃ³n en tests).
final hiveBoxProvider = Provider<Box<GarmentModel>>(
  (ref) => throw UnimplementedError(
    'hiveBoxProvider debe ser sobreescrito en ProviderScope con el box abierto.',
  ),
  name: 'hiveBoxProvider',
);

/// Carpeta permanente de fotos. Se sobreescribe en [main.dart] con su ruta real.
final garmentImageStorageProvider = Provider<GarmentImageStorage>(
  (ref) => throw UnimplementedError(
    'garmentImageStorageProvider debe ser sobreescrito en ProviderScope.',
  ),
  name: 'garmentImageStorageProvider',
);

/// Mapper bidireccional â€” sin estado, singleton.
final garmentMapperProvider = Provider<GarmentMapper>(
  (_) => const GarmentMapper(),
  name: 'garmentMapperProvider',
);

/// DataSource que encapsula las operaciones CRUD de Hive.
final garmentDataSourceProvider = Provider<HiveGarmentDataSource>(
  (ref) => HiveGarmentDataSource(ref.read(hiveBoxProvider)),
  name: 'garmentDataSourceProvider',
);

/// ImplementaciÃ³n concreta del repositorio.
final garmentRepositoryProvider = Provider<IGarmentRepository>(
  (ref) => GarmentRepositoryImpl(
    dataSource: ref.read(garmentDataSourceProvider),
    mapper: ref.read(garmentMapperProvider),
  ),
  name: 'garmentRepositoryProvider',
);

// â”€â”€ Capa de Dominio â€” Use Cases â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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


final updateGarmentUseCaseProvider = Provider<UpdateGarmentUseCase>(
  (ref) => UpdateGarmentUseCase(ref.read(garmentRepositoryProvider)),
  name: 'updateGarmentUseCaseProvider',
);
