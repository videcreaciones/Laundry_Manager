/// Fuente de datos local que encapsula todas las operaciones directas
/// sobre el [Box] de Hive para prendas.
///
/// Responsabilidades:
/// - Aislar al repositorio del API de Hive.
/// - Convertir excepciones de Hive en tipos que el repositorio pueda manejar.
/// - No conoce el dominio — trabaja exclusivamente con [GarmentModel].
///
/// Restricciones de diseño:
/// - SÍ importa hive/ (es capa de datos).
/// - NO importa entidades del dominio.
library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/models/garment_model.dart';

/// Abstracción de las operaciones CRUD sobre el Box de Hive.
///
/// Lanza [HiveError] o [Exception] ante fallos — el repositorio
/// es responsable de capturarlos y mapearlos a [GarmentFailure].
final class HiveGarmentDataSource {
  final Box<GarmentModel> _box;

  const HiveGarmentDataSource(this._box);

  // ── Lectura ───────────────────────────────────────────────────────────────

  /// Retorna todos los modelos almacenados en el Box.
  /// Lista vacía si no hay prendas.
  List<GarmentModel> getAll() {
    return _box.values.toList();
  }

  /// Retorna el modelo con la clave [id], o `null` si no existe.
  GarmentModel? getById(String id) {
    return _box.get(id);
  }

  // ── Escritura ─────────────────────────────────────────────────────────────

  /// Persiste [model] usando su [GarmentModel.id] como clave primaria.
  ///
  /// Si ya existe una entrada con ese ID, la sobreescribe.
  Future<void> save(GarmentModel model) async {
    await _box.put(model.id, model);
  }

  /// Actualiza únicamente el [statusIndex] y [updatedAt] del modelo
  /// identificado por [id].
  ///
  /// Retorna `false` si el ID no existe en el Box.
  Future<bool> updateStatus(
    String id,
    int newStatusIndex,
    DateTime updatedAt,
  ) async {
    final model = _box.get(id);
    if (model == null) return false;

    model.statusIndex = newStatusIndex;
    model.updatedAt = updatedAt;
    await model.save(); // HiveObject.save() persiste solo los campos modificados
    return true;
  }

  // ── Eliminación ───────────────────────────────────────────────────────────

  /// Elimina el modelo con clave [id] del Box.
  ///
  /// Retorna `false` si el ID no existía (operación idempotente).
  Future<bool> delete(String id) async {
    if (!_box.containsKey(id)) return false;
    await _box.delete(id);
    return true;
  }

  // ── Consultas ─────────────────────────────────────────────────────────────

  /// Retorna `true` si existe un modelo con la clave [id].
  bool containsKey(String id) => _box.containsKey(id);

  /// Número de prendas almacenadas actualmente.
  int get count => _box.length;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  /// Cierra el Box de Hive liberando sus recursos.
  Future<void> close() async {
    await _box.close();
  }
}
