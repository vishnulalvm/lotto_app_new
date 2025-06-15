import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

abstract class TicketCheckState {}

class TicketCheckInitial extends TicketCheckState {}

class TicketCheckLoading extends TicketCheckState {}

class TicketCheckSuccess extends TicketCheckState {
  final TicketCheckResponseModel result;

  TicketCheckSuccess(this.result);
}

class TicketCheckFailure extends TicketCheckState {
  final String error;

  TicketCheckFailure(this.error);
}
