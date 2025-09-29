import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_request_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';

class LotteryStatisticsApiService {
  final http.Client client;

  LotteryStatisticsApiService({http.Client? client}) : client = client ?? http.Client();

  Future<LotteryStatisticsResponseModel> getLotteryStatistics(
    LotteryStatisticsRequestModel request,
  ) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.lotteryStatistics),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LotteryStatisticsResponseModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get lottery statistics: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}