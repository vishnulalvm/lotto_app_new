import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';

part 'cached_home_screen_model.g.dart';

@HiveType(typeId: 0)
class CachedHomeScreenModel extends HiveObject {
  @HiveField(0)
  final String status;

  @HiveField(1)
  final int count;

  @HiveField(2)
  final List<CachedHomeScreenResultModel> results;

  @HiveField(3)
  final DateTime cacheTime;

  @HiveField(4)
  final int cacheExpiryHours;

  CachedHomeScreenModel({
    required this.status,
    required this.count,
    required this.results,
    required this.cacheTime,
    this.cacheExpiryHours = 24,
  });

  /// Convert from API model to cached model
  factory CachedHomeScreenModel.fromApiModel(HomeScreenResultsModel apiModel) {
    try {
      return CachedHomeScreenModel(
        status: apiModel.status,
        count: apiModel.count,
        results: apiModel.results
            .map((result) => CachedHomeScreenResultModel.fromApiModel(result))
            .toList(),
        cacheTime: DateTime.now(),
      );
    } catch (e) {
      print('Error converting API model to cached model: $e');
      rethrow;
    }
  }

  /// Convert back to API model
  HomeScreenResultsModel toApiModel() {
    return HomeScreenResultsModel(
      status: status,
      count: count,
      results: results.map((result) => result.toApiModel()).toList(),
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

@HiveType(typeId: 1)
class CachedHomeScreenResultModel extends HiveObject {
  @HiveField(0)
  final String date;

  @HiveField(1)
  final int id;

  @HiveField(2)
  final String uniqueId;

  @HiveField(3)
  final String lotteryName;

  @HiveField(4)
  final String lotteryCode;

  @HiveField(5)
  final String drawNumber;

  @HiveField(6)
  final CachedFirstPrizeModel firstPrize;

  @HiveField(7)
  final CachedConsolationPrizesModel consolationPrizes;

  @HiveField(8)
  final bool isPublished;

  CachedHomeScreenResultModel({
    required this.date,
    required this.id,
    required this.uniqueId,
    required this.lotteryName,
    required this.lotteryCode,
    required this.drawNumber,
    required this.firstPrize,
    required this.consolationPrizes,
    required this.isPublished,
  });

  /// Convert from API model to cached model
  factory CachedHomeScreenResultModel.fromApiModel(HomeScreenResultModel apiModel) {
    try {
      return CachedHomeScreenResultModel(
        date: apiModel.date,
        id: apiModel.id,
        uniqueId: apiModel.uniqueId,
        lotteryName: apiModel.lotteryName,
        lotteryCode: apiModel.lotteryCode,
        drawNumber: apiModel.drawNumber,
        firstPrize: CachedFirstPrizeModel.fromApiModel(apiModel.firstPrize),
        consolationPrizes: CachedConsolationPrizesModel.fromApiModel(apiModel.consolationPrizes),
        isPublished: apiModel.isPublished,
      );
    } catch (e) {
      print('Error converting result model for ${apiModel.lotteryName}: $e');
      rethrow;
    }
  }

  /// Convert back to API model
  HomeScreenResultModel toApiModel() {
    return HomeScreenResultModel(
      date: date,
      id: id,
      uniqueId: uniqueId,
      lotteryName: lotteryName,
      lotteryCode: lotteryCode,
      drawNumber: drawNumber,
      firstPrize: firstPrize.toApiModel(),
      consolationPrizes: consolationPrizes.toApiModel(),
      isPublished: isPublished,
    );
  }
}

@HiveType(typeId: 2)
class CachedFirstPrizeModel extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String ticketNumber;

  @HiveField(2)
  final String place;

  CachedFirstPrizeModel({
    required this.amount,
    required this.ticketNumber,
    required this.place,
  });

  /// Convert from API model to cached model
  factory CachedFirstPrizeModel.fromApiModel(FirstPrizeModel apiModel) {
    return CachedFirstPrizeModel(
      amount: apiModel.amount,
      ticketNumber: apiModel.ticketNumber,
      place: apiModel.place,
    );
  }

  /// Convert back to API model
  FirstPrizeModel toApiModel() {
    return FirstPrizeModel(
      amount: amount,
      ticketNumber: ticketNumber,
      place: place,
    );
  }
}

@HiveType(typeId: 3)
class CachedConsolationPrizesModel extends HiveObject {
  @HiveField(0)
  final double amount;

  @HiveField(1)
  final String ticketNumbers;

  CachedConsolationPrizesModel({
    required this.amount,
    required this.ticketNumbers,
  });

  /// Convert from API model to cached model
  factory CachedConsolationPrizesModel.fromApiModel(ConsolationPrizesModel apiModel) {
    return CachedConsolationPrizesModel(
      amount: apiModel.amount,
      ticketNumbers: apiModel.ticketNumbers,
    );
  }

  /// Convert back to API model
  ConsolationPrizesModel toApiModel() {
    return ConsolationPrizesModel(
      amount: amount,
      ticketNumbers: ticketNumbers,
    );
  }
}