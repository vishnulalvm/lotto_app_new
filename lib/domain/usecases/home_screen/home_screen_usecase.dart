import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';

class HomeScreenResultsUseCase {
  final HomeScreenResultsRepository _repository;

  HomeScreenResultsUseCase(this._repository);

  /// Execute with optional force refresh
  Future<HomeScreenResultsModel> execute({
    bool forceRefresh = false,
    Function(HomeScreenResultsModel)? onBackgroundRefreshComplete,
  }) async {
    return await _repository.getHomeScreenResults(
      forceRefresh: forceRefresh,
      onBackgroundRefreshComplete: onBackgroundRefreshComplete,
    );
  }

  /// Get data source information
  Future<DataSource> getDataSource() async {
    return await _repository.getLastDataSource();
  }

  /// Clear cached data
  Future<void> clearCache() async {
    await _repository.clearCache();
  }

  /// Get cache information
  Future<Map<String, dynamic>> getCacheInfo() async {
    return await _repository.getCacheInfo();
  }
}