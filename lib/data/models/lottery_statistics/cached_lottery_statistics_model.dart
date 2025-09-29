import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/challenge_statistics_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_entry_model.dart';

part 'cached_lottery_statistics_model.g.dart';

@HiveType(typeId: 20)
class CachedLotteryStatisticsModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final CachedChallengeStatisticsModel challengeStatistics;

  @HiveField(2)
  final List<CachedLotteryEntryModel> lotteryEntries;

  @HiveField(3)
  final DateTime cacheTime;

  @HiveField(4)
  final int cacheExpiryHours;

  CachedLotteryStatisticsModel({
    required this.userId,
    required this.challengeStatistics,
    required this.lotteryEntries,
    required this.cacheTime,
    this.cacheExpiryHours = 24,
  });

  /// Convert from API model to cached model
  factory CachedLotteryStatisticsModel.fromApiModel(LotteryStatisticsResponseModel apiModel) {
    try {
      return CachedLotteryStatisticsModel(
        userId: apiModel.userId,
        challengeStatistics: CachedChallengeStatisticsModel.fromApiModel(apiModel.challengeStatistics),
        lotteryEntries: apiModel.lotteryEntries
            .map((entry) => CachedLotteryEntryModel.fromApiModel(entry))
            .toList(),
        cacheTime: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert back to API model
  LotteryStatisticsResponseModel toApiModel() {
    return LotteryStatisticsResponseModel(
      userId: userId,
      challengeStatistics: challengeStatistics.toApiModel(),
      lotteryEntries: lotteryEntries.map((entry) => entry.toApiModel()).toList(),
    );
  }

  /// Check if cache has expired
  bool get isExpired {
    return DateTime.now().isAfter(cacheTime.add(Duration(hours: cacheExpiryHours)));
  }

  /// Check if cache is still fresh (within 30 minutes)
  bool get isFresh {
    return DateTime.now().isBefore(cacheTime.add(const Duration(minutes: 30)));
  }

  /// Get cache age in minutes
  int get cacheAgeInMinutes {
    return DateTime.now().difference(cacheTime).inMinutes;
  }
}

@HiveType(typeId: 21)
class CachedChallengeStatisticsModel extends HiveObject {
  @HiveField(0)
  final double totalExpense;

  @HiveField(1)
  final double totalWinnings;

  @HiveField(2)
  final int totalTickets;

  @HiveField(3)
  final double winRate;

  @HiveField(4)
  final double netResult;

  CachedChallengeStatisticsModel({
    required this.totalExpense,
    required this.totalWinnings,
    required this.totalTickets,
    required this.winRate,
    required this.netResult,
  });

  /// Convert from API model to cached model
  factory CachedChallengeStatisticsModel.fromApiModel(ChallengeStatisticsModel apiModel) {
    return CachedChallengeStatisticsModel(
      totalExpense: apiModel.totalExpense,
      totalWinnings: apiModel.totalWinnings,
      totalTickets: apiModel.totalTickets,
      winRate: apiModel.winRate,
      netResult: apiModel.netResult,
    );
  }

  /// Convert back to API model
  ChallengeStatisticsModel toApiModel() {
    return ChallengeStatisticsModel(
      totalExpense: totalExpense,
      totalWinnings: totalWinnings,
      totalTickets: totalTickets,
      winRate: winRate,
      netResult: netResult,
    );
  }
}

@HiveType(typeId: 22)
class CachedLotteryEntryModel extends HiveObject {
  @HiveField(0)
  final String? lotteryUniqueId;

  @HiveField(1)
  final int slNo;

  @HiveField(2)
  final String lotteryNumber;

  @HiveField(3)
  final String lotteryName;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final String purchaseDate;

  @HiveField(6)
  final double? winnings;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final int id;

  CachedLotteryEntryModel({
    this.lotteryUniqueId,
    required this.slNo,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.price,
    required this.purchaseDate,
    this.winnings,
    required this.status,
    required this.id,
  });

  /// Convert from API model to cached model
  factory CachedLotteryEntryModel.fromApiModel(LotteryEntryModel apiModel) {
    return CachedLotteryEntryModel(
      id: apiModel.id,
      lotteryUniqueId: apiModel.lotteryUniqueId,
      slNo: apiModel.slNo,
      lotteryNumber: apiModel.lotteryNumber,
      lotteryName: apiModel.lotteryName,
      price: apiModel.price,
      purchaseDate: apiModel.purchaseDate,
      winnings: apiModel.winnings,
      status: apiModel.status.name,
    );
  }

  /// Convert back to API model
  LotteryEntryModel toApiModel() {
    return LotteryEntryModel(
      id: id,
      lotteryUniqueId: lotteryUniqueId,
      slNo: slNo,
      lotteryNumber: lotteryNumber,
      lotteryName: lotteryName,
      price: price,
      purchaseDate: purchaseDate,
      winnings: winnings,
      status: LotteryEntryStatus.fromString(status),
    );
  }
}