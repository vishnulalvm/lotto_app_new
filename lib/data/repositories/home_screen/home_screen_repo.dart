import 'package:lotto_app/data/datasource/api/home_screen/home_screen_api.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';

class HomeScreenResultsRepository {
  final HomeScreenResultsApiService _apiService;

  HomeScreenResultsRepository(this._apiService);

  Future<HomeScreenResultsModel> getHomeScreenResults() async {
    try {
      final json = await _apiService.getHomeScreenResults();
      return HomeScreenResultsModel.fromJson(json);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}