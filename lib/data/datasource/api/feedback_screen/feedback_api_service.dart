import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';

class FeedbackApiService {
  final Dio _dio;

  FeedbackApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<Map<String, dynamic>> submitFeedback({
    required String phoneNumber,
    required String screenName,
    required String message,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.feedback,
        data: {
          'phone_number': phoneNumber,
          'screen_name': screenName,
          'message': message,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to submit feedback: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
