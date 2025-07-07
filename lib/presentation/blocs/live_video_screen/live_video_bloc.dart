import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/live_video_screen/live_video_usecase.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_event.dart';
import 'package:lotto_app/presentation/blocs/live_video_screen/live_video_state.dart';

class LiveVideoBloc extends Bloc<LiveVideoEvent, LiveVideoState> {
  final LiveVideoUseCase _useCase;

  LiveVideoBloc(this._useCase) : super(LiveVideoInitial()) {
    on<LoadLiveVideosEvent>(_onLoadLiveVideos);
    on<RefreshLiveVideosEvent>(_onRefreshLiveVideos);
  }

  Future<void> _onLoadLiveVideos(
    LoadLiveVideosEvent event,
    Emitter<LiveVideoState> emit,
  ) async {
    try {
      emit(LiveVideoLoading());
      final videos = await _useCase.execute();
      emit(LiveVideoLoaded(videos));
    } catch (e) {
      emit(LiveVideoError(e.toString()));
    }
  }

  Future<void> _onRefreshLiveVideos(
    RefreshLiveVideosEvent event,
    Emitter<LiveVideoState> emit,
  ) async {
    try {
      // Show refreshing state if we already have data
      if (state is LiveVideoLoaded) {
        emit(LiveVideoLoading(isRefreshing: true));
      } else {
        emit(LiveVideoLoading());
      }
      
      final videos = await _useCase.execute();
      emit(LiveVideoLoaded(videos));
    } catch (e) {
      emit(LiveVideoError(e.toString()));
    }
  }
}