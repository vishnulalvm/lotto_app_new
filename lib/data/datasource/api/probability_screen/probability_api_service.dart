import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/probability_screen/probability_request_model.dart';
import 'package:lotto_app/data/models/probability_screen/probability_response_model.dart';

class ProbabilityApiService {
  final Dio _dio;

  ProbabilityApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<ProbabilityResponseModel> getProbability(ProbabilityRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.lotteryPercentage,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return ProbabilityResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get probability: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      throw Exception('Error getting probability: $e');
    }
  }
}