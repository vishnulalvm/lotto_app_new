import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';

class LotteryResultDetailsApiService {
  Future<Map<String, dynamic>> getLotteryResultDetails(String uniqueId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.resultDetails}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'unique_id': uniqueId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get lottery result details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting lottery result details: $e');
    }
  }
}
