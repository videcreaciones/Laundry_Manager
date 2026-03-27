library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_failure.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';
import 'package:laundry_manager/injection_container.dart';

class GarmentException implements Exception {
  final GarmentFailure failure;
  const GarmentException(this.failure);

  @override
  String toString() => failure.toString();

  String get userMessage => switch (failure) {
    GarmentFailureValidationError(:final field, :final message) =>
      'Error en "$field": $message',
    GarmentFailureInvalidTransition(:final from, :final to) =>
      'No se puede cambiar de "${from.displayLabel}" a "${to.displayLabel}".',
    GarmentFailureDeletionForbidden(:final reason) => reason,
    GarmentFailureNotFound(:final id) =>
      'Prenda con ID "$id" no encontrada.',
    GarmentFailureStorageError(:final message) =>
      'Error de almacenamiento: $message',
    GarmentFailureImagePickerError(:final message) =>
      'Error al seleccionar imagen: $message',
  };
}

int _statusOrder(GarmentStatus s) => switch (s) {
  GarmentStatus.lavando  => 0,
  GarmentStatus.devuelta => 1,
  GarmentStatus.guardada => 2,
};

List<GarmentEntity> _sorted(List<GarmentEntity> list) {
  final copy = [...list];
  copy.sort((a, b) {
    final sc = _statusOrder(a.status).compareTo(_statusOrder(b.status));
    return sc != 0 ? sc : b.createdAt.compareTo(a.createdAt);
  });
  return copy;
}

class GarmentNotifier extends AsyncNotifier<List<GarmentEntity>> {
  @override
  Future<List<GarmentEntity>> build() async {
    final result = await ref.read(getAllGarmentsUseCaseProvider).execute();
    return result.fold(
      (failure) => throw GarmentException(failure),
      (garments) => _sorted(garments),
    );
  }

  Future<void> addGarment({
    required String name,
    required String owner,
    String? imagePath,
    String? notes,
    String? categoryId,
  }) async {
    final result = await ref
        .read(saveGarmentUseCaseProvider)
        .execute(name: name, owner: owner, imagePath: imagePath, notes: notes, categoryId: categoryId);
    result.fold(
      (failure) => throw GarmentException(failure),
      (newEntity) {
        final current = state.value ?? [];
        state = AsyncData(_sorted([newEntity, ...current]));
      },
    );
  }

  Future<void> updateStatus({
    required String id,
    required GarmentStatus from,
    required GarmentStatus to,
  }) async {
    final result = await ref
        .read(updateGarmentStatusUseCaseProvider)
        .execute(id: id, from: from, to: to);

    await result.fold(
      (failure) async => throw GarmentException(failure),
      (_) async {
        final updatedOptimistic = (state.value ?? []).map((e) {
          return e.id == id ? e.copyWithStatus(to) : e;
        }).toList();
        state = AsyncData(updatedOptimistic);
        await Future.delayed(const Duration(seconds: 1));
        state = AsyncData(_sorted(updatedOptimistic));
      },
    );
  }

  Future<void> editGarment({
    required GarmentEntity original,
    required String name,
    required String owner,
    String? imagePath,
    String? notes,
    String? categoryId,
  }) async {
    final result = await ref.read(updateGarmentUseCaseProvider).execute(
      original: original, name: name, owner: owner,
      imagePath: imagePath, notes: notes, categoryId: categoryId,
    );
    result.fold(
      (failure) => throw GarmentException(failure),
      (updated) {
        final current = state.value ?? [];
        state = AsyncData(_sorted(
          current.map((e) => e.id == updated.id ? updated : e).toList(),
        ));
      },
    );
  }

  Future<void> deleteGarment({
    required String id,
    required GarmentStatus currentStatus,
  }) async {
    final previous = state;
    state = AsyncData(
      (state.value ?? []).where((e) => e.id != id).toList(),
    );
    final result = await ref
        .read(deleteGarmentUseCaseProvider)
        .execute(id: id, currentStatus: currentStatus);
    result.fold(
      (failure) {
        state = previous;
        throw GarmentException(failure);
      },
      (_) {},
    );
  }
}

final garmentNotifierProvider =
    AsyncNotifierProvider<GarmentNotifier, List<GarmentEntity>>(
  GarmentNotifier.new,
);





