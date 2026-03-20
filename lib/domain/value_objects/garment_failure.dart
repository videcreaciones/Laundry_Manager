/// Tipos de error del dominio para el contexto de Laundry Manager.
///
/// Restricciones de diseño (Clean Architecture):
/// - Este archivo NO importa flutter/, hive/, ni riverpod/.
/// - Al ser una `sealed class`, el compilador de Dart obliga al consumidor
///   a manejar TODOS los casos en un switch exhaustivo.
/// - Las implementaciones internas son privadas; el consumidor solo accede
///   a través de los constructores factory nombrados.
library;

import 'package:laundry_manager/domain/value_objects/garment_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SEALED CLASS — GarmentFailure
//
// Uso con Either (fpdart):
//   Either<GarmentFailure, GarmentEntity> result = ...;
//   result.fold(
//     (failure) => switch (failure) {
//       GarmentFailureNotFound()        => ...,
//       GarmentFailureInvalidTransition() => ...,
//       GarmentFailureDeletionForbidden() => ...,
//       GarmentFailureStorageError()    => ...,
//       GarmentFailureValidationError() => ...,
//       GarmentFailureImagePickerError()=> ...,
//     },
//     (entity) => ...,
//   );
// ─────────────────────────────────────────────────────────────────────────────

/// Clase base sellada para todos los errores del dominio de lavandería.
///
/// Usar en combinación con `Either<GarmentFailure, T>` de fpdart para
/// modelar resultados que pueden fallar sin lanzar excepciones.
sealed class GarmentFailure {
  const GarmentFailure();
}

// ── Implementaciones ─────────────────────────────────────────────────────────

/// El ID solicitado no existe en la base de datos local.
///
/// Se produce en operaciones de `get`, `updateStatus` o `delete`
/// cuando el ID no está en el Box de Hive.
final class GarmentFailureNotFound extends GarmentFailure {
  /// ID que no pudo ser encontrado.
  final String id;

  const GarmentFailureNotFound(this.id);

  @override
  String toString() => 'GarmentFailure.notFound: ID "$id" no existe.';
}

/// La transición de estado solicitada viola RN-01.
///
/// Ocurre cuando se intenta un cambio de estado no secuencial
/// (ej: guardada → devuelta) o un retroceso (ej: lavando → guardada).
final class GarmentFailureInvalidTransition extends GarmentFailure {
  /// Estado origen de la transición inválida.
  final GarmentStatus from;

  /// Estado destino que fue solicitado pero no está permitido.
  final GarmentStatus to;

  const GarmentFailureInvalidTransition({
    required this.from,
    required this.to,
  });

  @override
  String toString() =>
      'GarmentFailure.invalidTransition: '
      '"${from.displayLabel}" → "${to.displayLabel}" no está permitido (RN-01).';
}

/// Intento de eliminar una prenda que está actualmente en estado LAVANDO.
///
/// Protege RN-02: una prenda en proceso no puede ser eliminada del sistema.
final class GarmentFailureDeletionForbidden extends GarmentFailure {
  /// Descripción del motivo por el cual el borrado fue rechazado.
  final String reason;

  const GarmentFailureDeletionForbidden(this.reason);

  @override
  String toString() => 'GarmentFailure.deletionForbidden: $reason (RN-02).';
}

/// Fallo genérico de la base de datos local (Hive).
///
/// Agrupa cualquier excepción originada en las operaciones de Hive
/// que no pueda ser clasificada de forma más específica.
final class GarmentFailureStorageError extends GarmentFailure {
  /// Mensaje de error original del sistema de almacenamiento.
  final String message;

  const GarmentFailureStorageError(this.message);

  @override
  String toString() => 'GarmentFailure.storageError: $message';
}

/// Los datos de la entidad no superan la validación del dominio (RN-04).
///
/// Se produce en `GarmentEntity.create()` cuando `name` u `owner`
/// están vacíos o contienen solo espacios.
final class GarmentFailureValidationError extends GarmentFailure {
  /// Nombre del campo que falló la validación (ej: `'name'`, `'owner'`).
  final String field;

  /// Descripción legible del error de validación.
  final String message;

  const GarmentFailureValidationError({
    required this.field,
    required this.message,
  });

  @override
  String toString() =>
      'GarmentFailure.validationError: campo "$field" → $message (RN-04).';
}

/// La selección de imagen falló por permisos, cancelación u otro error.
///
/// Según RN-03, este fallo NO impide guardar la prenda.
/// Se usa para informar al usuario, pero la operación de guardado continúa
/// con `imagePath = null`.
final class GarmentFailureImagePickerError extends GarmentFailure {
  /// Mensaje de error del sistema al intentar acceder a la galería.
  final String message;

  const GarmentFailureImagePickerError(this.message);

  @override
  String toString() => 'GarmentFailure.imagePickerError: $message (RN-03).';
}
