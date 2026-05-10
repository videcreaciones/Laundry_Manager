library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

final class GarmentMapper {
  const GarmentMapper();

  Either<GarmentFailure, GarmentEntity> toEntity(GarmentModel model) {
    if (model.statusIndex < 0 ||
        model.statusIndex >= GarmentStatus.values.length) {
      return Left(GarmentFailureStorageError(
        'statusIndex invalido (${model.statusIndex}) para "${model.id}".',
      ));
    }
    return Right(GarmentEntity.fromPersistence(
      id:         model.id,
      name:       model.name,
      owner:      model.owner,
      status:     GarmentStatus.values[model.statusIndex],
      imagePath:  model.imagePath,
      notes:      model.notes,
      categoryId: model.categoryId,
      createdAt:  model.createdAt,
      updatedAt:  model.updatedAt,
    ));
  }

  GarmentModel toModel(GarmentEntity entity) {
    return GarmentModel(
      id:          entity.id,
      name:        entity.name,
      owner:       entity.owner,
      statusIndex: entity.status.index,
      imagePath:   entity.imagePath,
      createdAt:   entity.createdAt,
      updatedAt:   entity.updatedAt,
      notes:       entity.notes,
      categoryId:  entity.categoryId,
    );
  }
}
