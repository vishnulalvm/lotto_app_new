import 'package:lotto_app/data/datasource/api/feedback_screen/feedback_api_service.dart';

class FeedbackRepository {
  final FeedbackApiService apiService;

  FeedbackRepository({required this.apiService});

  Future<bool> submitFeedback({
    required String phoneNumber,
    required String screenName,
    required String message,
  }) async {
    try {
      final response = await apiService.submitFeedback(
        phoneNumber: phoneNumber,
        screenName: screenName,
        message: message,
      );

      // Check if the response indicates success
      return response['success'] == true;
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }
}
