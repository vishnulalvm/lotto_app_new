import 'package:lotto_app/data/datasource/api/news_screen/news_api_service.dart';
import 'package:lotto_app/data/models/news_screen/news_model.dart';

abstract class NewsRepository {
  Future<NewsResponseModel> getNews();
}

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiService _apiService;

  NewsRepositoryImpl({required NewsApiService apiService})
      : _apiService = apiService;

  @override
  Future<NewsResponseModel> getNews() async {
    try {
      final response = await _apiService.getNews();
      
      // Validate response
      if (response.status != 'success') {
        throw Exception('API returned error status: ${response.status}');
      }
      
      if (response.data.isEmpty) {
        throw Exception('No news data available');
      }
      
      return response;
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }
}