/// Mapper bidireccional entre [GarmentModel] (capa de datos) y
/// [GarmentEntity] (capa de dominio).
///
/// Responsabilidades:
/// - Traducir el `statusIndex` (int de Hive) al enum [GarmentStatus].
/// - Traducir el enum [GarmentStatus] al `statusIndex` (int para Hive).
/// - Aislar al dominio de cualquier conocimiento de Hive.
///
/// Restricciones de diseÃ±o:
/// - Es el ÃšNICO punto del proyecto que conoce tanto el modelo como la entidad.
/// - No contiene lÃ³gica de negocio; solo traducciÃ³n de tipos.
library;

import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Convierte entre [GarmentModel] y [GarmentEntity].
///
/// Se instancia como singleton en el provider de Riverpod.
final class GarmentMapper {
  const GarmentMapper();

  // â”€â”€ Model â†’ Entity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Convierte un [GarmentModel] de Hive a un [GarmentEntity] del dominio.
  ///
  /// Retorna [Left] si el `statusIndex` almacenado no corresponde a ningÃºn
  /// valor conocido del enum (protecciÃ³n ante corrupciÃ³n de datos o migraciones
  /// de esquema incompletas).
  Either<GarmentFailure, GarmentEntity> toEntity(GarmentModel model) {
    // Validar que el statusIndex es un valor conocido del enum
    if (model.statusIndex < 0 ||
        model.statusIndex >= GarmentStatus.values.length) {
      return Left(
        GarmentFailureStorageError(
          'statusIndex invÃ¡lido (${model.statusIndex}) para la prenda '
          '"${model.id}". Posible corrupciÃ³n de datos.',
        ),
      );
    }

    final status = GarmentStatus.values[model.statusIndex];

    // GarmentEntity.create no se usa aquÃ­ porque los datos ya fueron
    // validados al momento de guardar. Usamos el constructor privado
    // a travÃ©s de create con los datos ya limpios.
    return GarmentEntity.create(
      id: model.id,
      name: model.name,
      owner: model.owner,
      status: status,
      imagePath: model.imagePath,
      notes: model.notes,
      createdAt: model.createdAt,
    ).map(
      // Sobreescribir updatedAt porque create() lo ignora (usa DateTime.now())
      // Necesitamos el valor persistido
      (entity) => _withUpdatedAt(entity, model.updatedAt),
    );
  }

  // â”€â”€ Entity â†’ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Convierte un [GarmentEntity] del dominio a un [GarmentModel] para Hive.
  ///
  /// Esta operaciÃ³n es siempre exitosa â€” si la entidad existe, el modelo
  /// puede construirse sin fallo.
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

  // â”€â”€ Helpers privados â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Aplica el [updatedAt] persistido a la entidad reciÃ©n creada.
  ///
  /// [GarmentEntity.create] siempre usa [DateTime.now()] para ambas fechas,
  /// pero al leer de Hive necesitamos restaurar el valor original.
  GarmentEntity _withUpdatedAt(GarmentEntity entity, DateTime updatedAt) {
    // copyWithStatus es el Ãºnico mÃ©todo de copia disponible, pero necesitamos
    // preservar el status. Aprovechamos que el status no cambia aquÃ­ y
    // usamos copyWithStatus con el mismo estado para obtener una nueva
    // instancia, luego aplicamos updatedAt mediante reflexiÃ³n de campos.
    //
    // Dado que GarmentEntity es final con constructor privado, la Ãºnica forma
    // de restaurar updatedAt es a travÃ©s de GarmentEntity.create con
    // createdAt fijo y luego no podemos setear updatedAt directamente.
    //
    // SoluciÃ³n: exponemos un factory adicional en GarmentEntity para
    // reconstrucciÃ³n desde persistencia. Ver nota de diseÃ±o abajo.
    //
    // NOTA DE DISEÃ‘O: Este es el Ãºnico caso en que necesitamos
    // GarmentEntity.fromPersistence. Lo agregamos como factory estÃ¡tico
    // en la entidad para cubrir este caso sin romper la inmutabilidad.
    return GarmentEntity.fromPersistence(
      id:        entity.id,
      name:      entity.name,
      owner:     entity.owner,
      status:    entity.status,
      imagePath: entity.imagePath,
      notes:     entity.notes,
      createdAt: entity.createdAt,
      updatedAt: updatedAt,
    );
  }
}


