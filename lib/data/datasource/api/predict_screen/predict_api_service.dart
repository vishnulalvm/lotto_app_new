import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/predict_screen/predict_request_model.dart';
import 'package:lotto_app/data/models/predict_screen/predict_response_model.dart';

class PredictApiService {
  final Dio _dio;

  PredictApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<PredictResponseModel> getPrediction(PredictRequestModel request) async {
    try {
      final response = await _dio.post(
        ApiConstants.predict,
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return PredictResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting prediction: $e');
    }
  }

  Future<PredictResponseModel> getPredictionData() async {
    try {
      final response = await _dio.get(ApiConstants.predict);
      if (response.statusCode == 200) {
        return PredictResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to get prediction data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting prediction data: $e');
    }
  }
}