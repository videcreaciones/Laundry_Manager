library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/datasources/hive_garment_datasource.dart';
import 'package:laundry_manager/data/mappers/garment_mapper.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/data/repositories/garment_repository_impl.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

void main() {
  late Box<GarmentModel> box;
  late GarmentRepositoryImpl repository;
  const boxName = 'garments_test';

  setUpAll(() async {
    Hive.init('.');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GarmentModelAdapter());
    }
  });

  setUp(() async {
    box = await Hive.openBox<GarmentModel>(boxName);
    await box.clear();
    repository = GarmentRepositoryImpl(
      dataSource: HiveGarmentDataSource(box),
      mapper: const GarmentMapper(),
    );
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  tearDownAll(() async {
    await Hive.deleteBoxFromDisk(boxName);
  });

  GarmentEntity buildEntity({
    String id = 'prenda-001',
    String name = 'Camisa blanca',
    String owner = 'Carlos',
    GarmentStatus status = GarmentStatus.guardada,
    String? imagePath,
  }) {
    return GarmentEntity.fromPersistence(
      id: id, name: name, owner: owner, status: status,
      imagePath: imagePath,
      createdAt: DateTime(2024, 1, 10, 8, 0),
      updatedAt: DateTime(2024, 1, 10, 8, 0),
    );
  }

  group('save —', () {
    test('T-24: save() persiste la prenda en el box', () async {
      final entity = buildEntity();
      final result = await repository.save(entity);
      expect(result.isRight(), isTrue);
      expect(box.containsKey(entity.id), isTrue);
      expect(box.get(entity.id)?.name, entity.name);
      expect(box.get(entity.id)?.statusIndex, entity.status.index);
    });

    test('save() de dos prendas distintas persiste ambas', () async {
      await repository.save(buildEntity(id: 'p-001', name: 'Camisa'));
      await repository.save(buildEntity(id: 'p-002', name: 'Pantalon'));
      expect(box.length, 2);
    });
  });

  group('getAll —', () {
    test('T-25: getAll() retorna lista vacia cuando no hay prendas', () async {
      final result = await repository.getAll();
      result.fold((_) => fail('Right esperado'), (list) => expect(list, isEmpty));
    });

    test('getAll() retorna todas las prendas guardadas', () async {
      await repository.save(buildEntity(id: 'p-001', name: 'Camisa'));
      await repository.save(buildEntity(id: 'p-002', name: 'Pantalon'));
      await repository.save(buildEntity(id: 'p-003', name: 'Abrigo'));
      final result = await repository.getAll();
      result.fold((_) => fail('Right esperado'), (list) => expect(list.length, 3));
    });

    test('getAll() ordena por createdAt descendente (D-06)', () async {
      final older = GarmentEntity.fromPersistence(
        id: 'p-old', name: 'Vieja', owner: 'A', status: GarmentStatus.guardada,
        createdAt: DateTime(2024, 1, 1), updatedAt: DateTime(2024, 1, 1),
      );
      final newer = GarmentEntity.fromPersistence(
        id: 'p-new', name: 'Nueva', owner: 'B', status: GarmentStatus.guardada,
        createdAt: DateTime(2024, 6, 1), updatedAt: DateTime(2024, 6, 1),
      );
      await repository.save(older);
      await repository.save(newer);
      final result = await repository.getAll();
      result.fold(
        (_) => fail('Right esperado'),
        (list) { expect(list.first.id, 'p-new'); expect(list.last.id, 'p-old'); },
      );
    });
  });

  group('updateStatus —', () {
    test('T-26: updateStatus() actualiza estado sin alterar otros campos', () async {
      final entity = buildEntity(id: 'p-001', name: 'Camisa', imagePath: '/foto.jpg');
      await repository.save(entity);
      final result = await repository.updateStatus('p-001', GarmentStatus.lavando);
      expect(result.isRight(), isTrue);
      final stored = box.get('p-001')!;
      expect(stored.statusIndex, GarmentStatus.lavando.index);
      expect(stored.name, entity.name);
      expect(stored.imagePath, entity.imagePath);
    });

    test('T-29: updateStatus() con ID inexistente retorna Left<GarmentFailureNotFound>', () async {
      final result = await repository.updateStatus('no-existe', GarmentStatus.lavando);
      result.fold((f) => expect(f, isA<GarmentFailureNotFound>()), (_) => fail('Left esperado'));
    });
  });

  group('delete —', () {
    test('T-27: delete() elimina la prenda del box', () async {
      final entity = buildEntity();
      await repository.save(entity);
      final result = await repository.delete(entity.id);
      expect(result.isRight(), isTrue);
      expect(box.containsKey(entity.id), isFalse);
    });

    test('delete() con ID inexistente retorna Left<GarmentFailureNotFound>', () async {
      final result = await repository.delete('fantasma');
      result.fold((f) => expect(f, isA<GarmentFailureNotFound>()), (_) => fail('Left esperado'));
    });

    test('delete() no afecta otras prendas', () async {
      await repository.save(buildEntity(id: 'p-001', name: 'Camisa'));
      await repository.save(buildEntity(id: 'p-002', name: 'Pantalon'));
      await repository.delete('p-001');
      expect(box.containsKey('p-001'), isFalse);
      expect(box.containsKey('p-002'), isTrue);
    });
  });

  group('integridad —', () {
    test('flujo: save -> updateStatus -> getAll refleja nuevo estado', () async {
      final entity = buildEntity(status: GarmentStatus.guardada);
      await repository.save(entity);
      await repository.updateStatus(entity.id, GarmentStatus.lavando);
      final result = await repository.getAll();
      result.fold(
        (_) => fail('Right esperado'),
        (list) => expect(list.firstWhere((e) => e.id == entity.id).status, GarmentStatus.lavando),
      );
    });
  });
}
