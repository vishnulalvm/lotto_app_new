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
  final int statusCode;
  final String status;
  final String resultStatus;
  final String message;
  final TicketCheckData data;

  TicketCheckResponseModel({
    required this.statusCode,
    required this.status,
    required this.resultStatus,
    required this.message,
    required this.data,
  });

  factory TicketCheckResponseModel.fromJson(Map<String, dynamic> json) {
    return TicketCheckResponseModel(
      statusCode: json['statusCode'] ?? 200,
      status: json['status'] ?? '',
      resultStatus: json['resultStatus'] ?? '',
      message: json['message'] ?? '',
      data: TicketCheckData.fromJson(json['data'] ?? {}),
    );
  }

  // Convenience getters that delegate to data
  bool get wonPrize => data.wonPrize;
  bool get resultPublished => data.resultPublished;
  bool get isPreviousResult => data.isPreviousResult;
  String get ticketNumber => data.ticketNumber;
  String get lotteryName => data.lotteryName;
  String get requestedDate => data.requestedDate;
  PreviousResult get previousResult => data.previousResult;

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
    } else if (!resultPublished && !wonPrize && !isPreviousResult) {
      return ResponseType.resultNotPublished; // Case 5
    }
    return ResponseType.unknown;
  }

  // Helper methods for UI display
  String get formattedPrize {
    if (previousResult.prizeDetails?.prizeAmount != null && 
        previousResult.prizeDetails!.prizeAmount > 0) {
      return '₹${_formatNumber(previousResult.prizeDetails!.prizeAmount)}/-';
    }
    return '₹0/-';
  }

  String get formattedLotteryInfo {
    if (lotteryName.isNotEmpty && previousResult.drawNumber.isNotEmpty) {
      return '$lotteryName ${previousResult.drawNumber}';
    }
    return lotteryName;
  }

  String get lotteryCode {
    // Lottery code is not provided in the new API structure
    return '';
  }

  bool get isWinner => wonPrize;

  String get displayTicketNumber => ticketNumber;

  String get prizeType {
    return previousResult.prizeDetails?.prizeType ?? '';
  }

  String get matchType {
    return previousResult.prizeDetails?.matchType ?? '';
  }

  String get place {
    // Place is not provided in the new API structure
    return '';
  }

  String get drawDate {
    return previousResult.date;
  }

  String get winningTicketNumber {
    return previousResult.prizeDetails?.winningTicketNumber ?? '';
  }

  String get uniqueId {
    return previousResult.uniqueId;
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

class TicketCheckData {
  final String ticketNumber;
  final String lotteryName;
  final String requestedDate;
  final bool wonPrize;
  final bool resultPublished;
  final bool isPreviousResult;
  final PreviousResult previousResult;

  TicketCheckData({
    required this.ticketNumber,
    required this.lotteryName,
    required this.requestedDate,
    required this.wonPrize,
    required this.resultPublished,
    required this.isPreviousResult,
    required this.previousResult,
  });

  factory TicketCheckData.fromJson(Map<String, dynamic> json) {
    return TicketCheckData(
      ticketNumber: json['ticketNumber'] ?? '',
      lotteryName: json['lotteryName'] ?? '',
      requestedDate: json['requestedDate'] ?? '',
      wonPrize: json['wonPrize'] ?? false,
      resultPublished: json['resultPublished'] ?? false,
      isPreviousResult: json['isPreviousResult'] ?? false,
      previousResult: PreviousResult.fromJson(json['previousResult'] ?? {}),
    );
  }
}

class PreviousResult {
  final String date;
  final String drawNumber;
  final String uniqueId;
  final double totalPrizeAmount;
  final PrizeDetails? prizeDetails;
  final JustMissData? justMissData;

  PreviousResult({
    required this.date,
    required this.drawNumber,
    required this.uniqueId,
    required this.totalPrizeAmount,
    this.prizeDetails,
    this.justMissData,
  });

  factory PreviousResult.fromJson(Map<String, dynamic> json) {
    return PreviousResult(
      date: json['date'] ?? '',
      drawNumber: json['drawNumber'] ?? '',
      uniqueId: json['uniqueId'] ?? '',
      totalPrizeAmount: (json['totalPrizeAmount'] ?? 0.0).toDouble(),
      prizeDetails: json['prizeDetails'] != null &&
                   json['prizeDetails'] is Map<String, dynamic>
          ? _parsePrizeDetails(json['prizeDetails'])
          : null,
      justMissData: json['justMissData'] != null &&
                   json['justMissData'] is Map<String, dynamic>
          ? JustMissData.fromJson(json['justMissData'])
          : null,
    );
  }

  static PrizeDetails? _parsePrizeDetails(Map<String, dynamic> prizeDetailsJson) {
    // Handle empty object case from API (case 5)
    if (prizeDetailsJson.isEmpty) {
      return null;
    }
    
    // Check if it has meaningful data
    final prizeType = prizeDetailsJson['prizeType'] ?? '';
    final prizeAmount = (prizeDetailsJson['prizeAmount'] ?? 0.0).toDouble();
    final matchType = prizeDetailsJson['matchType'] ?? '';
    final winningTicketNumber = prizeDetailsJson['winningTicketNumber'] ?? '';
    
    // If all fields are empty/zero, treat as null
    if (prizeType.isEmpty && prizeAmount == 0.0 && matchType.isEmpty && winningTicketNumber.isEmpty) {
      return null;
    }
    
    return PrizeDetails.fromJson(prizeDetailsJson);
  }
}

class PrizeDetails {
  final String prizeType;
  final double prizeAmount;
  final String matchType;
  final String winningTicketNumber;

  PrizeDetails({
    required this.prizeType,
    required this.prizeAmount,
    required this.matchType,
    required this.winningTicketNumber,
  });

  factory PrizeDetails.fromJson(Map<String, dynamic> json) {
    return PrizeDetails(
      prizeType: json['prizeType'] ?? '',
      prizeAmount: (json['prizeAmount'] ?? 0.0).toDouble(),
      matchType: json['matchType'] ?? '',
      winningTicketNumber: json['winningTicketNumber'] ?? '',
    );
  }
}

enum ResponseType {
  currentWinner, // won_prize=true, result_published=true, isPrevious_result=false
  currentLoser, // won_prize=false, result_published=true, isPrevious_result=false
  previousWinner, // won_prize=true, result_published=false, isPrevious_result=true
  previousLoser, // won_prize=false, result_published=false, isPrevious_result=true
  resultNotPublished, // won_prize=false, result_published=false, isPrevious_result=false
  unknown,
}

class JustMissData {
  final bool hasJustMiss;
  final List<JustMissMatch> shuffleMatches;
  final List<JustMissMatch> oneNumberMatches;
  final List<JustMissMatch> twoNumberMatches;

  JustMissData({
    required this.hasJustMiss,
    required this.shuffleMatches,
    required this.oneNumberMatches,
    required this.twoNumberMatches,
  });

  factory JustMissData.fromJson(Map<String, dynamic> json) {
    return JustMissData(
      hasJustMiss: json['hasJustMiss'] ?? false,
      shuffleMatches: (json['shuffleMatches'] as List<dynamic>?)
              ?.map((item) => JustMissMatch.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      oneNumberMatches: (json['oneNumberMatches'] as List<dynamic>?)
              ?.map((item) => JustMissMatch.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      twoNumberMatches: (json['twoNumberMatches'] as List<dynamic>?)
              ?.map((item) => JustMissMatch.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasAnyMatches =>
      shuffleMatches.isNotEmpty ||
      oneNumberMatches.isNotEmpty ||
      twoNumberMatches.isNotEmpty;
}

class JustMissMatch {
  final String ticketNumber;
  final String prizeType;
  final double prizeAmount;

  JustMissMatch({
    required this.ticketNumber,
    required this.prizeType,
    required this.prizeAmount,
  });

  factory JustMissMatch.fromJson(Map<String, dynamic> json) {
    return JustMissMatch(
      ticketNumber: json['ticketNumber'] ?? '',
      prizeType: json['prizeType'] ?? '',
      prizeAmount: (json['prizeAmount'] ?? 0.0).toDouble(),
    );
  }

  String get formattedPrize {
    if (prizeAmount > 0) {
      return '₹${_formatNumber(prizeAmount)}/-';
    }
    return '₹0/-';
  }

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