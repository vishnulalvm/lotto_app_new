import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

class TicketCheckApiService {

  static const String checkTicketEndpoint = '/results/check-ticket/';

  Future<TicketCheckResponseModel> checkTicket({
    required String ticketNumber,
    required String phoneNumber,
    required String date,
  }) async {
    try {
      final request = TicketCheckRequestModel(
        ticketNumber: ticketNumber,
        phoneNumber: phoneNumber,
        date: date,
      );

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}$checkTicketEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return TicketCheckResponseModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to check ticket: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking ticket: $e');
    }
  }
}
