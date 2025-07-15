// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_result_details_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedResultDetailsModelAdapter
    extends TypeAdapter<CachedResultDetailsModel> {
  @override
  final int typeId = 5;

  @override
  CachedResultDetailsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedResultDetailsModel(
      uniqueId: fields[0] as String,
      data: (fields[1] as Map).cast<String, dynamic>(),
      cachedAt: fields[2] as DateTime,
      expiresAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedResultDetailsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.uniqueId)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.cachedAt)
      ..writeByte(3)
      ..write(obj.expiresAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedResultDetailsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
