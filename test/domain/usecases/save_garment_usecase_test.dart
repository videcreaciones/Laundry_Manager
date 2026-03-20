library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:laundry_manager/domain/usecases/save_garment_usecase.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

import 'mock_garment_repository.mocks.dart';

void main() {
  late MockIGarmentRepository mockRepository;
  late SaveGarmentUseCase useCase;
  const fixedId = 'fixed-uuid-001';

  setUp(() {
    mockRepository = MockIGarmentRepository();
    provideDummy<Either<GarmentFailure, Unit>>(const Right(unit));
    useCase = SaveGarmentUseCase(mockRepository, fixedIdForTesting: fixedId);
  });

  group('camino feliz -', () {
    test('T-15: prenda valida retorna Right<GarmentEntity>', () async {
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(unit));
      final result = await useCase.execute(name: 'Camisa azul', owner: 'Juan', imagePath: '/foto.jpg');
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Se esperaba Right'),
        (entity) {
          expect(entity.id, fixedId);
          expect(entity.name, 'Camisa azul');
          expect(entity.owner, 'Juan');
          expect(entity.status, GarmentStatus.guardada);
          expect(entity.imagePath, '/foto.jpg');
        },
      );
      verify(mockRepository.save(any)).called(1);
    });

    test('prenda sin imagen retorna Right con imagePath null (RN-03)', () async {
      when(mockRepository.save(any)).thenAnswer((_) async => const Right(unit));
      final result = await useCase.execute(name: 'Pantalon', owner: 'Maria');
      result.fold((_) => fail('Right esperado'), (e) => expect(e.imagePath, isNull));
      verify(mockRepository.save(any)).called(1);
    });
  });

  group('validacion fallida (RN-04) -', () {
    test('T-15b: name vacio retorna Left sin llamar al repositorio', () async {
      final result = await useCase.execute(name: '', owner: 'Juan');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GarmentFailureValidationError>()), (_) => fail('Left esperado'));
      verifyNever(mockRepository.save(any));
    });

    test('owner vacio retorna Left sin llamar al repositorio', () async {
      final result = await useCase.execute(name: 'Camisa', owner: '');
      expect(result.isLeft(), isTrue);
      verifyNever(mockRepository.save(any));
    });
  });

  group('errores del repositorio -', () {
    test('T-16: repository.save falla retorna Left<StorageError>', () async {
      when(mockRepository.save(any))
          .thenAnswer((_) async => const Left(GarmentFailureStorageError('Sin espacio')));
      final result = await useCase.execute(name: 'Camisa', owner: 'Juan');
      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<GarmentFailureStorageError>()), (_) => fail('Left esperado'));
    });
  });
}
