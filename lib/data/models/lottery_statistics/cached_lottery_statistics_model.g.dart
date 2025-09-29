// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_lottery_statistics_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedLotteryStatisticsModelAdapter
    extends TypeAdapter<CachedLotteryStatisticsModel> {
  @override
  final int typeId = 20;

  @override
  CachedLotteryStatisticsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedLotteryStatisticsModel(
      userId: fields[0] as String,
      challengeStatistics: fields[1] as CachedChallengeStatisticsModel,
      lotteryEntries: (fields[2] as List).cast<CachedLotteryEntryModel>(),
      cacheTime: fields[3] as DateTime,
      cacheExpiryHours: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CachedLotteryStatisticsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.challengeStatistics)
      ..writeByte(2)
      ..write(obj.lotteryEntries)
      ..writeByte(3)
      ..write(obj.cacheTime)
      ..writeByte(4)
      ..write(obj.cacheExpiryHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedLotteryStatisticsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedChallengeStatisticsModelAdapter
    extends TypeAdapter<CachedChallengeStatisticsModel> {
  @override
  final int typeId = 21;

  @override
  CachedChallengeStatisticsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedChallengeStatisticsModel(
      totalExpense: fields[0] as double,
      totalWinnings: fields[1] as double,
      totalTickets: fields[2] as int,
      winRate: fields[3] as double,
      netResult: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CachedChallengeStatisticsModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.totalExpense)
      ..writeByte(1)
      ..write(obj.totalWinnings)
      ..writeByte(2)
      ..write(obj.totalTickets)
      ..writeByte(3)
      ..write(obj.winRate)
      ..writeByte(4)
      ..write(obj.netResult);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedChallengeStatisticsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CachedLotteryEntryModelAdapter
    extends TypeAdapter<CachedLotteryEntryModel> {
  @override
  final int typeId = 22;

  @override
  CachedLotteryEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedLotteryEntryModel(
      lotteryUniqueId: fields[0] as String?,
      slNo: fields[1] as int,
      lotteryNumber: fields[2] as String,
      lotteryName: fields[3] as String,
      price: fields[4] as double,
      purchaseDate: fields[5] as String,
      winnings: fields[6] as double?,
      status: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CachedLotteryEntryModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.lotteryUniqueId)
      ..writeByte(1)
      ..write(obj.slNo)
      ..writeByte(2)
      ..write(obj.lotteryNumber)
      ..writeByte(3)
      ..write(obj.lotteryName)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.purchaseDate)
      ..writeByte(6)
      ..write(obj.winnings)
      ..writeByte(7)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedLotteryEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
