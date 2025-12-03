import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/probability_screen/probability_request_model.dart';
import 'package:lotto_app/data/models/probability_screen/probability_response_model.dart';

class ProbabilityApiService {
  final http.Client client;

  ProbabilityApiService({http.Client? client}) : client = client ?? http.Client();

  Future<ProbabilityResponseModel> getProbability(ProbabilityRequestModel request) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.lotteryPercentage),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return ProbabilityResponseModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to get probability: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting probability: $e');
    }
  }
}