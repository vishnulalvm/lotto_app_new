import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';

class LotteryResultDetailsApiService {
  final Dio _dio;

  LotteryResultDetailsApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<Map<String, dynamic>> getLotteryResultDetails(String uniqueId) async {
    try {
      final response = await _dio.post(
        ApiConstants.resultDetails,
        data: {
          'unique_id': uniqueId,
        },
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get lottery result details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting lottery result details: $e');
    }
  }
}
