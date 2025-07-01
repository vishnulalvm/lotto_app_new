import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotto_app/domain/usecases/news_screen/news_usecase.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_event.dart';
import 'package:lotto_app/presentation/blocs/news_screen/news_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsUseCase _newsUseCase;

  NewsBloc({required NewsUseCase newsUseCase})
      : _newsUseCase = newsUseCase,
        super(NewsInitial()) {
    on<LoadNewsEvent>(_onLoadNews);
    on<RefreshNewsEvent>(_onRefreshNews);
  }

  Future<void> _onLoadNews(
    LoadNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    emit(NewsLoading());
    try {
      final news = await _newsUseCase.execute();
      emit(NewsLoaded(news: news));
    } catch (e) {
      emit(NewsError(error: e.toString()));
    }
  }

  Future<void> _onRefreshNews(
    RefreshNewsEvent event,
    Emitter<NewsState> emit,
  ) async {
    try {
      final news = await _newsUseCase.execute();
      emit(NewsLoaded(news: news));
    } catch (e) {
      emit(NewsError(error: e.toString()));
    }
  }
}