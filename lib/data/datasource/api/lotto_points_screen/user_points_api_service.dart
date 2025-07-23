import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/lotto_points_screen/user_points_model.dart';

class UserPointsApiService {
  static const int timeoutDuration = 30;

  Future<UserPointsModel> getUserPoints(String phoneNumber) async {
    try {
      final requestModel = UserPointsRequestModel(phoneNumber: phoneNumber);
      
      final response = await http
          .post(
            Uri.parse('${ApiConstants.backUpUrl}${ApiConstants.userPoints}'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestModel.toJson()),
          )
          .timeout(const Duration(seconds: timeoutDuration));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return UserPointsModel.fromJson(responseData);
      } else {
        throw Exception('Failed to fetch user points: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Please check your internet connection');
      }
      throw Exception('Failed to fetch user points: $e');
    }
  }
}