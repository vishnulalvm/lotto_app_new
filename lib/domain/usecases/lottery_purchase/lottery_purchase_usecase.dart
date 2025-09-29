import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';
import 'package:lotto_app/data/repositories/lottery_purchase/lottery_purchase_repository.dart';

class LotteryPurchaseUseCase {
  final LotteryPurchaseRepository _repository;

  LotteryPurchaseUseCase(this._repository);

  Future<LotteryPurchaseResponseModel> execute({
    required String userId,
    required String lotteryNumber,
    required String lotteryName,
    required int ticketPrice,
    required String purchaseDate,
  }) async {
    return await _repository.purchaseLottery(
      userId,
      lotteryNumber,
      lotteryName,
      ticketPrice,
      purchaseDate,
    );
  }
}