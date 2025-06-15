class HomeScreenResultsModel {
  final String status;
  final int count;
  final List<HomeScreenResultModel> results;

  HomeScreenResultsModel({
    required this.status,
    required this.count,
    required this.results,
  });

  factory HomeScreenResultsModel.fromJson(Map<String, dynamic> json) {
    return HomeScreenResultsModel(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      results: (json['results'] as List<dynamic>?)
          ?.map((item) => HomeScreenResultModel.fromJson(item))
          .toList() ?? [],
    );
  }
}

class HomeScreenResultModel {
  final String date;
  final int id;
  final String uniqueId;
  final String lotteryName;
  final String lotteryCode;
  final String drawNumber;
  final FirstPrizeModel firstPrize;
  final ConsolationPrizesModel consolationPrizes;
  final bool isPublished;

  HomeScreenResultModel({
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

  factory HomeScreenResultModel.fromJson(Map<String, dynamic> json) {
    return HomeScreenResultModel(
      date: json['date'] ?? '',
      id: json['id'] ?? 0,
      uniqueId: json['unique_id'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      lotteryCode: json['lottery_code'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      firstPrize: FirstPrizeModel.fromJson(json['first_prize'] ?? {}),
      consolationPrizes: ConsolationPrizesModel.fromJson(json['consolation_prizes'] ?? {}),
      isPublished: json['is_published'] ?? false,
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
    return consolationPrizes.ticketNumbers.split(' ').where((ticket) => ticket.isNotEmpty).toList();
  }
  
  String get formattedConsolationPrize => 'Consolation Prize ${consolationPrizes.amount.toInt()}/-';
  
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
