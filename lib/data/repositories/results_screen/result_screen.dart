import 'package:lotto_app/data/datasource/api/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

class LotteryResultDetailsRepository {
  final LotteryResultDetailsApiService _apiService;

  LotteryResultDetailsRepository(this._apiService);

  Future<LotteryResultDetailsModel> getLotteryResultDetails(String uniqueId) async {
    try {
      final json = await _apiService.getLotteryResultDetails(uniqueId);
      return LotteryResultDetailsModel.fromJson(json);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}