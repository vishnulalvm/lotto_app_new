abstract class TicketCheckEvent {}

class CheckTicketEvent extends TicketCheckEvent {
  final String ticketNumber;
  final String phoneNumber;
  final String date;

  CheckTicketEvent({
    required this.ticketNumber,
    required this.phoneNumber,
    required this.date,
  });
}

class ResetTicketCheckEvent extends TicketCheckEvent {}
