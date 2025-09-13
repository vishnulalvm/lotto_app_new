// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_prediction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiPredictionModelAdapter extends TypeAdapter<AiPredictionModel> {
  @override
  final int typeId = 10;

  @override
  AiPredictionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiPredictionModel(
      date: fields[0] as String,
      prizeType: fields[1] as int,
      predictedNumbers: (fields[2] as List).cast<String>(),
      generatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiPredictionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.prizeType)
      ..writeByte(2)
      ..write(obj.predictedNumbers)
      ..writeByte(3)
      ..write(obj.generatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiPredictionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
