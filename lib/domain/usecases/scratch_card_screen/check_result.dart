import 'package:lotto_app/core/utils/barcode_validator.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';
import 'package:lotto_app/data/repositories/scratch_card_screen/check_result.dart';

class TicketCheckUseCase {
  final TicketCheckRepository _repository;

  TicketCheckUseCase(this._repository);

  Future<TicketCheckResponseModel> execute({
    required String ticketNumber,
    required String phoneNumber,
    required String date,
  }) async {
    // Validate ticket number format
    if (!BarcodeValidator.isValidLotteryTicket(ticketNumber)) {
      throw Exception(BarcodeValidator.getValidationError(ticketNumber));
    }

    return await _repository.checkTicket(
      ticketNumber: BarcodeValidator.cleanTicketNumber(ticketNumber),
      phoneNumber: phoneNumber,
      date: date,
    );
  }
}
