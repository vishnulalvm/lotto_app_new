import 'package:dio/dio.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

class TicketCheckApiService {
  final Dio _dio;

  TicketCheckApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

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

print("request.toJson() ${request.toJson()}");
      final response = await _dio.post(
        checkTicketEndpoint,
        data: request.toJson(),
      );
      print(response.data);
      print(response.statusCode);
      if (response.statusCode == 200) {
        print("response.data ${response.data.toString()}");
        return TicketCheckResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to check ticket: ${response.statusCode}');
      }
    } catch (e) {
      print("Error checking ticket: $e");
      throw Exception('Error checking ticket: $e');
    }
  }
}
