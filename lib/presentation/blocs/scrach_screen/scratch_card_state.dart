import 'package:equatable/equatable.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

abstract class TicketCheckState extends Equatable {
  const TicketCheckState();

  @override
  List<Object?> get props => [];
}

class TicketCheckInitial extends TicketCheckState {
  const TicketCheckInitial();
}

class TicketCheckLoading extends TicketCheckState {
  const TicketCheckLoading();
}

class TicketCheckSuccess extends TicketCheckState {
  final TicketCheckResponseModel result;

  const TicketCheckSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class TicketCheckFailure extends TicketCheckState {
  final String error;

  const TicketCheckFailure(this.error);

  @override
  List<Object?> get props => [error];
}
