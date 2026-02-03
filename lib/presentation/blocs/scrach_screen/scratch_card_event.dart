import 'package:equatable/equatable.dart';

abstract class TicketCheckEvent extends Equatable {
  const TicketCheckEvent();

  @override
  List<Object?> get props => [];
}

class CheckTicketEvent extends TicketCheckEvent {
  final String ticketNumber;
  final String phoneNumber;
  final String date;

  const CheckTicketEvent({
    required this.ticketNumber,
    required this.phoneNumber,
    required this.date,
  });

  @override
  List<Object?> get props => [ticketNumber, phoneNumber, date];
}

class ResetTicketCheckEvent extends TicketCheckEvent {
  const ResetTicketCheckEvent();
}
