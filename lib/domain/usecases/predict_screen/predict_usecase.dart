import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';
import 'package:lotto_app/data/repositories/predict_screen/predict_repository.dart';

class PredictUseCase {
  final PredictRepository _repository;

  PredictUseCase(this._repository);

  /// Execute prediction request
  Future<PredictResponseModel> execute(PredictRequestModel request) async {
    return await _repository.getPrediction(request);
  }

  /// Get prediction data for display
  Future<PredictResponseModel> getPredictionData({bool forceRefresh = false}) async {
    return await _repository.getPredictionData(forceRefresh: forceRefresh);
  }

  /// Get cached prediction data
  Future<PredictResponseModel?> getCachedPredictionData() async {
    return await _repository.getCachedPredictionData();
  }

  /// Refresh prediction data in background and return updated data
  Future<PredictResponseModel?> refreshPredictionDataInBackground() async {
    try {
      await _repository.refreshPredictionDataInBackground();
      return await _repository.getCachedPredictionData();
    } catch (e) {
      return null;
    }
  }
}