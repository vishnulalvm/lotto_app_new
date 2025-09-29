import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';

abstract class LotteryPurchaseState {}

class LotteryPurchaseInitial extends LotteryPurchaseState {}

class LotteryPurchaseLoading extends LotteryPurchaseState {}

class LotteryPurchaseSuccess extends LotteryPurchaseState {
  final LotteryPurchaseResponseModel response;

  LotteryPurchaseSuccess(this.response);
}

class LotteryPurchaseError extends LotteryPurchaseState {
  final String message;

  LotteryPurchaseError(this.message);
}