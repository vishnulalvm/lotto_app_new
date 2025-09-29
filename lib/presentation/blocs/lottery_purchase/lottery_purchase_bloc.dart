import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/lottery_purchase/lottery_purchase_usecase.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_event.dart';
import 'package:lotto_app/presentation/blocs/lottery_purchase/lottery_purchase_state.dart';

class LotteryPurchaseBloc extends Bloc<LotteryPurchaseEvent, LotteryPurchaseState> {
  final LotteryPurchaseUseCase useCase;

  LotteryPurchaseBloc({required this.useCase}) : super(LotteryPurchaseInitial()) {
    on<PurchaseLottery>(_onPurchaseLottery);
    on<DeleteLotteryPurchase>(_onDeleteLotteryPurchase);
  }

  Future<void> _onPurchaseLottery(
    PurchaseLottery event,
    Emitter<LotteryPurchaseState> emit,
  ) async {
    emit(LotteryPurchaseLoading());
    try {
      final response = await useCase.execute(
        userId: event.userId,
        lotteryNumber: event.lotteryNumber,
        lotteryName: event.lotteryName,
        ticketPrice: event.ticketPrice,
        purchaseDate: event.purchaseDate,
      );
      
      emit(LotteryPurchaseSuccess(response));
    } catch (e) {
      // Check if it's a duplicate purchase error
      if (e.toString().contains('already purchased this lottery number')) {
        emit(LotteryPurchaseError(e.toString(), isDuplicate: true));
      } else {
        emit(LotteryPurchaseError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteLotteryPurchase(
    DeleteLotteryPurchase event,
    Emitter<LotteryPurchaseState> emit,
  ) async {
    emit(LotteryPurchaseDeleteLoading());
    try {
      final response = await useCase.deleteLotteryPurchase(
        userId: event.userId,
        id: event.id,
      );
      
      emit(LotteryPurchaseDeleteSuccess(response));
    } catch (e) {
      emit(LotteryPurchaseDeleteError(e.toString()));
    }
  }
}