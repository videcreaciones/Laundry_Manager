/// Modelo de persistencia de Hive para una prenda.
///
/// Este archivo reemplaza lo que normalmente generaría `hive_generator`.
/// El adaptador está escrito a mano para evitar el conflicto de versiones
/// entre `hive_generator` y `riverpod_generator` (incompatibilidad de
/// `source_gen`).
///
/// Campos persistidos:
///   Field 0 → id          (String)
///   Field 1 → name        (String)
///   Field 2 → owner       (String)
///   Field 3 → statusIndex (int)   — índice del enum GarmentStatus
///   Field 4 → imagePath   (String?)
///   Field 5 → createdAt   (DateTime)
///   Field 6 → updatedAt   (DateTime)
///   Field 7 → notes       (String?)
///
/// Restricciones de diseño:
/// - Este archivo SÍ puede importar hive/ (es capa de datos).
/// - NO importa clases del dominio directamente; el mapper hace la traducción.
library;

import 'package:hive_flutter/hive_flutter.dart';

part 'garment_model.g.dart';

/// Identificador del tipo Hive. Debe ser único en toda la app.
/// Reservamos el 0 para GarmentModel.
const int kGarmentModelTypeId = 0;

/// Nombre del Box de Hive donde se almacenan todas las prendas.
/// Centralizado aquí para evitar strings mágicos dispersos en el código.
const String kGarmentBoxName = 'garments';

/// Representación persistible de una prenda en Hive.
///
/// Es un objeto mutable (requerido por Hive). La inmutabilidad del dominio
/// se garantiza en [GarmentEntity], no aquí.
@HiveType(typeId: kGarmentModelTypeId)
class GarmentModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String owner;

  /// Índice del enum [GarmentStatus]. Se persiste como int para compatibilidad
  /// con versiones futuras del enum (agregar estados no rompe datos existentes
  /// mientras no se reordenen los valores).
  @HiveField(3)
  late int statusIndex;

  /// Ruta absoluta local de la foto. Null si no hay imagen (RN-03).
  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  @HiveField(7)
  String? notes;

  /// Constructor con nombre para facilitar la creación desde el mapper.
  GarmentModel({
    required this.id,
    required this.name,
    required this.owner,
    required this.statusIndex,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.notes,
  });

  @override
  String toString() {
    return 'GarmentModel(id: $id, name: "$name", statusIndex: $statusIndex)';
  }
}
