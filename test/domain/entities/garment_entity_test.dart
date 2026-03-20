/// Tests unitarios para [GarmentEntity] — cubre T-01 a T-05 del spec.md
///
/// Valida el constructor factory [GarmentEntity.create] y sus reglas:
/// - RN-03: La foto es opcional; imagePath nulo es válido.
/// - RN-04: name y owner son campos requeridos (no vacíos, no solo espacios).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

/// ID fijo usado en todos los tests para garantizar determinismo.
const _testId = 'test-uuid-fixed-001';

/// Datos mínimos válidos para crear una prenda.
const _validName  = 'Camisa azul';
const _validOwner = 'Juan Pérez';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Grupo: GarmentEntity.create — Camino feliz
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentEntity.create — camino feliz —', () {
    /// T-01: La creación con datos válidos debe retornar Right<GarmentEntity>.
    test(
      'T-01: crea entidad válida con name y owner correctos → Right',
      () {
        // Act
        final result = GarmentEntity.create(
          id: _testId,
          name: _validName,
          owner: _validOwner,
        );

        // Assert
        expect(result, isA<Right<GarmentFailure, GarmentEntity>>());

        result.fold(
          (_) => fail('Se esperaba Right pero se obtuvo Left'),
          (entity) {
            expect(entity.id, _testId);
            expect(entity.name, _validName);
            expect(entity.owner, _validOwner);
            expect(entity.status, GarmentStatus.guardada); // estado inicial por defecto
          },
        );
      },
    );

    /// T-05: La foto es opcional — imagePath nulo no debe provocar error (RN-03).
    test(
      'T-05: imagePath nulo es válido (RN-03 — foto opcional)',
      () {
        // Act
        final result = GarmentEntity.create(
          id: _testId,
          name: _validName,
          owner: _validOwner,
          imagePath: null, // explícitamente nulo
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.map((entity) => expect(entity.imagePath, isNull));
      },
    );

    test(
      'estado inicial por defecto es GarmentStatus.guardada',
      () {
        final result = GarmentEntity.create(
          id: _testId,
          name: _validName,
          owner: _validOwner,
        );
        result.map(
          (entity) => expect(entity.status, GarmentStatus.guardada),
        );
      },
    );

    test(
      'name y owner se almacenan sin espacios sobrantes (trim)',
      () {
        final result = GarmentEntity.create(
          id: _testId,
          name: '  Camisa azul  ',
          owner: '  Juan Pérez  ',
        );
        result.fold(
          (_) => fail('Debería ser Right'),
          (entity) {
            expect(entity.name, 'Camisa azul');
            expect(entity.owner, 'Juan Pérez');
          },
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Grupo: GarmentEntity.create — Validaciones fallidas (RN-04)
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentEntity.create — validaciones fallidas (RN-04) —', () {
    /// T-02: name vacío debe retornar Left<GarmentFailureValidationError>.
    test(
      'T-02: name vacío → Left con field="name" (RN-04)',
      () {
        // Act
        final result = GarmentEntity.create(
          id: _testId,
          name: '',          // INVÁLIDO
          owner: _validOwner,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<GarmentFailureValidationError>());
            final validationError = failure as GarmentFailureValidationError;
            expect(validationError.field, 'name');
          },
          (_) => fail('Se esperaba Left pero se obtuvo Right'),
        );
      },
    );

    /// T-03: name con solo espacios debe fallar igual que name vacío (RN-04).
    test(
      'T-03: name con solo espacios → Left con field="name" (RN-04)',
      () {
        // Act
        final result = GarmentEntity.create(
          id: _testId,
          name: '   ',      // INVÁLIDO — solo espacios
          owner: _validOwner,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<GarmentFailureValidationError>());
            expect((failure as GarmentFailureValidationError).field, 'name');
          },
          (_) => fail('Se esperaba Left pero se obtuvo Right'),
        );
      },
    );

    /// T-03b: owner vacío debe retornar Left<GarmentFailureValidationError>.
    test(
      'T-03b: owner vacío → Left con field="owner" (RN-04)',
      () {
        // Act
        final result = GarmentEntity.create(
          id: _testId,
          name: _validName,
          owner: '',         // INVÁLIDO
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<GarmentFailureValidationError>());
            expect((failure as GarmentFailureValidationError).field, 'owner');
          },
          (_) => fail('Se esperaba Left pero se obtuvo Right'),
        );
      },
    );

    test(
      'owner con solo espacios → Left con field="owner" (RN-04)',
      () {
        final result = GarmentEntity.create(
          id: _testId,
          name: _validName,
          owner: '   ',     // INVÁLIDO — solo espacios
        );
        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect((f as GarmentFailureValidationError).field, 'owner'),
          (_) => fail('Se esperaba Left'),
        );
      },
    );

    test(
      'name vacío tiene precedencia sobre owner vacío (validación en orden)',
      () {
        final result = GarmentEntity.create(
          id: _testId,
          name: '',   // primer campo validado
          owner: '',  // segundo campo — no debe llegar aquí
        );
        result.fold(
          (f) => expect((f as GarmentFailureValidationError).field, 'name'),
          (_) => fail('Se esperaba Left'),
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Grupo: GarmentEntity.copyWithStatus — Inmutabilidad
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentEntity.copyWithStatus —', () {
    late GarmentEntity baseEntity;

    setUp(() {
      // Fixture: prenda válida en estado inicial
      final result = GarmentEntity.create(
        id: _testId,
        name: _validName,
        owner: _validOwner,
        createdAt: DateTime(2024, 1, 15, 10, 0), // fecha fija para comparación
      );
      baseEntity = result.getOrElse((_) => throw Exception('fixture inválido'));
    });

    /// T-04a: copyWithStatus debe actualizar el estado correctamente.
    test(
      'T-04a: copyWithStatus actualiza el status al nuevo valor',
      () {
        // Act
        final updated = baseEntity.copyWithStatus(GarmentStatus.lavando);

        // Assert
        expect(updated.status, GarmentStatus.lavando);
      },
    );

    /// T-04b: copyWithStatus debe actualizar updatedAt sin alterar createdAt.
    test(
      'T-04b: copyWithStatus actualiza updatedAt pero preserva createdAt',
      () {
        // Act
        final before = DateTime.now();
        final updated = baseEntity.copyWithStatus(GarmentStatus.lavando);
        final after = DateTime.now();

        // Assert — updatedAt >= createdAt y dentro del rango de la llamada
        expect(
          updated.updatedAt.isAfter(baseEntity.createdAt) ||
              updated.updatedAt.isAtSameMomentAs(baseEntity.createdAt),
          isTrue,
        );
        expect(updated.updatedAt.isAfter(before) || updated.updatedAt.isAtSameMomentAs(before), isTrue);
        expect(updated.updatedAt.isBefore(after) || updated.updatedAt.isAtSameMomentAs(after), isTrue);
        expect(updated.createdAt, baseEntity.createdAt); // createdAt no cambia
      },
    );

    test(
      'copyWithStatus preserva todos los demás campos intactos',
      () {
        // Act
        final updated = baseEntity.copyWithStatus(GarmentStatus.devuelta);

        // Assert — todos los campos excepto status y updatedAt permanecen igual
        expect(updated.id, baseEntity.id);
        expect(updated.name, baseEntity.name);
        expect(updated.owner, baseEntity.owner);
        expect(updated.imagePath, baseEntity.imagePath);
        expect(updated.notes, baseEntity.notes);
        expect(updated.createdAt, baseEntity.createdAt);
      },
    );

    test(
      'copyWithStatus retorna una nueva instancia (inmutabilidad)',
      () {
        // Act
        final updated = baseEntity.copyWithStatus(GarmentStatus.lavando);

        // Assert — no es la misma referencia
        expect(identical(baseEntity, updated), isFalse);
        expect(baseEntity.status, GarmentStatus.guardada); // original no muta
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Grupo: GarmentEntity — Igualdad por ID
  // ══════════════════════════════════════════════════════════════════════════

  group('GarmentEntity — igualdad —', () {
    test(
      'dos entidades con el mismo ID son iguales sin importar su estado',
      () {
        final a = GarmentEntity.create(id: _testId, name: 'Camisa', owner: 'Juan')
            .getOrElse((_) => throw Exception());
        final b = a.copyWithStatus(GarmentStatus.lavando);

        expect(a, equals(b)); // mismo id → equals
        expect(a.hashCode, b.hashCode);
      },
    );

    test(
      'dos entidades con distintos IDs no son iguales',
      () {
        final a = GarmentEntity.create(id: 'id-001', name: 'Camisa', owner: 'Juan')
            .getOrElse((_) => throw Exception());
        final b = GarmentEntity.create(id: 'id-002', name: 'Camisa', owner: 'Juan')
            .getOrElse((_) => throw Exception());

        expect(a, isNot(equals(b)));
      },
    );
  });
}
