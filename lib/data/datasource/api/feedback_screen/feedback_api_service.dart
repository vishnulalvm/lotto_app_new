import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';

class FeedbackApiService {
  final http.Client client;

  FeedbackApiService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> submitFeedback({
    required String phoneNumber,
    required String screenName,
    required String message,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.feedback),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phoneNumber,
          'screen_name': screenName,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit feedback: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
