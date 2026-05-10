library;

import 'package:hive_flutter/hive_flutter.dart';

part 'garment_model.g.dart';

const int kGarmentModelTypeId = 0;
const String kGarmentBoxName = 'garments';

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
  });
}
