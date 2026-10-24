import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_manager/data/datasources/garment_image_storage.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory imagesDir;
  late GarmentImageStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('garment_images_test');
    imagesDir = Directory(p.join(root.path, 'garment_images'));
    storage = GarmentImageStorage(imagesDir);
  });

  tearDown(() => root.delete(recursive: true));

  Future<File> cacheImage() async {
    final file = File(p.join(root.path, 'cache', 'picked.jpg'));
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    return file;
  }

  test('persist copia la foto de la caché a la carpeta permanente', () async {
    final source = await cacheImage();

    final stored = await storage.persist(source.path);

    expect(stored, isNotNull);
    expect(p.isWithin(imagesDir.path, stored!), isTrue);
    expect(await File(stored).readAsBytes(), [1, 2, 3]);
    await source.delete();
    expect(await File(stored).exists(), isTrue);
  });

  test('persist no vuelve a copiar una foto que ya está guardada', () async {
    final stored = await storage.persist((await cacheImage()).path);

    expect(await storage.persist(stored), stored);
    expect(imagesDir.listSync(), hasLength(1));
  });

  test('persist deja igual una ruta nula o que no existe', () async {
    expect(await storage.persist(null), isNull);
    final missing = p.join(root.path, 'no_existe.jpg');
    expect(await storage.persist(missing), missing);
  });

  test('delete borra solo fotos de la carpeta de la app', () async {
    final source = await cacheImage();
    final stored = await storage.persist(source.path);

    await storage.delete(source.path);
    await storage.delete(stored);

    expect(await source.exists(), isTrue);
    expect(await File(stored!).exists(), isFalse);
  });
}
