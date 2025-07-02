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
}