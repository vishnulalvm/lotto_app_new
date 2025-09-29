import 'package:lotto_app/data/models/lottery_statistics/lottery_statistics_response_model.dart';
import 'package:lotto_app/data/repositories/lottery_statistics/lottery_statistics_repository.dart';

class LotteryStatisticsUseCase {
  final LotteryStatisticsRepository _repository;

  LotteryStatisticsUseCase(this._repository);

  /// Execute with optional force refresh and background refresh callback
  Future<LotteryStatisticsResponseModel> execute({
    required String userId,
    bool forceRefresh = false,
    Function(LotteryStatisticsResponseModel)? onBackgroundRefreshComplete,
  }) async {
    return await _repository.getLotteryStatistics(
      userId,
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