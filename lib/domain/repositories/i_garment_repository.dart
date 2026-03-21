library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

abstract interface class IGarmentRepository {
  Future<Either<GarmentFailure, List<GarmentEntity>>> getAll();
  Future<Either<GarmentFailure, Unit>> save(GarmentEntity garment);
  Future<Either<GarmentFailure, Unit>> update(GarmentEntity garment);
  Future<Either<GarmentFailure, Unit>> updateStatus(String id, GarmentStatus newStatus);
  Future<Either<GarmentFailure, Unit>> delete(String id);
  Future<void> close();
}
