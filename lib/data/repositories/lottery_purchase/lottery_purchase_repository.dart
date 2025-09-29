import 'package:lotto_app/data/datasource/api/lottery_purchase/lottery_purchase_api_service.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_request_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';

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
    final request = LotteryPurchaseRequestModel(
      userId: userId,
      lotteryNumber: lotteryNumber,
      lotteryName: lotteryName,
      ticketPrice: ticketPrice,
      purchaseDate: purchaseDate,
    );

    return await apiService.purchaseLottery(request);
  }
}