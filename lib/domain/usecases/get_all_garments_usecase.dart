/// Use case: recuperar todas las prendas persistidas.
///
/// Es el caso de uso más simple — delega directamente al repositorio
/// sin lógica de negocio adicional. El ordenamiento es responsabilidad
/// del repositorio (D-06: createdAt descendente).
///
/// Restricciones de diseño (Clean Architecture):
/// - Solo importa contratos e interfaces del dominio.
/// - NO importa flutter/, hive/, ni riverpod/.
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';

/// Recupera la lista completa de prendas desde el almacenamiento local.
///
/// Retorna `Right<List<GarmentEntity>>` (lista vacía si no hay prendas).
/// Retorna `Left<GarmentFailure>` si ocurre un error de almacenamiento.
final class GetAllGarmentsUseCase {
  final IGarmentRepository _repository;

  const GetAllGarmentsUseCase(this._repository);

  /// Ejecuta el caso de uso.
  Future<Either<GarmentFailure, List<GarmentEntity>>> execute() {
    return _repository.getAll();
  }
}
