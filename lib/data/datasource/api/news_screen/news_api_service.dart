import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/news_screen/news_model.dart';

class NewsApiService {
  final http.Client client;

  NewsApiService({http.Client? client}) : client = client ?? http.Client();

  Future<NewsResponseModel> getNews() async {
    try {
      final response = await client.get(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.news),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return NewsResponseModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load news: HTTP ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to connect to server: $e');
    }
  }

  void dispose() {
    client.close();
  }
}