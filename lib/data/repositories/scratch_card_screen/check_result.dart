import 'package:lotto_app/data/datasource/api/scratch_card_screen/result_checker.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

class TicketCheckRepository {
  final TicketCheckApiService _apiService;

  TicketCheckRepository(this._apiService);

  Future<TicketCheckResponseModel> checkTicket({
    required String ticketNumber,
    required String phoneNumber,
    required String date,
  }) async {
    return await _apiService.checkTicket(
      ticketNumber: ticketNumber,
      phoneNumber: phoneNumber,
      date: date,
    );
  }
}