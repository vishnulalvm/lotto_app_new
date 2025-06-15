import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/scratch_card_screen/check_result.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_event.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_state.dart';

class TicketCheckBloc extends Bloc<TicketCheckEvent, TicketCheckState> {
  final TicketCheckUseCase _useCase;

  TicketCheckBloc(this._useCase) : super(TicketCheckInitial()) {
    on<CheckTicketEvent>(_onCheckTicket);
    on<ResetTicketCheckEvent>(_onResetTicketCheck);
  }

  Future<void> _onCheckTicket(
    CheckTicketEvent event,
    Emitter<TicketCheckState> emit,
  ) async {
    try {
      emit(TicketCheckLoading());
      
      final result = await _useCase.execute(
        ticketNumber: event.ticketNumber,
        phoneNumber: event.phoneNumber,
        date: event.date,
      );
      
      emit(TicketCheckSuccess(result));
    } catch (e) {
      emit(TicketCheckFailure(e.toString()));
    }
  }

  void _onResetTicketCheck(
    ResetTicketCheckEvent event,
    Emitter<TicketCheckState> emit,
  ) {
    emit(TicketCheckInitial());
  }
}
