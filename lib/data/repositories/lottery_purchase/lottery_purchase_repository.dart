import 'package:lotto_app/data/datasource/api/lottery_purchase/lottery_purchase_api_service.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_request_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_delete_response_model.dart';

class LotteryPurchaseRepository {
  final LotteryPurchaseApiService apiService;

  LotteryPurchaseRepository({
    required this.apiService,
  });

  Future<LotteryPurchaseResponseModel> purchaseLottery(
    String userId,
    String lotteryNumber,
    String lotteryName,
    int ticketPrice,
    String purchaseDate,
  ) async {
    final request = LotteryPurchaseRequestModel.create(
      userId: userId,
      lotteryNumber: lotteryNumber,
      lotteryName: lotteryName,
      ticketPrice: ticketPrice,
      purchaseDate: purchaseDate,
    );

    return await apiService.purchaseLottery(request);
  }

  Future<LotteryPurchaseDeleteResponseModel> deleteLotteryPurchase(
    String userId,
    int id,
  ) async {
    final request = LotteryPurchaseRequestModel.delete(
      userId: userId,
      id: id,
    );

    return await apiService.deleteLotteryPurchase(request);
  }
}