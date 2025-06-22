class LotteryResultDetailsModel {
  final String status;
  final LotteryResultModel result;

  LotteryResultDetailsModel({
    required this.status,
    required this.result,
  });

  factory LotteryResultDetailsModel.fromJson(Map<String, dynamic> json) {
    return LotteryResultDetailsModel(
      status: json['status'] ?? '',
      result: LotteryResultModel.fromJson(json['result'] ?? {}),
    );
  }
}

class LotteryResultModel {
  final String date;
  final int id;
  final String uniqueId;
  final String lotteryName;
  final String lotteryCode;
  final String drawNumber;
  final List<PrizeModel> prizes;
  final bool isPublished;
  final bool isBumper;
  final String createdAt;
  final String updatedAt;

  LotteryResultModel({
    required this.date,
    required this.id,
    required this.uniqueId,
    required this.lotteryName,
    required this.lotteryCode,
    required this.drawNumber,
    required this.prizes,
    required this.isPublished,
    required this.isBumper,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LotteryResultModel.fromJson(Map<String, dynamic> json) {
    return LotteryResultModel(
      date: json['date'] ?? '',
      id: json['id'] ?? 0,
      uniqueId: json['unique_id'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      lotteryCode: json['lottery_code'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      prizes: (json['prizes'] as List<dynamic>?)
          ?.map((item) => PrizeModel.fromJson(item))
          .toList() ?? [],
      isPublished: json['is_published'] ?? false,
      isBumper: json['is_bumper'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Helper methods for UI display
  String get formattedTitle => '$lotteryName $lotteryCode Winner List';
  
  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String get formattedDrawNumber => '$lotteryCode-$drawNumber';

  // Get prizes by type
  List<PrizeModel> getPrizesByType(String prizeType) {
    return prizes.where((prize) => prize.prizeType == prizeType).toList();
  }

  PrizeModel? getFirstPrize() {
    try {
      return prizes.firstWhere((prize) => prize.prizeType == '1st');
    } catch (e) {
      return null;
    }
  }

  PrizeModel? getConsolationPrize() {
    try {
      return prizes.firstWhere((prize) => prize.prizeType == 'consolation');
    } catch (e) {
      return null;
    }
  }

  List<PrizeModel> getOrderedPrizes() {
    final prizeOrder = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    List<PrizeModel> orderedPrizes = [];
    
    for (String prizeType in prizeOrder) {
      final prizesOfType = getPrizesByType(prizeType);
      orderedPrizes.addAll(prizesOfType);
    }
    
    // Add consolation at the end
    final consolation = getConsolationPrize();
    if (consolation != null) {
      orderedPrizes.add(consolation);
    }
    
    return orderedPrizes;
  }
}

class PrizeModel {
  final String prizeType;
  final double prizeAmount;
  final bool placeUsed;
  final bool isGrid;
  final String? ticketNumbers; // For grid-based prizes
  final List<TicketModel> tickets; // For individual ticket prizes

  PrizeModel({
    required this.prizeType,
    required this.prizeAmount,
    required this.placeUsed,
    required this.isGrid,
    this.ticketNumbers,
    required this.tickets,
  });

  factory PrizeModel.fromJson(Map<String, dynamic> json) {
    return PrizeModel(
      prizeType: json['prize_type'] ?? '',
      prizeAmount: double.tryParse(json['prize_amount']?.toString() ?? '0') ?? 0.0,
      placeUsed: json['place_used'] ?? false,
      isGrid: json['is_grid'] ?? false,
      ticketNumbers: json['ticket_numbers'], // Can be null
      tickets: (json['tickets'] as List<dynamic>?)
          ?.map((item) => TicketModel.fromJson(item))
          .toList() ?? [],
    );
  }

  // Helper methods for UI display
  String get formattedPrizeAmount {
    final amountInt = prizeAmount.toInt();
    if (amountInt >= 10000000) {
      final crores = amountInt / 10000000;
      return '₹ ${amountInt.toString()}/-  [${crores.toInt()} Crore${crores > 1 ? 's' : ''}]';
    } else if (amountInt >= 100000) {
      final lakhs = amountInt / 100000;
      return '₹ ${amountInt.toString()}/-  [${lakhs.toInt()} Lakh${lakhs > 1 ? 's' : ''}]';
    } else {
      return '₹ ${amountInt.toString()}/-';
    }
  }

  String get prizeTypeFormatted {
    switch (prizeType) {
      case '1st':
        return '1st Prize';
      case '2nd':
        return '2nd Prize';
      case '3rd':
        return '3rd Prize';
      case '4th':
        return '4th Prize';
      case '5th':
        return '5th Prize';
      case '6th':
        return '6th Prize';
      case '7th':
        return '7th Prize';
      case '8th':
        return '8th Prize';
      case '9th':
        return '9th Prize';
      case '10th':
        return '10th Prize';
      case 'consolation':
        return 'Consolation Prize';
      default:
        return prizeType;
    }
  }

  // Get all ticket numbers as a list (works for both formats)
  List<String> get allTicketNumbers {
    List<String> allNumbers = [];
    
    // Add tickets from tickets array
    for (var ticket in tickets) {
      allNumbers.add(ticket.ticketNumber);
    }
    
    // Add tickets from ticket_numbers string
    if (ticketNumbers != null && ticketNumbers!.isNotEmpty) {
      allNumbers.addAll(
        ticketNumbers!
            .split(' ')
            .where((ticket) => ticket.trim().isNotEmpty)
            .toList()
      );
    }
    
    return allNumbers;
  }

  // Get ticket numbers with locations (only for tickets array)
  List<TicketModel> get ticketsWithLocation => tickets;

  // Check if this prize has location information
  bool get hasLocationInfo => tickets.isNotEmpty && placeUsed;

  // Check if this is a single ticket prize
  bool get isSingleTicket => allTicketNumbers.length == 1;

  // For backward compatibility - returns the old format
  @Deprecated('Use allTicketNumbers instead')
  List<String> get ticketNumbersList => allTicketNumbers;
}

class TicketModel {
  final String ticketNumber;
  final String? location;

  TicketModel({
    required this.ticketNumber,
    this.location,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      ticketNumber: json['ticket_number'] ?? '',
      location: json['location'],
    );
  }

  String get displayText {
    if (location != null && location!.isNotEmpty) {
      return '$ticketNumber ($location)';
    }
    return ticketNumber;
  }
}