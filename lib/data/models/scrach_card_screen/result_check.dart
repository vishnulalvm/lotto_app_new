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
  final double prize;
  final String matchedWith;
  final String lotteryName;
  final String lotteryCode;
  final String drawNumber;
  final String date;
  final String uniqueId;
  final String ticketNumber;

  TicketCheckResponseModel({
    required this.message,
    required this.prize,
    required this.matchedWith,
    required this.lotteryName,
    required this.lotteryCode,
    required this.drawNumber,
    required this.date,
    required this.uniqueId,
    required this.ticketNumber,
  });

  factory TicketCheckResponseModel.fromJson(Map<String, dynamic> json) {
    return TicketCheckResponseModel(
      message: json['message'] ?? '',
      prize: double.tryParse(json['prize']?.toString() ?? '0') ?? 0.0,
      matchedWith: json['matched_with'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      lotteryCode: json['lottery_code'] ?? '',
      drawNumber: json['draw_number'] ?? '',
      date: json['date'] ?? '',
      uniqueId: json['unique_id'] ?? '',
      ticketNumber: json['ticket_number'] ?? '',
    );
  }

  // Helper methods for UI display
  String get formattedPrize => '₹${prize.toInt().toString()}/-';
  
  String get formattedLotteryInfo => '$lotteryName $lotteryCode-$drawNumber';
  
  bool get isWinner => prize > 0;
  
  String get displayTicketNumber {
    // If the ticket number from API is different (like "8851"), 
    // we might want to show the full scanned number instead
    return ticketNumber;
  }
}
