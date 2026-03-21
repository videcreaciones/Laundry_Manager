library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

final class GarmentEntity {
  final String id;
  final String name;
  final String owner;
  final GarmentStatus status;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? categoryId; // NUEVO — opcional

  const GarmentEntity._({
    required this.id,
    required this.name,
    required this.owner,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.notes,
    this.categoryId,
  });

  static Either<GarmentFailure, GarmentEntity> create({
    required String id,
    required String name,
    required String owner,
    GarmentStatus status = GarmentStatus.guardada,
    String? imagePath,
    String? notes,
    String? categoryId,
    DateTime? createdAt,
  }) {
    if (name.trim().isEmpty) {
      return Left(const GarmentFailureValidationError(
        field: 'name', message: 'El nombre de la prenda es requerido.'));
    }
    if (owner.trim().isEmpty) {
      return Left(const GarmentFailureValidationError(
        field: 'owner', message: 'El nombre del propietario es requerido.'));
    }
    final now = createdAt ?? DateTime.now();
    return Right(GarmentEntity._(
      id: id, name: name.trim(), owner: owner.trim(),
      status: status, imagePath: imagePath,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      categoryId: categoryId,
      createdAt: now, updatedAt: now,
    ));
  }

  static GarmentEntity fromPersistence({
    required String id,
    required String name,
    required String owner,
    required GarmentStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? imagePath,
    String? notes,
    String? categoryId,
  }) {
    return GarmentEntity._(
      id: id, name: name, owner: owner, status: status,
      imagePath: imagePath, notes: notes, categoryId: categoryId,
      createdAt: createdAt, updatedAt: updatedAt,
    );
  }

  GarmentEntity copyWithStatus(GarmentStatus newStatus) {
    return GarmentEntity._(
      id: id, name: name, owner: owner, status: newStatus,
      imagePath: imagePath, notes: notes, categoryId: categoryId,
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GarmentEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GarmentEntity(id: $id, name: "$name", status: ${status.displayLabel})';
}
