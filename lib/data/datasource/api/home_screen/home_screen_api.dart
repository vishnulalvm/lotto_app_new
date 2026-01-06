import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';

class HomeScreenResultsApiService {
  final Dio _dio;

  HomeScreenResultsApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<Map<String, dynamic>> getHomeScreenResults() async {
    try {
      final response = await _dio.get(ApiConstants.homeResults);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get lottery results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting lottery results: $e');
    }
  }
}