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
  final bool isPreviousResult;

  // Common fields
  final String? ticketNumber;
  final String? last4Digits;
  final String? requestedDate;
  final String? lotteryName;

  // Prize details (Case 1: won_prize=true, result_published=true, isPrevious_result=false)
  final PrizeDetails? prizeDetails;
  final int? totalPrizes;
  final double? totalPrizeAmount;

  // Lottery info (Case 2: won_prize=false, result_published=true, isPrevious_result=false)
  final LotteryInfo? lotteryInfo;

  // Latest result (Case 3 & 4: result_published=false, isPrevious_result=true)
  final LatestResult? latestResult;

  TicketCheckResponseModel({
    required this.message,
    required this.wonPrize,
    required this.resultPublished,
    required this.isPreviousResult,
    this.ticketNumber,
    this.last4Digits,
    this.requestedDate,
    this.lotteryName,
    this.prizeDetails,
    this.totalPrizes,
    this.totalPrizeAmount,
    this.lotteryInfo,
    this.latestResult,
  });

  factory TicketCheckResponseModel.fromJson(Map<String, dynamic> json) {
    return TicketCheckResponseModel(
      message: json['message'] ?? '',
      wonPrize: json['won_prize'] ?? false,
      resultPublished: json['result_published'] ?? false,
      isPreviousResult: json['isPrevious_result'] ?? false,
      ticketNumber: json['ticket_number'],
      last4Digits: json['last_4_digits'],
      requestedDate: json['requested_date'],
      lotteryName: json['lottery_name'],
      prizeDetails: json['prize_details'] != null
          ? PrizeDetails.fromJson(json['prize_details'])
          : null,
      totalPrizes: json['total_prizes'],
      totalPrizeAmount: json['total_prize_amount']?.toDouble(),
      lotteryInfo: json['lottery_info'] != null
          ? LotteryInfo.fromJson(json['lottery_info'])
          : null,
      latestResult: json['latest_result'] != null
          ? LatestResult.fromJson(json['latest_result'])
          : null,
    );
  }

  // Response type identification helpers
  ResponseType get responseType {
    if (resultPublished && wonPrize && !isPreviousResult) {
      return ResponseType.currentWinner; // Case 1
    } else if (resultPublished && !wonPrize && !isPreviousResult) {
      return ResponseType.currentLoser; // Case 2
    } else if (!resultPublished && wonPrize && isPreviousResult) {
      return ResponseType.previousWinner; // Case 3
    } else if (!resultPublished && !wonPrize && isPreviousResult) {
      return ResponseType.previousLoser; // Case 4
    }
    return ResponseType.unknown;
  }

  // Helper methods for UI display
  String get formattedPrize {
    switch (responseType) {
      case ResponseType.currentWinner:
        if (prizeDetails != null) {
          return '₹${_formatNumber(prizeDetails!.prizeAmount)}/-';
        }
        break;
      case ResponseType.previousWinner:
        if (latestResult?.prizeDetails != null) {
          return '₹${_formatNumber(latestResult!.prizeDetails!.prizeAmount)}/-';
        }
        break;
      case ResponseType.currentLoser:
      case ResponseType.previousLoser:
      case ResponseType.unknown:
        return '₹0/-';
    }
    return '₹0/-';
  }

  String get formattedLotteryInfo {
    switch (responseType) {
      case ResponseType.currentWinner:
        if (prizeDetails != null) {
          return '${prizeDetails!.lotteryName} ${prizeDetails!.drawNumber}';
        }
        break;
      case ResponseType.currentLoser:
        if (lotteryInfo != null) {
          return '${lotteryInfo!.name} ${lotteryInfo!.drawNumber}';
        }
        break;
      case ResponseType.previousWinner:
      case ResponseType.previousLoser:
        if (latestResult != null && lotteryName != null) {
          return '$lotteryName ${latestResult!.drawNumber}';
        }
        break;
      case ResponseType.unknown:
        break;
    }
    return '';
  }

  String get lotteryCode {
    switch (responseType) {
      case ResponseType.currentWinner:
        return prizeDetails?.lotteryCode ?? '';
      case ResponseType.currentLoser:
        return lotteryInfo?.code ?? '';
      case ResponseType.previousWinner:
      case ResponseType.previousLoser:
        // For previous results, code might not be available in the response
        return '';
      case ResponseType.unknown:
        return '';
    }
  }

  bool get isWinner => wonPrize;

  String get displayTicketNumber {
    return ticketNumber ?? prizeDetails?.yourTicketNumber ?? '';
  }

  String get prizeType {
    switch (responseType) {
      case ResponseType.currentWinner:
        return prizeDetails?.prizeType ?? '';
      case ResponseType.previousWinner:
        return latestResult?.prizeDetails?.prizeType ?? '';
      case ResponseType.currentLoser:
      case ResponseType.previousLoser:
      case ResponseType.unknown:
        return '';
    }
  }

  String get matchType {
    switch (responseType) {
      case ResponseType.currentWinner:
        return prizeDetails?.matchType ?? '';
      case ResponseType.previousWinner:
        return latestResult?.prizeDetails?.matchType ?? '';
      case ResponseType.currentLoser:
      case ResponseType.previousLoser:
      case ResponseType.unknown:
        return '';
    }
  }

  String get place {
    return prizeDetails?.place ?? '';
  }

  String get drawDate {
    switch (responseType) {
      case ResponseType.currentWinner:
        return prizeDetails?.date ?? '';
      case ResponseType.currentLoser:
        return lotteryInfo?.date ?? '';
      case ResponseType.previousWinner:
      case ResponseType.previousLoser:
        return latestResult?.date ?? '';
      case ResponseType.unknown:
        return '';
    }
  }

  String get winningTicketNumber {
    switch (responseType) {
      case ResponseType.currentWinner:
        return prizeDetails?.winningTicketNumber ?? '';
      case ResponseType.previousWinner:
        return latestResult?.prizeDetails?.winningTicketNumber ?? '';
      case ResponseType.currentLoser:
      case ResponseType.previousLoser:
      case ResponseType.unknown:
        return '';
    }
  }

  String get uniqueId {
    switch (responseType) {
      case ResponseType.currentWinner:
        return prizeDetails?.uniqueId ?? '';
      case ResponseType.currentLoser:
        return lotteryInfo?.uniqueId ?? '';
      case ResponseType.previousWinner:
      case ResponseType.previousLoser:
        return latestResult?.uniqueId ?? '';
      case ResponseType.unknown:
        return '';
    }
  }

  // Helper method to format numbers with commas
  String _formatNumber(double number) {
    String numStr = number.toInt().toString();
    String result = '';
    int counter = 0;

    for (int i = numStr.length - 1; i >= 0; i--) {
      if (counter == 3) {
        result = ',$result';
        counter = 0;
      }
      result = numStr[i] + result;
      counter++;
    }

    return result;
  }
}

enum ResponseType {
  currentWinner, // won_prize=true, result_published=true, isPrevious_result=false
  currentLoser, // won_prize=false, result_published=true, isPrevious_result=false
  previousWinner, // won_prize=true, result_published=false, isPrevious_result=true
  previousLoser, // won_prize=false, result_published=false, isPrevious_result=true
  unknown,
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
