abstract class LotteryPurchaseEvent {}

class PurchaseLottery extends LotteryPurchaseEvent {
  final String userId;
  final String lotteryNumber;
  final String lotteryName;
  final int ticketPrice;
  final String purchaseDate;

  PurchaseLottery({
    required this.userId,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.ticketPrice,
    required this.purchaseDate,
  });
}

class DeleteLotteryPurchase extends LotteryPurchaseEvent {
  final String userId;
  final int id;

  DeleteLotteryPurchase({
    required this.userId,
    required this.id,
  });
}