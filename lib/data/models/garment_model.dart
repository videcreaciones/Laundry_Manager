library;

import 'package:hive_flutter/hive_flutter.dart';

export 'garment_model_adapter.dart';

const int kGarmentModelTypeId = 0;
const String kGarmentBoxName = 'garments';

// hive_generator no se usa (incompatible con la version de source_gen que
// requiere riverpod_generator) — el adaptador de estos campos se escribe a
// mano en garment_model_adapter.dart y debe mantenerse en sincronia con
// los indices @HiveField de abajo.
@HiveType(typeId: kGarmentModelTypeId)
class GarmentModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String owner;
  @HiveField(3) late int statusIndex;
  @HiveField(4) String? imagePath;
  @HiveField(5) late DateTime createdAt;
  @HiveField(6) late DateTime updatedAt;
  @HiveField(7) String? notes;
  @HiveField(8) String? categoryId; // NUEVO
  @HiveField(9) String? reminderType; // 'everyNDays' | 'monthlyOnDay'
  @HiveField(10) int? reminderValue;
  @HiveField(11) int? reminderHour;
  @HiveField(12) int? reminderMinute;

  GarmentModel({
    required this.id,
    required this.name,
    required this.owner,
    required this.statusIndex,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.notes,
    this.categoryId,
    this.reminderType,
    this.reminderValue,
    this.reminderHour,
    this.reminderMinute,
  });
}
