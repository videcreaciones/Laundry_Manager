library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:laundry_manager/domain/usecases/update_garment_status_usecase.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

import 'mock_garment_repository.mocks.dart';

void main() {
  late MockIGarmentRepository mockRepository;
  late UpdateGarmentStatusUseCase useCase;
  const testId = 'prenda-test-001';

  setUp(() {
    mockRepository = MockIGarmentRepository();
    provideDummy<Either<GarmentFailure, Unit>>(const Right(unit));
    useCase = UpdateGarmentStatusUseCase(mockRepository);
  });

  group('transiciones válidas —', () {
    test('T-12: guardada → lavando llama a repository.updateStatus y retorna Right', () async {
      when(mockRepository.updateStatus(testId, GarmentStatus.lavando))
          .thenAnswer((_) async => const Right(unit));
      final result = await useCase.execute(id: testId, from: GarmentStatus.guardada, to: GarmentStatus.lavando);
      expect(result.isRight(), isTrue);
      verify(mockRepository.updateStatus(testId, GarmentStatus.lavando)).called(1);
    });

    test('lavando → devuelta llama a repository.updateStatus y retorna Right', () async {
      when(mockRepository.updateStatus(testId, GarmentStatus.devuelta))
          .thenAnswer((_) async => const Right(unit));
      final result = await useCase.execute(id: testId, from: GarmentStatus.lavando, to: GarmentStatus.devuelta);
      expect(result.isRight(), isTrue);
      verify(mockRepository.updateStatus(testId, GarmentStatus.devuelta)).called(1);
    });
  });

  group('transiciones inválidas (RN-01) —', () {
    test('T-13: guardada → devuelta retorna Left<InvalidTransition> sin llamar al repositorio', () async {
      final result = await useCase.execute(id: testId, from: GarmentStatus.guardada, to: GarmentStatus.devuelta);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<GarmentFailureInvalidTransition>());
          expect((f as GarmentFailureInvalidTransition).from, GarmentStatus.guardada);
          expect(f.to, GarmentStatus.devuelta);
        },
        (_) => fail('Se esperaba Left'),
      );
      verifyNever(mockRepository.updateStatus(any, any));
    });

    test('T-13b: lavando → guardada (retroceso) retorna Left sin llamar al repositorio', () async {
      final result = await useCase.execute(id: testId, from: GarmentStatus.lavando, to: GarmentStatus.guardada);
      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<GarmentFailureInvalidTransition>());
      verifyNever(mockRepository.updateStatus(any, any));
    });

    test('T-13c: devuelta → cualquier estado retorna Left sin llamar al repositorio', () async {
      for (final to in GarmentStatus.values) {
        final result = await useCase.execute(id: testId, from: GarmentStatus.devuelta, to: to);
        expect(result.isLeft(), isTrue, reason: 'devuelta → $to deberia ser invalido');
      }
      verifyNever(mockRepository.updateStatus(any, any));
    });
  });

  group('errores del repositorio —', () {
    test('T-14: repositorio retorna Left<storageError> → use case lo propaga', () async {
      when(mockRepository.updateStatus(testId, GarmentStatus.lavando))
          .thenAnswer((_) async => const Left(GarmentFailureStorageError('Disco lleno')));
      final result = await useCase.execute(id: testId, from: GarmentStatus.guardada, to: GarmentStatus.lavando);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GarmentFailureStorageError>()), (_) => fail('Left esperado'));
    });

    test('repositorio retorna Left<notFound> → use case lo propaga', () async {
      when(mockRepository.updateStatus('no-existe', GarmentStatus.lavando))
          .thenAnswer((_) async => const Left(GarmentFailureNotFound('no-existe')));
      final result = await useCase.execute(id: 'no-existe', from: GarmentStatus.guardada, to: GarmentStatus.lavando);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GarmentFailureNotFound>()), (_) => fail('Left esperado'));
    });
  });
}
