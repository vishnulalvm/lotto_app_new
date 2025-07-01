import 'package:lotto_app/data/models/news_screen/news_model.dart';

abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoading extends NewsState {}

class NewsLoaded extends NewsState {
  final List<NewsModel> news;

  NewsLoaded({required this.news});
}

class NewsError extends NewsState {
  final String error;

  NewsError({required this.error});
}