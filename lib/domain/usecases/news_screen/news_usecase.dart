import 'package:lotto_app/data/models/news_screen/news_model.dart';
import 'package:lotto_app/data/repositories/news_screen/news_repository.dart';

class NewsUseCase {
  final NewsRepository _repository;

  NewsUseCase(this._repository);

  Future<List<NewsModel>> execute() async {
    try {
      final response = await _repository.getNews();
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}