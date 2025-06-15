import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';

class HomeScreenResultsApiService {
  Future<Map<String, dynamic>> getHomeScreenResults() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.homeResults),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get lottery results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting lottery results: $e');
    }
  }
}