import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/lotto_points_screen/user_points_usecase.dart';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_event.dart';
import 'package:lotto_app/presentation/blocs/lotto_points_screen/user_points_state.dart';

class UserPointsBloc extends Bloc<UserPointsEvent, UserPointsState> {
  final UserPointsUseCase _userPointsUseCase;

  UserPointsBloc({UserPointsUseCase? userPointsUseCase})
      : _userPointsUseCase = userPointsUseCase ?? UserPointsUseCase(),
        super(UserPointsInitial()) {
    on<FetchUserPointsEvent>(_onFetchUserPoints);
    on<RefreshUserPointsEvent>(_onRefreshUserPoints);
  }

  Future<void> _onFetchUserPoints(
    FetchUserPointsEvent event,
    Emitter<UserPointsState> emit,
  ) async {
    emit(UserPointsLoading());
    
    try {
      final userPoints = await _userPointsUseCase.execute(event.phoneNumber);
      emit(UserPointsLoaded(userPoints: userPoints));
    } catch (e) {
      emit(UserPointsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshUserPoints(
    RefreshUserPointsEvent event,
    Emitter<UserPointsState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserPointsLoaded) {
      emit(UserPointsRefreshing(userPoints: currentState.userPoints));
    }
    
    try {
      final userPoints = await _userPointsUseCase.execute(event.phoneNumber);
      emit(UserPointsLoaded(userPoints: userPoints));
    } catch (e) {
      if (currentState is UserPointsLoaded) {
        emit(currentState);
      } else {
        emit(UserPointsError(message: e.toString()));
      }
    }
  }
}