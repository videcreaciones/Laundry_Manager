library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';

final class UpdateGarmentUseCase {
  final IGarmentRepository _repository;
  const UpdateGarmentUseCase(this._repository);

  Future<Either<GarmentFailure, GarmentEntity>> execute({
    required GarmentEntity original,
    required String name,
    required String owner,
    String? imagePath,
    String? notes,
    String? categoryId,
  }) async {
    if (name.trim().isEmpty) {
      return Left(const GarmentFailureValidationError(
        field: 'name', message: 'El nombre es requerido.'));
    }
    if (owner.trim().isEmpty) {
      return Left(const GarmentFailureValidationError(
        field: 'owner', message: 'El propietario es requerido.'));
    }

    final updated = GarmentEntity.fromPersistence(
      id:         original.id,
      name:       name.trim(),
      owner:      owner.trim(),
      status:     original.status,
      imagePath:  imagePath,
      notes:      notes?.trim().isEmpty == true ? null : notes?.trim(),
      categoryId: categoryId,   // ← persiste el nuevo valor (puede ser null)
      createdAt:  original.createdAt,
      updatedAt:  DateTime.now(),
    );

    final result = await _repository.update(updated);
    return result.fold(Left.new, (_) => Right(updated));
  }
}
