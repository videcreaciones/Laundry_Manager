library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:laundry_manager/domain/usecases/delete_garment_usecase.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

import 'mock_garment_repository.mocks.dart';

void main() {
  late MockIGarmentRepository mockRepository;
  late DeleteGarmentUseCase useCase;
  const testId = 'prenda-test-001';

  setUp(() {
    mockRepository = MockIGarmentRepository();
    provideDummy<Either<GarmentFailure, Unit>>(const Right(unit));
    useCase = DeleteGarmentUseCase(mockRepository);
  });

  group('borrado permitido —', () {
    test('T-17: prenda en estado guardada → borrado exitoso', () async {
      when(mockRepository.delete(testId)).thenAnswer((_) async => const Right(unit));
      final result = await useCase.execute(id: testId, currentStatus: GarmentStatus.guardada);
      expect(result.isRight(), isTrue);
      verify(mockRepository.delete(testId)).called(1);
    });

    test('T-19: prenda en estado devuelta → borrado exitoso', () async {
      when(mockRepository.delete(testId)).thenAnswer((_) async => const Right(unit));
      final result = await useCase.execute(id: testId, currentStatus: GarmentStatus.devuelta);
      expect(result.isRight(), isTrue);
      verify(mockRepository.delete(testId)).called(1);
    });
  });

  group('borrado prohibido (RN-02) —', () {
    test('T-18: prenda en LAVANDO → Left<DeletionForbidden> sin llamar al repositorio', () async {
      final result = await useCase.execute(id: testId, currentStatus: GarmentStatus.lavando);
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<GarmentFailureDeletionForbidden>());
          expect((f as GarmentFailureDeletionForbidden).reason, contains(testId));
        },
        (_) => fail('Se esperaba Left'),
      );
      verifyNever(mockRepository.delete(any));
    });
  });

  group('errores del repositorio —', () {
    test('Left<notFound> se propaga', () async {
      when(mockRepository.delete('fantasma'))
          .thenAnswer((_) async => const Left(GarmentFailureNotFound('fantasma')));
      final result = await useCase.execute(id: 'fantasma', currentStatus: GarmentStatus.guardada);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GarmentFailureNotFound>()), (_) => fail('Left esperado'));
    });

    test('Left<storageError> se propaga', () async {
      when(mockRepository.delete(testId))
          .thenAnswer((_) async => const Left(GarmentFailureStorageError('Error de disco')));
      final result = await useCase.execute(id: testId, currentStatus: GarmentStatus.devuelta);
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GarmentFailureStorageError>()), (_) => fail('Left esperado'));
    });
  });
}
