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

  @HiveField(5)
  final int totalPoints;

  @HiveField(6)
  final CachedUpdatesModel updates;

  CachedHomeScreenModel({
    required this.status,
    required this.count,
    required this.results,
    required this.cacheTime,
    this.cacheExpiryHours = 24,
    required this.totalPoints,
    required this.updates,
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
        totalPoints: apiModel.totalPoints,
        updates: CachedUpdatesModel.fromApiModel(apiModel.updates),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Convert back to API model
  HomeScreenResultsModel toApiModel() {
    return HomeScreenResultsModel(
      status: status,
      count: count,
      results: results.map((result) => result.toApiModel()).toList(),
      totalPoints: totalPoints,
      updates: updates.toApiModel(),
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
  final CachedConsolationPrizesModel? consolationPrizes;

  @HiveField(8)
  final bool isPublished;

  @HiveField(9)
  final bool isBumper;

  CachedHomeScreenResultModel({
    required this.date,
    required this.id,
    required this.uniqueId,
    required this.lotteryName,
    required this.lotteryCode,
    required this.drawNumber,
    required this.firstPrize,
    this.consolationPrizes,
    required this.isPublished,
    required this.isBumper,
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
        consolationPrizes: apiModel.consolationPrizes != null 
            ? CachedConsolationPrizesModel.fromApiModel(apiModel.consolationPrizes!)
            : null,
        isPublished: apiModel.isPublished,
        isBumper: apiModel.isBumper,
      );
    } catch (e) {
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
      consolationPrizes: consolationPrizes?.toApiModel(),
      isPublished: isPublished,
      isBumper: isBumper,
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

@HiveType(typeId: 4)
class CachedUpdatesModel extends HiveObject {
  @HiveField(0)
  final String image1;

  @HiveField(1)
  final String image2;

  @HiveField(2)
  final String image3;

  @HiveField(3)
  final String? redirectLink1;

  @HiveField(4)
  final String? redirectLink2;

  @HiveField(5)
  final String? redirectLink3;

  CachedUpdatesModel({
    required this.image1,
    required this.image2,
    required this.image3,
    this.redirectLink1,
    this.redirectLink2,
    this.redirectLink3,
  });

  /// Convert from API model to cached model
  factory CachedUpdatesModel.fromApiModel(UpdatesModel apiModel) {
    return CachedUpdatesModel(
      image1: apiModel.image1,
      image2: apiModel.image2,
      image3: apiModel.image3,
      redirectLink1: apiModel.redirectLink1,
      redirectLink2: apiModel.redirectLink2,
      redirectLink3: apiModel.redirectLink3,
    );
  }

  /// Convert back to API model
  UpdatesModel toApiModel() {
    return UpdatesModel(
      image1: image1,
      image2: image2,
      image3: image3,
      redirectLink1: redirectLink1,
      redirectLink2: redirectLink2,
      redirectLink3: redirectLink3,
    );
  }

  /// Get all image URLs as a list
  List<String> get allImages => [image1, image2, image3].where((url) => url.isNotEmpty).toList();
}