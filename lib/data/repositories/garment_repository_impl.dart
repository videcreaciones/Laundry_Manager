/// Implementación concreta de [IGarmentRepository] usando Hive como
/// mecanismo de persistencia local.
///
/// Responsabilidades:
/// - Orquestar [HiveGarmentDataSource] y [GarmentMapper].
/// - Capturar excepciones de Hive y traducirlas a [GarmentFailure].
/// - Aplicar el ordenamiento por [GarmentEntity.createdAt] descendente (D-06).
/// - Validar precondiciones que el use case haya delegado (ej: existencia del ID).
///
/// Restricciones de diseño:
/// - SÍ importa hive/, datasource y mapper (es capa de datos).
/// - Implementa [IGarmentRepository] — contrato del dominio.
/// - NO contiene lógica de negocio (ej: no valida transiciones de estado).
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/data/datasources/hive_garment_datasource.dart';
import 'package:laundry_manager/data/mappers/garment_mapper.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Implementación de [IGarmentRepository] con Hive como backend.
final class GarmentRepositoryImpl implements IGarmentRepository {
  final HiveGarmentDataSource _dataSource;
  final GarmentMapper _mapper;

  const GarmentRepositoryImpl({
    required HiveGarmentDataSource dataSource,
    required GarmentMapper mapper,
  })  : _dataSource = dataSource,
        _mapper = mapper;

  // ── getAll ────────────────────────────────────────────────────────────────

  @override
  Future<Either<GarmentFailure, List<GarmentEntity>>> getAll() async {
    try {
      final models = _dataSource.getAll();

      // Mapear cada modelo a entidad, acumulando errores si los hay
      final entities = <GarmentEntity>[];
      for (final model in models) {
        final result = _mapper.toEntity(model);
        // Si un modelo tiene datos corruptos, fallamos rápido (fail-fast)
        if (result.isLeft()) {
          return Left(
            result.fold((f) => f, (_) => throw StateError('unreachable')),
          );
        }
        entities.add(result.getOrElse((_) => throw StateError('unreachable')));
      }

      // Ordenar por createdAt descendente (D-06: más reciente primero)
      entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(entities);
    } catch (e) {
      return Left(GarmentFailureStorageError(
        'Error al leer prendas de la base de datos: $e',
      ));
    }
  }

  // ── save ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<GarmentFailure, Unit>> save(GarmentEntity garment) async {
    try {
      final model = _mapper.toModel(garment);
      await _dataSource.save(model);
      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError(
        'Error al guardar la prenda "${garment.name}": $e',
      ));
    }
  }

  // ── updateStatus ──────────────────────────────────────────────────────────

  @override
  Future<Either<GarmentFailure, Unit>> updateStatus(
    String id,
    GarmentStatus newStatus,
  ) async {
    try {
      final updated = await _dataSource.updateStatus(
        id,
        newStatus.index,
        DateTime.now(),
      );

      if (!updated) {
        return Left(GarmentFailureNotFound(id));
      }

      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError(
        'Error al actualizar estado de la prenda "$id": $e',
      ));
    }
  }

  // ── delete ────────────────────────────────────────────────────────────────

  @override
  Future<Either<GarmentFailure, Unit>> delete(String id) async {
    try {
      final deleted = await _dataSource.delete(id);

      if (!deleted) {
        return Left(GarmentFailureNotFound(id));
      }

      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError(
        'Error al eliminar la prenda "$id": $e',
      ));
    }
  }

  // ── close ─────────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _dataSource.close();
  }
}
