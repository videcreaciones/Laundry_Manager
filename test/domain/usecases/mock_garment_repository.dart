/// Archivo fuente para la generación de mocks con mockito.
///
/// Ejecutar después de crear este archivo:
///   flutter pub run build_runner build --delete-conflicting-outputs
///
/// Esto genera: mock_garment_repository.mocks.dart
library;

import 'package:mockito/annotations.dart';
import 'package:laundry_manager/domain/repositories/i_garment_repository.dart';

@GenerateMocks([IGarmentRepository])
void main() {}
