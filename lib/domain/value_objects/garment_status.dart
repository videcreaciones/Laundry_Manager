library;

enum GarmentStatus {
  guardada,
  lavando,
  devuelta;

  bool canTransitionTo(GarmentStatus next) {
    return switch (this) {
      GarmentStatus.guardada => next == GarmentStatus.lavando,
      GarmentStatus.lavando  => next == GarmentStatus.devuelta,
      GarmentStatus.devuelta => next == GarmentStatus.guardada, // CICLO
    };
  }

  GarmentStatus? get nextStatus => switch (this) {
    GarmentStatus.guardada => GarmentStatus.lavando,
    GarmentStatus.lavando  => GarmentStatus.devuelta,
    GarmentStatus.devuelta => GarmentStatus.guardada, // CICLO — nunca null
  };

  String get displayLabel => switch (this) {
    GarmentStatus.guardada => 'Guardada',
    GarmentStatus.lavando  => 'En lavandería',
    GarmentStatus.devuelta => 'Devuelta',
  };

  String get shortLabel => switch (this) {
    GarmentStatus.guardada => 'Guardada',
    GarmentStatus.lavando  => 'Lavando',
    GarmentStatus.devuelta => 'Devuelta',
  };

  String get actionLabel => switch (this) {
    GarmentStatus.guardada => 'Enviar a lavandería',
    GarmentStatus.lavando  => 'Marcar como devuelta',
    GarmentStatus.devuelta => 'Volver a guardar',  // NUEVO
  };
}
