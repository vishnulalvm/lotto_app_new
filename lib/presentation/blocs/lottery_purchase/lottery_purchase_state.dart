import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_delete_response_model.dart';

abstract class LotteryPurchaseState {}

class LotteryPurchaseInitial extends LotteryPurchaseState {}

class LotteryPurchaseLoading extends LotteryPurchaseState {}

class LotteryPurchaseSuccess extends LotteryPurchaseState {
  final LotteryPurchaseResponseModel response;

  LotteryPurchaseSuccess(this.response);
}

class LotteryPurchaseError extends LotteryPurchaseState {
  final String message;
  final bool isDuplicate;

  LotteryPurchaseError(this.message, {this.isDuplicate = false});
}

class LotteryPurchaseDeleteLoading extends LotteryPurchaseState {}

class LotteryPurchaseDeleteSuccess extends LotteryPurchaseState {
  final LotteryPurchaseDeleteResponseModel response;

  LotteryPurchaseDeleteSuccess(this.response);
}

class LotteryPurchaseDeleteError extends LotteryPurchaseState {
  final String message;

  LotteryPurchaseDeleteError(this.message);
}