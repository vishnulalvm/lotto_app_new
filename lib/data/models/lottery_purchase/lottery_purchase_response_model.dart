class LotteryPurchaseResponseModel {
  final int id;
  final String userId;
  final String lotteryNumber;
  final String lotteryName;
  final double ticketPrice;
  final String purchaseDate;
  final String message;

  LotteryPurchaseResponseModel({
    required this.id,
    required this.userId,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.ticketPrice,
    required this.purchaseDate,
    required this.message,
  });

  factory LotteryPurchaseResponseModel.fromJson(Map<String, dynamic> json) {
    return LotteryPurchaseResponseModel(
      id: json['id'],
      userId: json['user_id'],
      lotteryNumber: json['lottery_number'],
      lotteryName: json['lottery_name'],
      ticketPrice: json['ticket_price'].toDouble(),
      purchaseDate: json['purchase_date'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lottery_number': lotteryNumber,
      'lottery_name': lotteryName,
      'ticket_price': ticketPrice,
      'purchase_date': purchaseDate,
      'message': message,
    };
  }
}