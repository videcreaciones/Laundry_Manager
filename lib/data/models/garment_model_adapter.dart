library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:laundry_manager/data/models/garment_model.dart';

/// Adaptador de Hive escrito a mano para [GarmentModel] — ver la nota en
/// garment_model.dart sobre por que no se usa hive_generator. Los indices
/// de campo deben coincidir exactamente con los @HiveField de esa clase.
class GarmentModelAdapter extends TypeAdapter<GarmentModel> {
  @override
  final int typeId = kGarmentModelTypeId;

  @override
  GarmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GarmentModel(
      id:             fields[0] as String,
      name:           fields[1] as String,
      owner:          fields[2] as String,
      statusIndex:    fields[3] as int,
      imagePath:      fields[4] as String?,
      createdAt:      fields[5] as DateTime,
      updatedAt:      fields[6] as DateTime,
      notes:          fields[7] as String?,
      categoryId:     fields[8] as String?,
      reminderType:   fields[9] as String?,
      reminderValue:  fields[10] as int?,
      reminderHour:   fields[11] as int?,
      reminderMinute: fields[12] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, GarmentModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.owner)
      ..writeByte(3)
      ..write(obj.statusIndex)
      ..writeByte(4)
      ..write(obj.imagePath)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.categoryId)
      ..writeByte(9)
      ..write(obj.reminderType)
      ..writeByte(10)
      ..write(obj.reminderValue)
      ..writeByte(11)
      ..write(obj.reminderHour)
      ..writeByte(12)
      ..write(obj.reminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GarmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
