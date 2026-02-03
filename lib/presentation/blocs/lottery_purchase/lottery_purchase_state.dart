import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_delete_response_model.dart';

abstract class LotteryPurchaseState extends Equatable {
  const LotteryPurchaseState();

  @override
  List<Object?> get props => [];
}

class LotteryPurchaseInitial extends LotteryPurchaseState {
  const LotteryPurchaseInitial();
}

class LotteryPurchaseLoading extends LotteryPurchaseState {
  const LotteryPurchaseLoading();
}

class LotteryPurchaseSuccess extends LotteryPurchaseState {
  final LotteryPurchaseResponseModel response;

  const LotteryPurchaseSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class LotteryPurchaseError extends LotteryPurchaseState {
  final String message;
  final bool isDuplicate;

  const LotteryPurchaseError(this.message, {this.isDuplicate = false});

  @override
  List<Object?> get props => [message, isDuplicate];
}

class LotteryPurchaseDeleteLoading extends LotteryPurchaseState {
  const LotteryPurchaseDeleteLoading();
}

class LotteryPurchaseDeleteSuccess extends LotteryPurchaseState {
  final LotteryPurchaseDeleteResponseModel response;

  const LotteryPurchaseDeleteSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class LotteryPurchaseDeleteError extends LotteryPurchaseState {
  final String message;

  const LotteryPurchaseDeleteError(this.message);

  @override
  List<Object?> get props => [message];
}
