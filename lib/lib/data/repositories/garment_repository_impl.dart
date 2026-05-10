library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/data/datasources/hive_garment_datasource.dart';
import 'package:laundry_manager/data/mappers/garment_mapper.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

final class GarmentRepositoryImpl implements IGarmentRepository {
  final HiveGarmentDataSource _dataSource;
  final GarmentMapper _mapper;

  const GarmentRepositoryImpl({
    required HiveGarmentDataSource dataSource,
    required GarmentMapper mapper,
  })  : _dataSource = dataSource,
        _mapper = mapper;

  @override
  Future<Either<GarmentFailure, List<GarmentEntity>>> getAll() async {
    try {
      final models = _dataSource.getAll();
      final entities = <GarmentEntity>[];
      for (final model in models) {
        final result = _mapper.toEntity(model);
        if (result.isLeft()) {
          return Left(result.fold((f) => f, (_) => throw StateError('unreachable')));
        }
        entities.add(result.getOrElse((_) => throw StateError('unreachable')));
      }
      const statusOrder = {
        GarmentStatus.lavando: 0,
        GarmentStatus.devuelta: 1,
        GarmentStatus.guardada: 2,
      };
      entities.sort((a, b) {
        final statusCompare = statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
        if (statusCompare != 0) return statusCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      return Right(entities);
    } catch (e) {
      return Left(GarmentFailureStorageError('Error al leer prendas: $e'));
    }
  }

  @override
  Future<Either<GarmentFailure, Unit>> save(GarmentEntity garment) async {
    try {
      final model = _mapper.toModel(garment);
      await _dataSource.save(model);
      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError('Error al guardar "${garment.name}": $e'));
    }
  }

  @override
  Future<Either<GarmentFailure, Unit>> update(GarmentEntity garment) async {
    try {
      if (!_dataSource.containsKey(garment.id)) {
        return Left(GarmentFailureNotFound(garment.id));
      }
      final model = _mapper.toModel(garment);
      await _dataSource.save(model);
      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError('Error al actualizar "${garment.name}": $e'));
    }
  }

  @override
  Future<Either<GarmentFailure, Unit>> updateStatus(String id, GarmentStatus newStatus) async {
    try {
      final updated = await _dataSource.updateStatus(id, newStatus.index, DateTime.now());
      if (!updated) return Left(GarmentFailureNotFound(id));
      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError('Error al actualizar estado "$id": $e'));
    }
  }

  @override
  Future<Either<GarmentFailure, Unit>> delete(String id) async {
    try {
      final deleted = await _dataSource.delete(id);
      if (!deleted) return Left(GarmentFailureNotFound(id));
      return const Right(unit);
    } catch (e) {
      return Left(GarmentFailureStorageError('Error al eliminar "$id": $e'));
    }
  }

  @override
  Future<void> close() async => _dataSource.close();
}
