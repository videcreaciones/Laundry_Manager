/// Entidad inmutable del dominio que representa una prenda registrada.
///
/// Restricciones de diseÃ±o (Clean Architecture):
/// - NO importa flutter/, hive/, ni riverpod/.
/// - NO importa `uuid`; el ID se recibe como parÃ¡metro desde el use case
///   que sÃ­ puede importar uuid. Esto mantiene la entidad 100% testeable
///   con IDs predecibles (decisiÃ³n HITL aprobada).
/// - La construcciÃ³n solo es posible a travÃ©s de [GarmentEntity.create],
///   que aplica las validaciones del dominio (RN-04).
/// - [copyWithStatus] es el Ãºnico mecanismo de mutaciÃ³n; retorna una nueva
///   instancia (patrÃ³n de inmutabilidad).
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Representa una prenda dentro del sistema de gestiÃ³n de lavanderÃ­a.
///
/// Siempre debe construirse con [GarmentEntity.create] para garantizar
/// que las reglas de negocio RN-04 se cumplen desde el primer momento.
final class GarmentEntity {
  // â”€â”€ Campos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Identificador Ãºnico de la prenda (UUID v4).
  final String id;

  /// Nombre descriptivo de la prenda. Requerido (RN-04).
  final String name;

  /// Nombre del propietario de la prenda. Requerido (RN-04).
  final String owner;

  /// Estado actual de la prenda en su ciclo de vida.
  final GarmentStatus status;

  /// Ruta absoluta local a la foto de la prenda.
  /// `null` si no se tomÃ³ foto o si la selecciÃ³n fallÃ³ (RN-03).
  final String? imagePath;

  /// Fecha y hora en que la prenda fue registrada en el sistema.
  final DateTime createdAt;

  /// Fecha y hora de la Ãºltima modificaciÃ³n de estado.
  final DateTime updatedAt;

  /// Notas opcionales sobre la prenda.
  final String? notes;

  // â”€â”€ Constructor privado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  const GarmentEntity._({
    required this.id,
    required this.name,
    required this.owner,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.notes,
  });

  // â”€â”€ Factory de construcciÃ³n con validaciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Crea una nueva [GarmentEntity] aplicando las validaciones del dominio.
  ///
  /// Retorna `Right<GarmentEntity>` si vÃ¡lido, `Left<GarmentFailure>` si no.
  static Either<GarmentFailure, GarmentEntity> create({
    required String id,
    required String name,
    required String owner,
    GarmentStatus status = GarmentStatus.guardada,
    String? imagePath,
    String? notes,
    DateTime? createdAt,
  }) {
    // ValidaciÃ³n RN-04: nombre requerido
    if (name.trim().isEmpty) {
      return Left(
        const GarmentFailureValidationError(
          field: 'name',
          message: 'El nombre de la prenda es requerido.',
        ),
      );
    }

    // ValidaciÃ³n RN-04: propietario requerido
    if (owner.trim().isEmpty) {
      return Left(
        const GarmentFailureValidationError(
          field: 'owner',
          message: 'El nombre del propietario es requerido.',
        ),
      );
    }

    final now = createdAt ?? DateTime.now();

    return Right(
      GarmentEntity._(
        id: id,
        name: name.trim(),
        owner: owner.trim(),
        status: status,
        imagePath: imagePath,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // â”€â”€ ReconstrucciÃ³n desde persistencia â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Reconstruye una [GarmentEntity] desde datos ya validados en persistencia.
  ///
  /// **Solo debe ser usado por [GarmentMapper]** al leer desde Hive.
  /// - No aplica `.trim()` (los datos ya fueron saneados al guardar).
  /// - Restaura [updatedAt] con el valor exacto persistido.
  /// - No valida campos (se asume que la BD tiene datos Ã­ntegros).
  static GarmentEntity fromPersistence({
    required String id,
    required String name,
    required String owner,
    required GarmentStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? imagePath,
    String? notes,
  }) {
    return GarmentEntity._(
      id: id,
      name: name,
      owner: owner,
      status: status,
      imagePath: imagePath,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // â”€â”€ MutaciÃ³n inmutable â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Retorna una nueva [GarmentEntity] con [newStatus] y [updatedAt] fresco.
  GarmentEntity copyWithStatus(GarmentStatus newStatus) {
    return GarmentEntity._(
      id: id,
      name: name,
      owner: owner,
      status: newStatus,
      imagePath: imagePath,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // â”€â”€ Igualdad y representaciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GarmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GarmentEntity('
        'id: $id, '
        'name: "$name", '
        'owner: "$owner", '
        'status: ${status.displayLabel}, '
        'imagePath: $imagePath'
        ')';
  }
}
