/// Use case: cambiar el estado de una prenda existente.
///
/// Este es el use case más crítico del dominio — aplica RN-01:
/// la transición debe ser secuencial (guardada→lavando→devuelta)
/// sin saltos ni retrocesos.
///
/// Restricciones de diseño (Clean Architecture):
/// - Valida la transición ANTES de llamar al repositorio.
/// - Si la transición es inválida, el repositorio nunca es contactado.
/// - NO importa flutter/, hive/, ni riverpod/.
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Actualiza el estado de una prenda respetando las reglas de transición (RN-01).
///
/// Flujo:
/// 1. Valida que [from] puede transicionar a [to] con [GarmentStatus.canTransitionTo].
/// 2. Si la transición es inválida → retorna [GarmentFailureInvalidTransition] SIN
///    llamar al repositorio.
/// 3. Si es válida → delega la actualización al repositorio.
final class UpdateGarmentStatusUseCase {
  final IGarmentRepository _repository;

  const UpdateGarmentStatusUseCase(this._repository);

  /// Ejecuta el caso de uso.
  ///
  /// Parámetros:
  /// - [id]: ID de la prenda a actualizar.
  /// - [from]: Estado actual de la prenda (necesario para validar RN-01).
  /// - [to]: Estado al que se quiere transicionar.
  ///
  /// Retorna `Right<Unit>` si la transición es válida y se persistió.
  /// Retorna `Left<GarmentFailureInvalidTransition>` si viola RN-01.
  /// Retorna `Left<GarmentFailureNotFound>` si el ID no existe.
  /// Retorna `Left<GarmentFailureStorageError>` ante fallo de Hive.
  Future<Either<GarmentFailure, Unit>> execute({
    required String id,
    required GarmentStatus from,
    required GarmentStatus to,
  }) async {
    // 1. Validar la transición (RN-01) — sin tocar el repositorio
    if (!from.canTransitionTo(to)) {
      return Left(
        GarmentFailureInvalidTransition(from: from, to: to),
      );
    }

    // 2. Transición válida — delegar al repositorio
    return _repository.updateStatus(id, to);
  }
}
