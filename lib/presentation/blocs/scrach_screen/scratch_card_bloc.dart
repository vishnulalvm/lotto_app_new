import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/core/services/just_miss_service.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';
import 'package:lotto_app/data/repositories/results_screen/result_screen.dart';
import 'package:lotto_app/domain/usecases/scratch_card_screen/check_result.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_event.dart';
import 'package:lotto_app/presentation/blocs/scrach_screen/scratch_card_state.dart';

class TicketCheckBloc extends Bloc<TicketCheckEvent, TicketCheckState> {
  final TicketCheckUseCase _useCase;
  final LotteryResultDetailsRepository _resultDetailsRepository;

  TicketCheckBloc(
    this._useCase,
    this._resultDetailsRepository,
  ) : super(TicketCheckInitial()) {
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

      // Compute just miss data for losers when result is published
      final shouldComputeJustMiss = _shouldComputeJustMiss(result);

      if (shouldComputeJustMiss) {
        final enhancedResult = await _computeJustMissData(result);
        emit(TicketCheckSuccess(enhancedResult));
      } else {
        emit(TicketCheckSuccess(result));
      }
    } catch (e) {
      emit(TicketCheckFailure(e.toString()));
    }
  }

  /// Check if we should compute just miss data
  /// Only compute for losers (currentLoser, previousLoser) when result is published
  bool _shouldComputeJustMiss(TicketCheckResponseModel result) {
    final isLoser = result.responseType == ResponseType.currentLoser ||
        result.responseType == ResponseType.previousLoser;

    final hasUniqueId = result.previousResult.uniqueId.isNotEmpty;

    return isLoser && hasUniqueId;
  }

  /// Fetch full lottery result and compute just miss data
  Future<TicketCheckResponseModel> _computeJustMissData(
    TicketCheckResponseModel result,
  ) async {
    try {
      final uniqueId = result.previousResult.uniqueId;
      final ticketNumber = result.ticketNumber;

      // Fetch full lottery result details
      final fullResultDetails = await _resultDetailsRepository.getLotteryResultDetails(uniqueId);
      final fullResult = fullResultDetails.result;

      // Compute just miss data using the service
      final justMissData = JustMissService.findJustMissNumbers(
        ticketNumber: ticketNumber,
        fullResult: fullResult,
      );

      // Create enhanced response with just miss data
      return TicketCheckResponseModel(
        statusCode: result.statusCode,
        status: result.status,
        resultStatus: result.resultStatus,
        message: result.message,
        data: TicketCheckData(
          ticketNumber: result.data.ticketNumber,
          lotteryName: result.data.lotteryName,
          requestedDate: result.data.requestedDate,
          wonPrize: result.data.wonPrize,
          resultPublished: result.data.resultPublished,
          isPreviousResult: result.data.isPreviousResult,
          previousResult: PreviousResult(
            date: result.previousResult.date,
            drawNumber: result.previousResult.drawNumber,
            uniqueId: result.previousResult.uniqueId,
            totalPrizeAmount: result.previousResult.totalPrizeAmount,
            prizeDetails: result.previousResult.prizeDetails,
            justMissData: justMissData, // Add computed just miss data
          ),
        ),
      );
    } catch (e) {
      // If just miss computation fails, return original result
      // Don't fail the whole ticket check just because just miss failed
      return result;
    }
  }

  void _onResetTicketCheck(
    ResetTicketCheckEvent event,
    Emitter<TicketCheckState> emit,
  ) {
    emit(TicketCheckInitial());
  }
}
