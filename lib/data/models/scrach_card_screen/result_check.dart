class TicketCheckRequestModel {
  final String ticketNumber;
  final String phoneNumber;
  final String date;

  TicketCheckRequestModel({
    required this.ticketNumber,
    required this.phoneNumber,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticket_number': ticketNumber,
      'phone_number': phoneNumber,
      'date': date,
    };
  }
}

class TicketCheckResponseModel {
  final String message;
  final bool wonPrize;
  final bool resultPublished;
  final String? ticketNumber;
  final String? last4Digits;
  final String? requestedDate;
  final String? lotteryName;
  final bool isPreviousResult;
  
  // Prize details (only when won_prize is true and result_published is true)
  final PrizeDetails? prizeDetails;
  
  // Lottery info (when won_prize is false)
  final LotteryInfo? lotteryInfo;
  
  // Latest result (when result_published is false)
  final LatestResult? latestResult;

  TicketCheckResponseModel({
    required this.message,
    required this.wonPrize,
    required this.resultPublished,
    this.ticketNumber,
    this.last4Digits,
    this.requestedDate,
    this.lotteryName,
    this.isPreviousResult = false,
    this.prizeDetails,
    this.lotteryInfo,
    this.latestResult,
  });

  factory TicketCheckResponseModel.fromJson(Map<String, dynamic> json) {
    return TicketCheckResponseModel(
      message: json['message'] ?? '',
      wonPrize: json['won_prize'] ?? false,
      resultPublished: json['result_published'] ?? false,
      ticketNumber: json['ticket_number'],
      last4Digits: json['last_4_digits'],
      requestedDate: json['requested_date'],
      lotteryName: json['lottery_name'],
      isPreviousResult: json['isPrevious_result'] ?? false,
      prizeDetails: json['prize_details'] != null 
          ? PrizeDetails.fromJson(json['prize_details']) 
          : null,
      lotteryInfo: json['lottery_info'] != null 
          ? LotteryInfo.fromJson(json['lottery_info']) 
          : null,
      latestResult: json['latest_result'] != null 
          ? LatestResult.fromJson(json['latest_result']) 
          : null,
    );
  }

  // Helper methods for UI display
  String get formattedPrize {
    if (prizeDetails != null) {
      return '₹${prizeDetails!.prizeAmount.toInt().toString()}/-';
    } else if (latestResult?.prizeDetails != null) {
      return '₹${latestResult!.prizeDetails!.prizeAmount.toInt().toString()}/-';
    }
    return '₹0/-';
  }
  
  String get formattedLotteryInfo {
    if (prizeDetails != null) {
      return '${prizeDetails!.lotteryName} ${prizeDetails!.lotteryCode}-${prizeDetails!.drawNumber}';
    } else if (lotteryInfo != null) {
      return '${lotteryInfo!.name} ${lotteryInfo!.code}-${lotteryInfo!.drawNumber}';
    } else if (latestResult != null) {
      return '$lotteryName ${latestResult!.drawNumber}';
    }
    return '';
  }
  
  bool get isWinner => wonPrize;
  
  String get displayTicketNumber => ticketNumber ?? '';
  
  String get prizeType => prizeDetails?.prizeType ?? latestResult?.prizeDetails?.prizeType ?? '';
  
  String get matchType => prizeDetails?.matchType ?? latestResult?.prizeDetails?.matchType ?? '';
  
  String get place => prizeDetails?.place ?? '';
  
  String get drawDate {
    if (prizeDetails != null) {
      return prizeDetails!.date;
    } else if (lotteryInfo != null) {
      return lotteryInfo!.date;
    } else if (latestResult != null) {
      return latestResult!.date;
    }
    return '';
  }
}

class PrizeDetails {
  final String prizeType;
  final double prizeAmount;
  final String lotteryName;
  final String lotteryCode;
  final String drawNumber;
  final String date;
  final String uniqueId;
  final String winningTicketNumber;
  final String yourTicketNumber;
  final String matchType;
  final String place;

  PrizeDetails({
    required this.prizeType,
    required this.prizeAmount,
    required this.lotteryName,
    required this.lotteryCode,
    required this.drawNumber,
    required this.date,
    required this.uniqueId,
    required this.winningTicketNumber,
    required this.yourTicketNumber,
    required this.matchType,
    required this.place,
  });

  factory PrizeDetails.fromJson(Map<String, dynamic> json) {
    return PrizeDetails(
      prizeType: json['prize_type'] ?? '',
      prizeAmount: (json['prize_amount'] ?? 0.0).toDouble(),
      lotteryName: json['lottery_name'] ?? '',
      lotteryCode: json['lottery_code'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      date: json['date'] ?? '',
      uniqueId: json['unique_id'] ?? '',
      winningTicketNumber: json['winning_ticket_number'] ?? '',
      yourTicketNumber: json['your_ticket_number'] ?? '',
      matchType: json['match_type'] ?? '',
      place: json['place'] ?? '',
    );
  }
}

class LotteryInfo {
  final String name;
  final String code;
  final String date;
  final String drawNumber;
  final String uniqueId;

  LotteryInfo({
    required this.name,
    required this.code,
    required this.date,
    required this.drawNumber,
    required this.uniqueId,
  });

  factory LotteryInfo.fromJson(Map<String, dynamic> json) {
    return LotteryInfo(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      date: json['date'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      uniqueId: json['unique_id'] ?? '',
    );
  }
}

class LatestResult {
  final String date;
  final String drawNumber;
  final String uniqueId;
  final double? totalPrizeAmount;
  final LatestPrizeDetails? prizeDetails;

  LatestResult({
    required this.date,
    required this.drawNumber,
    required this.uniqueId,
    this.totalPrizeAmount,
    this.prizeDetails,
  });

  factory LatestResult.fromJson(Map<String, dynamic> json) {
    return LatestResult(
      date: json['date'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      uniqueId: json['unique_id'] ?? '',
      totalPrizeAmount: json['total_prize_amount']?.toDouble(),
      prizeDetails: json['prize_details'] != null 
          ? LatestPrizeDetails.fromJson(json['prize_details']) 
          : null,
    );
  }
}

class LatestPrizeDetails {
  final String prizeType;
  final double prizeAmount;
  final String matchType;
  final String winningTicketNumber;

  LatestPrizeDetails({
    required this.prizeType,
    required this.prizeAmount,
    required this.matchType,
    required this.winningTicketNumber,
  });

  factory LatestPrizeDetails.fromJson(Map<String, dynamic> json) {
    return LatestPrizeDetails(
      prizeType: json['prize_type'] ?? '',
      prizeAmount: (json['prize_amount'] ?? 0.0).toDouble(),
      matchType: json['match_type'] ?? '',
      winningTicketNumber: json['winning_ticket_number'] ?? '',
    );
  }
}