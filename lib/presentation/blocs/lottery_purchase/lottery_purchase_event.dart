import 'package:equatable/equatable.dart';

abstract class LotteryPurchaseEvent extends Equatable {
  const LotteryPurchaseEvent();

  @override
  List<Object?> get props => [];
}

class PurchaseLottery extends LotteryPurchaseEvent {
  final String userId;
  final String lotteryNumber;
  final String lotteryName;
  final int ticketPrice;
  final String purchaseDate;

  const PurchaseLottery({
    required this.userId,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.ticketPrice,
    required this.purchaseDate,
  });

  @override
  List<Object?> get props =>
      [userId, lotteryNumber, lotteryName, ticketPrice, purchaseDate];
}

class DeleteLotteryPurchase extends LotteryPurchaseEvent {
  final String userId;
  final int id;

  const DeleteLotteryPurchase({
    required this.userId,
    required this.id,
  });

  @override
  List<Object?> get props => [userId, id];
}
