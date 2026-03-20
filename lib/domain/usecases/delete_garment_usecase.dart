/// Use case: eliminar una prenda del sistema.
///
/// Aplica RN-02: no se puede eliminar una prenda que está en estado LAVANDO.
/// Si el estado es LAVANDO → retorna error SIN contactar el repositorio.
///
/// Restricciones de diseño (Clean Architecture):
/// - Valida RN-02 ANTES de llamar al repositorio.
/// - NO importa flutter/, hive/, ni riverpod/.
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Elimina permanentemente una prenda respetando RN-02.
///
/// Flujo:
/// 1. Verifica que el estado actual NO sea [GarmentStatus.lavando].
/// 2. Si es LAVANDO → retorna [GarmentFailureDeletionForbidden] SIN llamar
///    al repositorio.
/// 3. Si el estado permite borrado → delega al repositorio.
final class DeleteGarmentUseCase {
  final IGarmentRepository _repository;

  const DeleteGarmentUseCase(this._repository);

  /// Ejecuta el caso de uso.
  ///
  /// Parámetros:
  /// - [id]: ID de la prenda a eliminar.
  /// - [currentStatus]: Estado actual de la prenda (para validar RN-02).
  ///   Se recibe como parámetro para evitar una lectura extra al repositorio.
  ///
  /// Retorna `Right<Unit>` si el borrado fue exitoso.
  /// Retorna `Left<GarmentFailureDeletionForbidden>` si está en LAVANDO (RN-02).
  /// Retorna `Left<GarmentFailureNotFound>` si el ID no existe.
  /// Retorna `Left<GarmentFailureStorageError>` ante fallo de Hive.
  Future<Either<GarmentFailure, Unit>> execute({
    required String id,
    required GarmentStatus currentStatus,
  }) async {
    // 1. Validar RN-02 — sin tocar el repositorio
    if (currentStatus == GarmentStatus.lavando) {
      return Left(
        GarmentFailureDeletionForbidden(
          'La prenda con ID "$id" está en proceso de lavado '
          'y no puede ser eliminada (RN-02).',
        ),
      );
    }

    // 2. Estado permitido — delegar al repositorio
    return _repository.delete(id);
  }
}
