class LotteryPurchaseRequestModel {
  final String userId;
  final String lotteryNumber;
  final String lotteryName;
  final int ticketPrice;
  final String purchaseDate;

  LotteryPurchaseRequestModel({
    required this.userId,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.ticketPrice,
    required this.purchaseDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'lottery_number': lotteryNumber,
      'lottery_name': lotteryName,
      'ticket_price': ticketPrice,
      'purchase_date': purchaseDate,
    };
  }
}