import 'package:lotto_app/data/datasource/api/predict_screen/predict_api_service.dart';
import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';

abstract class PredictRepository {
  Future<PredictResponseModel> getPrediction(PredictRequestModel request);
}

class PredictRepositoryImpl implements PredictRepository {
  final PredictApiService _apiService;

  PredictRepositoryImpl(this._apiService);

  @override
  Future<PredictResponseModel> getPrediction(PredictRequestModel request) async {
    try {
      return await _apiService.getPrediction(request);
    } catch (e) {
      throw Exception('Failed to get prediction: $e');
    }
  }
}