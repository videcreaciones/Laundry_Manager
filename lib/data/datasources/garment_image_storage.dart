/// Guarda las fotos de las prendas en una carpeta permanente de la app.
///
/// image_picker devuelve rutas en la caché, que Android puede vaciar en
/// cualquier momento; por eso cada foto se copia aquí antes de guardarse.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class GarmentImageStorage {
  final Directory _imagesDir;
  const GarmentImageStorage(this._imagesDir);

  bool _isOwned(String path) => p.isWithin(_imagesDir.path, path);

  /// Copia [path] a la carpeta de fotos y devuelve la nueva ruta.
  /// Si ya está en la carpeta, o el archivo no existe, devuelve [path] tal cual.
  Future<String?> persist(String? path) async {
    if (path == null || _isOwned(path)) return path;
    final source = File(path);
    if (!await source.exists()) return path;

    await _imagesDir.create(recursive: true);
    final extension = p.extension(path).isEmpty ? '.jpg' : p.extension(path);
    final target = p.join(_imagesDir.path, '${const Uuid().v4()}$extension');
    await source.copy(target);
    return target;
  }

  /// Borra una foto, solo si pertenece a la carpeta de la app.
  Future<void> delete(String? path) async {
    if (path == null || !_isOwned(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Una foto que no se pudo borrar no debe impedir la operación.
    }
  }
}
