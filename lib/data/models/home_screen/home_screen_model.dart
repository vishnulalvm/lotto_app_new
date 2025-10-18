import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LotteryLocalizationHelper {
  static final Map<String, String> _lotteryNameToKey = {
    'VISHU BUMPER': 'vishuBumper',
    'SUMMER BUMPER': 'summerBumper',
    'POOJA BUMPER': 'poojaBumper',
    'KARUNYA PLUS': 'karunyaPlus',
    'SUVARNA KERALAM': 'suvarnaKeralam',
    'KARUNYA': 'karunya',
    'SAMRUDHI': 'samrudhi',
    'BHAGYATHARA': 'bhagyathara',
    'STHREE SAKTHI': 'sthreeSakthi',
    'DHANALEKSHMI': 'dhanalekshmi',
    'MANSOON BUMPER': 'monsoonbumper',
    'THIRUVONAM BUMPER': 'thiruvonamBumper',
    'CHRISTMAS NEW YEAR BUMPER': 'christmasNewYearBumper',
  };

  static String getLotteryKey(String lotteryName) {
    return _lotteryNameToKey[lotteryName.toUpperCase()] ?? 'karunya';
  }
}

class HomeScreenResultsModel {
  final String status;
  final int count;
  final int totalPoints;
  final UpdatesModel updates;
  final List<HomeScreenResultModel> results;

  HomeScreenResultsModel({
    required this.status,
    required this.count,
    required this.totalPoints,
    required this.updates,
    required this.results,
  });

