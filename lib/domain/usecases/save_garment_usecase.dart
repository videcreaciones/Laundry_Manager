library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:uuid/uuid.dart';

final class SaveGarmentUseCase {
  final IGarmentRepository _repository;
  final String? _fixedIdForTesting;

  const SaveGarmentUseCase(
    this._repository, {
    String? fixedIdForTesting,
  }) : _fixedIdForTesting = fixedIdForTesting;

  Future<Either<GarmentFailure, GarmentEntity>> execute({
    required String name,
    required String owner,
    String? imagePath,
    String? notes,
  }) async {
    final id = _fixedIdForTesting ?? const Uuid().v4();
    final entityResult = GarmentEntity.create(
      id: id, name: name, owner: owner, imagePath: imagePath, notes: notes,
    );
    if (entityResult.isLeft()) return entityResult;
    final entity = entityResult.getOrElse((_) => throw StateError('unreachable'));
    final saveResult = await _repository.save(entity);
    return saveResult.fold(Left.new, (_) => Right(entity));
  }
}
