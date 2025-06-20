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
          .toList() ?? [],
    );
  }
}

class UpdatesModel {
  final String image1;
  final String image2;
  final String image3;

  UpdatesModel({
    required this.image1,
    required this.image2,
    required this.image3,
  });

  factory UpdatesModel.fromJson(Map<String, dynamic> json) {
    return UpdatesModel(
      image1: json['image1'] ?? '',
      image2: json['image2'] ?? '',
      image3: json['image3'] ?? '',
    );
  }

  // Helper method to get all image URLs as a list
  List<String> get allImages => [image1, image2, image3].where((url) => url.isNotEmpty).toList();
}

class HomeScreenResultModel {
  final String date;
  final int id;
  final String uniqueId;
  final String lotteryName;
  final String lotteryCode;
  final String drawNumber;
  final FirstPrizeModel firstPrize;
  final ConsolationPrizesModel? consolationPrizes; // Made nullable
  final bool isPublished;
  final bool isBumper; // New field

  HomeScreenResultModel({
    required this.date,
    required this.id,
    required this.uniqueId,
    required this.lotteryName,
    required this.lotteryCode,
    required this.drawNumber,
    required this.firstPrize,
    this.consolationPrizes, // Nullable
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

  // Helper methods for UI display
  String get formattedTitle => '$lotteryName $lotteryCode Winner List';
  
  String get formattedFirstPrize {
    final amountInLakhs = (firstPrize.amount / 100000).toInt();
    return '1st Prize Rs ${firstPrize.amount.toInt()}/-  [$amountInLakhs Lakhs]';
  }
  
  String get formattedWinner => '${firstPrize.ticketNumber} (${firstPrize.place})';
  
  List<String> get consolationTicketsList {
    if (consolationPrizes == null) return [];
    return consolationPrizes!.ticketNumbers.split(' ').where((ticket) => ticket.isNotEmpty).toList();
  }
  
  String get formattedConsolationPrize {
    if (consolationPrizes == null) return 'No Consolation Prize';
    return 'Consolation Prize ${consolationPrizes!.amount.toInt()}/-';
  }
  
  // New helper method for bumper status
  String get lotteryTypeLabel => isBumper ? 'BUMPER' : 'REGULAR';
  
  // Date formatting helpers
  DateTime get dateTime => DateTime.parse(date);
  
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final resultDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (resultDate == today) {
      return 'Today Result';
    } else if (resultDate == yesterday) {
      return 'Yesterday Result';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    }
  }
  
  bool get isNew {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resultDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return resultDate == today;
  }

  // Helper method to check if consolation prizes exist
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