  factory HomeScreenResultsModel.fromJson(Map<String, dynamic> json) {
    return HomeScreenResultsModel(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      updates: UpdatesModel.fromJson(json['updates'] ?? {}),
      results: (json['results'] as List<dynamic>?)
              ?.map((item) => HomeScreenResultModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class UpdatesModel {
  final String image1;
  final String image2;
  final String image3;
  final String? redirectLink1;
  final String? redirectLink2;
  final String? redirectLink3;

  UpdatesModel({
    required this.image1,
    required this.image2,
    required this.image3,
    this.redirectLink1,
    this.redirectLink2,
    this.redirectLink3,
  });

  factory UpdatesModel.fromJson(Map<String, dynamic> json) {
    return UpdatesModel(
      image1: _extractImageUrl(json['image1']),
      image2: _extractImageUrl(json['image2']),
      image3: _extractImageUrl(json['image3']),
      redirectLink1: _extractRedirectLink(json['image1']),
      redirectLink2: _extractRedirectLink(json['image2']),
      redirectLink3: _extractRedirectLink(json['image3']),
    );
  }

  // Helper method to extract image URL from either string or object format
  static String _extractImageUrl(dynamic imageData) {
    if (imageData == null) return '';

    if (imageData is String) {
      return imageData;
    } else if (imageData is Map<String, dynamic>) {
      return imageData['image_url']?.toString() ?? '';
    }

    return '';
  }

  // Helper method to extract redirect link from object format
  static String? _extractRedirectLink(dynamic imageData) {
    if (imageData is Map<String, dynamic>) {
      return imageData['redirect_link']?.toString();
    }
    return null;
  }

  // Helper method to get all image URLs as a list
  List<String> get allImages =>
      [image1, image2, image3].where((url) => url.isNotEmpty).toList();
}

class HomeScreenResultModel {
  final String date;
  final int id;
  final String uniqueId;
  final String lotteryName;
  final String lotteryCode;
  final String drawNumber;
  final FirstPrizeModel firstPrize;
  final ConsolationPrizesModel? consolationPrizes;
  final bool isPublished;
  final bool isBumper;

  HomeScreenResultModel({
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

  factory HomeScreenResultModel.fromJson(Map<String, dynamic> json) {
    return HomeScreenResultModel(
      date: json['date'] ?? '',
      id: json['id'] ?? 0,
      uniqueId: json['unique_id'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      lotteryCode: json['lottery_code'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      firstPrize: FirstPrizeModel.fromJson(json['first_prize'] ?? {}),
      consolationPrizes: json['consolation_prizes'] != null
          ? ConsolationPrizesModel.fromJson(json['consolation_prizes'])
          : null,
      isPublished: json['is_published'] ?? false,
      isBumper: json['is_bumper'] ?? false,
    );
  }

  // Updated method to support localization with easy_localization
  String getFormattedTitle(BuildContext context) {
    final lotteryKey = LotteryLocalizationHelper.getLotteryKey(lotteryName);
    final localizedLotteryName = lotteryKey.tr();


    return '$localizedLotteryName - $drawNumber';
  }

  // Keep the original method for backward compatibility (optional)
  String get formattedTitle => '$lotteryName WINNERS - $drawNumber';

  // ... rest of your existing methods remain the same
  String get formattedFirstPrize {
    final amountInLakhs = (firstPrize.amount / 100000).toInt();
    
    if (amountInLakhs >= 100) {
      final amountInCrores = (amountInLakhs / 100.0);
      if (amountInCrores == amountInCrores.toInt()) {
        // Whole number crores
        return '1st Prize Rs ${firstPrize.amount.toInt()}/-  [${amountInCrores.toInt()} Crore]';
      } else {
        // Decimal crores
        return '1st Prize Rs ${firstPrize.amount.toInt()}/-  [${amountInCrores.toStringAsFixed(1)} Crore]';
      }
    } else {
      return '1st Prize Rs ${firstPrize.amount.toInt()}/-  [$amountInLakhs Lakhs]';
    }
  }

  String get formattedWinner =>
      '${firstPrize.ticketNumber} (${firstPrize.place})';

  List<String> get consolationTicketsList {
    if (consolationPrizes == null) return [];
    return consolationPrizes!.ticketNumbers
        .split(' ')
        .where((ticket) => ticket.isNotEmpty)
        .toList();
  }

  String get formattedConsolationPrize {
    if (consolationPrizes == null) {
      return 'no_consolation_prize'.tr(); // Use the translation key
    }
    // Use named arguments for dynamic values with easy_localization
    return 'consolation_prize_amount'
        .tr(args: ['${consolationPrizes!.amount.toInt()}']);
  }

  String get lotteryTypeLabel => isBumper ? 'BUMPER' : 'REGULAR';

  DateTime get dateTime => DateTime.parse(date);

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final resultDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (resultDate == today) {
      return 'today_result'.tr(); // Use translation key
    } else if (resultDate == yesterday) {
      return 'yesterday_result'.tr(); // Use translation key
    } else {
      // For date formatting, easy_localization's DateFormat can be used,
      // or you can continue with manual formatting if preferred,
      // ensuring the format is consistent across locales.
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    }
  }

  bool get isNew {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resultDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return resultDate == today;
  }

  bool get isLive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resultDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    // Only show Live badge if it's today's result
    if (resultDate != today) return false;
    
    // Check if current time is between 3 PM (15:00) and 4 PM (16:00)
    final currentHour = now.hour;
    return currentHour >= 15 && currentHour < 16;
  }

  bool get hasConsolationPrizes => consolationPrizes != null;
}

class FirstPrizeModel {
  final double amount;
  final String ticketNumber;
  final String place;

  FirstPrizeModel({
    required this.amount,
    required this.ticketNumber,
    required this.place,
  });

  factory FirstPrizeModel.fromJson(Map<String, dynamic> json) {
    return FirstPrizeModel(
      amount: (json['amount'] ?? 0).toDouble(),
      ticketNumber: json['ticket_number'] ?? '',
      place: json['place'] ?? '',
    );
  }
}

class ConsolationPrizesModel {
  final double amount;
  final String ticketNumbers;

  ConsolationPrizesModel({
    required this.amount,
    required this.ticketNumbers,
  });

  factory ConsolationPrizesModel.fromJson(Map<String, dynamic> json) {
    return ConsolationPrizesModel(
      amount: (json['amount'] ?? 0).toDouble(),
      ticketNumbers: json['ticket_numbers'] ?? '',
    );
  }
}
