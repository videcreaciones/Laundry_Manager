library;

import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

void main() {
  group('GarmentStatus.canTransitionTo —', () {
    test('T-06: guardada → lavando es VÁLIDO', () {
      expect(GarmentStatus.guardada.canTransitionTo(GarmentStatus.lavando), isTrue);
    });

    test('T-07: lavando → devuelta es VÁLIDO', () {
      expect(GarmentStatus.lavando.canTransitionTo(GarmentStatus.devuelta), isTrue);
    });

    test('T-09a: devuelta → guardada es VÁLIDO (ciclo)', () {
      expect(GarmentStatus.devuelta.canTransitionTo(GarmentStatus.guardada), isTrue);
    });

    test('T-08: guardada → devuelta es INVÁLIDO (salto de estado)', () {
      expect(GarmentStatus.guardada.canTransitionTo(GarmentStatus.devuelta), isFalse);
    });

    test('T-09b: devuelta → lavando es INVÁLIDO (salto de estado)', () {
      expect(GarmentStatus.devuelta.canTransitionTo(GarmentStatus.lavando), isFalse);
    });

    test('T-10: lavando → guardada es INVÁLIDO (retroceso)', () {
      expect(GarmentStatus.lavando.canTransitionTo(GarmentStatus.guardada), isFalse);
    });

    test('T-extra-a: guardada → guardada es INVÁLIDO (mismo estado)', () {
      expect(GarmentStatus.guardada.canTransitionTo(GarmentStatus.guardada), isFalse);
    });

    test('T-extra-b: lavando → lavando es INVÁLIDO (mismo estado)', () {
      expect(GarmentStatus.lavando.canTransitionTo(GarmentStatus.lavando), isFalse);
    });

    test('devuelta → devuelta es INVÁLIDO (mismo estado)', () {
      expect(GarmentStatus.devuelta.canTransitionTo(GarmentStatus.devuelta), isFalse);
    });
  });

  group('GarmentStatus.nextStatus —', () {
    test('guardada.nextStatus retorna lavando', () {
      expect(GarmentStatus.guardada.nextStatus, GarmentStatus.lavando);
    });

    test('lavando.nextStatus retorna devuelta', () {
      expect(GarmentStatus.lavando.nextStatus, GarmentStatus.devuelta);
    });

    test('T-11: devuelta.nextStatus retorna guardada (ciclo)', () {
      expect(GarmentStatus.devuelta.nextStatus, GarmentStatus.guardada);
    });

    test('nextStatus nunca es null (ciclo infinito)', () {
      for (final status in GarmentStatus.values) {
        expect(status.nextStatus, isNotNull,
            reason: '$status no debería tener nextStatus null en el ciclo');
      }
    });
  });

  group('GarmentStatus labels —', () {
    test('displayLabel retorna etiquetas no vacías para todos los estados', () {
      for (final status in GarmentStatus.values) {
        expect(status.displayLabel, isNotEmpty);
        expect(status.shortLabel, isNotEmpty);
      }
    });

    test('actionLabel nunca es null (todos los estados tienen acción en el ciclo)', () {
      for (final status in GarmentStatus.values) {
        expect(status.actionLabel, isNotEmpty,
            reason: '$status debería tener actionLabel en el ciclo');
      }
    });

    test('devuelta.actionLabel es "Volver a guardar"', () {
      expect(GarmentStatus.devuelta.actionLabel, 'Volver a guardar');
    });
  });
}
