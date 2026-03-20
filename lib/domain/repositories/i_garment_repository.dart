/// Contrato del repositorio de prendas.
///
/// Restricciones de diseño (Clean Architecture):
/// - Este archivo NO importa hive/, flutter/ ni riverpod/.
/// - La capa de dominio solo conoce esta interfaz.
/// - La implementación concreta ([GarmentRepositoryImpl]) vive en `data/`.
///
/// Todas las operaciones retornan [Either] para modelar errores
/// sin lanzar excepciones (Railway-Oriented Programming con fpdart — D-01).
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Define las operaciones de persistencia disponibles para el dominio.
///
/// El dominio programa contra esta interfaz. Nunca depende de Hive
/// ni de ninguna otra tecnología de almacenamiento.
abstract interface class IGarmentRepository {
  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Retorna todas las prendas persistidas.
  ///
  /// La lista está ordenada por [GarmentEntity.createdAt] descendente
  /// (más reciente primero — decisión D-06 aprobada en HITL).
  ///
  /// Retorna `Right([])` si no hay prendas almacenadas (no es un error).
  Future<Either<GarmentFailure, List<GarmentEntity>>> getAll();

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Persiste una nueva prenda en el almacenamiento local.
  ///
  /// - Falla con [GarmentFailureStorageError] si Hive lanza una excepción.
  /// - Usa el [GarmentEntity.id] como clave primaria del Box.
  Future<Either<GarmentFailure, Unit>> save(GarmentEntity garment);

  // ── Actualización ─────────────────────────────────────────────────────────

  /// Actualiza únicamente el estado de una prenda existente.
  ///
  /// **Precondición:** La transición debe haber sido validada por
  /// [UpdateGarmentStatusUseCase] antes de llamar a este método.
  /// El repositorio NO valida transiciones; esa responsabilidad es del dominio.
  ///
  /// - Falla con [GarmentFailureNotFound] si el ID no existe.
  /// - Falla con [GarmentFailureStorageError] ante errores de Hive.
  Future<Either<GarmentFailure, Unit>> updateStatus(
    String id,
    GarmentStatus newStatus,
  );

  // ── Eliminación ───────────────────────────────────────────────────────────

  /// Elimina permanentemente una prenda del almacenamiento local.
  ///
  /// **Precondición:** La validación de RN-02 debe haberse ejecutado en
  /// [DeleteGarmentUseCase] antes de llamar a este método.
  ///
  /// - Falla con [GarmentFailureNotFound] si el ID no existe.
  /// - Falla con [GarmentFailureStorageError] ante errores de Hive.
  Future<Either<GarmentFailure, Unit>> delete(String id);

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  /// Libera los recursos del Box de Hive.
  ///
  /// Debe ser llamado al cerrar la aplicación, en el `dispose`
  /// del [ProviderScope] o en el `onDispose` del provider raíz.
  Future<void> close();
}
