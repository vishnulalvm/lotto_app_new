import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_request_model.dart';
import 'package:lotto_app/data/models/lottery_purchase/lottery_purchase_response_model.dart';

class LotteryPurchaseApiService {
  final http.Client client;

  LotteryPurchaseApiService({http.Client? client}) : client = client ?? http.Client();

  Future<LotteryPurchaseResponseModel> purchaseLottery(
    LotteryPurchaseRequestModel request,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.lotteryPurchase),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return LotteryPurchaseResponseModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to purchase lottery: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}