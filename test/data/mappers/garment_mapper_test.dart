/// Tests unitarios para [GarmentMapper] — cubre T-20 a T-23 del spec.md
///
/// Valida la conversión bidireccional entre [GarmentModel] y [GarmentEntity],
/// incluyendo el round-trip completo y el caso de imagePath nulo (RN-03).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/data/mappers/garment_mapper.dart';
import 'package:laundry_manager/data/models/garment_model.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

void main() {
  late GarmentMapper mapper;

  setUp(() {
    mapper = const GarmentMapper();
  });

  // ── Fixtures ──────────────────────────────────────────────────────────────

  GarmentModel buildModel({
    String id = 'model-id-001',
    String name = 'Camisa azul',
    String owner = 'Juan Pérez',
    int statusIndex = 0, // guardada
    String? imagePath = '/storage/foto.jpg',
    String? notes = 'Lavar en frío',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime(2024, 6, 15, 10, 30);
    return GarmentModel(
      id: id,
      name: name,
      owner: owner,
      statusIndex: statusIndex,
      imagePath: imagePath,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      notes: notes,
    );
  }

  GarmentEntity buildEntity({
    String id = 'entity-id-001',
    String name = 'Pantalón negro',
    String owner = 'María López',
    GarmentStatus status = GarmentStatus.lavando,
    String? imagePath = '/storage/pantalon.jpg',
    String? notes,
  }) {
    return GarmentEntity.fromPersistence(
      id: id,
      name: name,
      owner: owner,
      status: status,
      imagePath: imagePath,
      notes: notes,
      createdAt: DateTime(2024, 6, 1, 9, 0),
      updatedAt: DateTime(2024, 6, 10, 14, 0),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // T-20: toModel — Model → Entity
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentMapper.toModel —', () {
    /// T-20: Todos los campos deben mapearse correctamente de Entity a Model.
    test(
      'T-20: mapea correctamente todos los campos de Entity → Model',
      () {
        // Arrange
        final entity = buildEntity();

        // Act
        final model = mapper.toModel(entity);

        // Assert
        expect(model.id,          entity.id);
        expect(model.name,        entity.name);
        expect(model.owner,       entity.owner);
        expect(model.statusIndex, entity.status.index);
        expect(model.imagePath,   entity.imagePath);
        expect(model.notes,       entity.notes);
        expect(model.createdAt,   entity.createdAt);
        expect(model.updatedAt,   entity.updatedAt);
      },
    );

    test(
      'statusIndex corresponde al índice correcto del enum',
      () {
        for (final status in GarmentStatus.values) {
          final entity = buildEntity(status: status);
          final model = mapper.toModel(entity);
          expect(model.statusIndex, status.index);
        }
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // T-21: toEntity — Model → Entity
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentMapper.toEntity —', () {
    /// T-21: Todos los campos deben mapearse correctamente de Model a Entity.
    test(
      'T-21: mapea correctamente todos los campos de Model → Entity',
      () {
        // Arrange
        final model = buildModel();

        // Act
        final result = mapper.toEntity(model);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Se esperaba Right'),
          (entity) {
            expect(entity.id,        model.id);
            expect(entity.name,      model.name);
            expect(entity.owner,     model.owner);
            expect(entity.status,    GarmentStatus.values[model.statusIndex]);
            expect(entity.imagePath, model.imagePath);
            expect(entity.notes,     model.notes);
            expect(entity.createdAt, model.createdAt);
            expect(entity.updatedAt, model.updatedAt);
          },
        );
      },
    );

    test(
      'statusIndex 0 → guardada, 1 → lavando, 2 → devuelta',
      () {
        for (int i = 0; i < GarmentStatus.values.length; i++) {
          final model = buildModel(statusIndex: i);
          final result = mapper.toEntity(model);
          result.fold(
            (_) => fail('Se esperaba Right para statusIndex $i'),
            (entity) => expect(entity.status, GarmentStatus.values[i]),
          );
        }
      },
    );

    test(
      'statusIndex inválido (-1) → Left<GarmentFailureStorageError>',
      () {
        final model = buildModel(statusIndex: -1);
        final result = mapper.toEntity(model);
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<GarmentFailureStorageError>()),
          (_) => fail('Se esperaba Left'),
        );
      },
    );

    test(
      'statusIndex inválido (99) → Left<GarmentFailureStorageError>',
      () {
        final model = buildModel(statusIndex: 99);
        final result = mapper.toEntity(model);
        expect(result.isLeft(), isTrue);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // T-22: Round-trip Entity → Model → Entity
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentMapper round-trip —', () {
    /// T-22: El round-trip toEntity(toModel(entity)) debe preservar todos
    /// los campos sin pérdida ni transformación.
    test(
      'T-22: round-trip toEntity(toModel(entity)) preserva todos los campos',
      () {
        // Arrange
        final original = buildEntity();

        // Act
        final model = mapper.toModel(original);
        final result = mapper.toEntity(model);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Se esperaba Right en round-trip'),
          (restored) {
            expect(restored.id,        original.id);
            expect(restored.name,      original.name);
            expect(restored.owner,     original.owner);
            expect(restored.status,    original.status);
            expect(restored.imagePath, original.imagePath);
            expect(restored.notes,     original.notes);
            expect(restored.createdAt, original.createdAt);
            expect(restored.updatedAt, original.updatedAt);
          },
        );
      },
    );

    test(
      'round-trip para los 3 estados del enum preserva el status correctamente',
      () {
        for (final status in GarmentStatus.values) {
          final original = buildEntity(status: status);
          final restored = mapper.toEntity(mapper.toModel(original));
          restored.fold(
            (_) => fail('Round-trip falló para status $status'),
            (entity) => expect(entity.status, status),
          );
        }
      },
    );

    // ── T-23: imagePath nulo sobrevive el round-trip ──────────────────────

    /// T-23: imagePath = null debe sobrevivir Model → Entity → Model sin error.
    test(
      'T-23: imagePath nulo sobrevive el round-trip sin error (RN-03)',
      () {
        // Arrange — entity sin foto
        final original = buildEntity(imagePath: null);

        // Act
        final model = mapper.toModel(original);
        final result = mapper.toEntity(model);

        // Assert
        expect(model.imagePath, isNull); // model también debe tener null
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Se esperaba Right'),
          (entity) => expect(entity.imagePath, isNull),
        );
      },
    );

    test(
      'notes nulo sobrevive el round-trip sin error',
      () {
        final original = buildEntity(notes: null);
        final result = mapper.toEntity(mapper.toModel(original));
        result.fold(
          (_) => fail('Se esperaba Right'),
          (entity) => expect(entity.notes, isNull),
        );
      },
    );
  });
}
