// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_home_screen_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedHomeScreenModelAdapter extends TypeAdapter<CachedHomeScreenModel> {
  @override
  final int typeId = 0;

  @override
  CachedHomeScreenModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedHomeScreenModel(
      status: fields[0] as String,
      count: fields[1] as int,
      results: (fields[2] as List).cast<CachedHomeScreenResultModel>(),
      cacheTime: fields[3] as DateTime,
      cacheExpiryHours: fields[4] as int,
      totalPoints: fields[5] as int,
      updates: fields[6] as CachedUpdatesModel,
    );
  }

  @override
  void write(BinaryWriter writer, CachedHomeScreenModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.status)
      ..writeByte(1)
      ..write(obj.count)
      ..writeByte(2)
      ..write(obj.results)
      ..writeByte(3)
      ..write(obj.cacheTime)
      ..writeByte(4)
      ..write(obj.cacheExpiryHours)
      ..writeByte(5)
      ..write(obj.totalPoints)
      ..writeByte(6)
      ..write(obj.updates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedHomeScreenModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedHomeScreenResultModelAdapter
    extends TypeAdapter<CachedHomeScreenResultModel> {
  @override
  final int typeId = 1;

  @override
  CachedHomeScreenResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedHomeScreenResultModel(
      date: fields[0] as String,
      id: fields[1] as int,
      uniqueId: fields[2] as String,
      lotteryName: fields[3] as String,
      lotteryCode: fields[4] as String,
      drawNumber: fields[5] as String,
      firstPrize: fields[6] as CachedFirstPrizeModel,
      consolationPrizes: fields[7] as CachedConsolationPrizesModel?,
      isPublished: fields[8] as bool,
      isBumper: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CachedHomeScreenResultModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.uniqueId)
      ..writeByte(3)
      ..write(obj.lotteryName)
      ..writeByte(4)
      ..write(obj.lotteryCode)
      ..writeByte(5)
      ..write(obj.drawNumber)
      ..writeByte(6)
      ..write(obj.firstPrize)
      ..writeByte(7)
      ..write(obj.consolationPrizes)
      ..writeByte(8)
      ..write(obj.isPublished)
      ..writeByte(9)
      ..write(obj.isBumper);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedHomeScreenResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedFirstPrizeModelAdapter extends TypeAdapter<CachedFirstPrizeModel> {
  @override
  final int typeId = 2;

  @override
  CachedFirstPrizeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedFirstPrizeModel(
      amount: fields[0] as double,
      ticketNumber: fields[1] as String,
      place: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedFirstPrizeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.ticketNumber)
      ..writeByte(2)
      ..write(obj.place);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedFirstPrizeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedConsolationPrizesModelAdapter
    extends TypeAdapter<CachedConsolationPrizesModel> {
  @override
  final int typeId = 3;

  @override
  CachedConsolationPrizesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedConsolationPrizesModel(
      amount: fields[0] as double,
      ticketNumbers: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedConsolationPrizesModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.ticketNumbers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedConsolationPrizesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedUpdatesModelAdapter extends TypeAdapter<CachedUpdatesModel> {
  @override
  final int typeId = 4;

  @override
  CachedUpdatesModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUpdatesModel(
      image1: fields[0] as String,
      image2: fields[1] as String,
      image3: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedUpdatesModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.image1)
      ..writeByte(1)
      ..write(obj.image2)
      ..writeByte(2)
      ..write(obj.image3);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUpdatesModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
