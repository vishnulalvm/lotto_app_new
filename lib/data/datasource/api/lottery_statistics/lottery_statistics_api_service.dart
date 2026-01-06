import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_request_model.dart';
import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';

class LotteryStatisticsApiService {
  final Dio _dio;

  LotteryStatisticsApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<LotteryStatisticsResponseModel> getLotteryStatistics(
    LotteryStatisticsRequestModel request,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.lotteryStatistics,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return LotteryStatisticsResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get lottery statistics: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}