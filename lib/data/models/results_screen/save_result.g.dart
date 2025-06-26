// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedLotteryResultAdapter extends TypeAdapter<SavedLotteryResult> {
  @override
  final int typeId = 5;

  @override
  SavedLotteryResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedLotteryResult(
      uniqueId: fields[0] as String,
      title: fields[1] as String,
      date: fields[2] as String,
      prize: fields[3] as String,
      winner: fields[4] as String,
      consolationPrizes: (fields[5] as List).cast<String>(),
      savedAt: fields[6] as DateTime,
      isFavorite: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavedLotteryResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uniqueId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.prize)
      ..writeByte(4)
      ..write(obj.winner)
      ..writeByte(5)
      ..write(obj.consolationPrizes)
      ..writeByte(6)
      ..write(obj.savedAt)
      ..writeByte(7)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLotteryResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
