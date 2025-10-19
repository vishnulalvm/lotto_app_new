import 'package:lotto_app/data/datasource/api/probability_screen/probability_api_service.dart';
import 'package:lotto_app/data/models/probability_screen/probability_request_model.dart';
import 'package:lotto_app/data/models/probability_screen/probability_response_model.dart';

abstract class ProbabilityRepository {
  Future<ProbabilityResponseModel> getProbability(ProbabilityRequestModel request);
}

class ProbabilityRepositoryImpl implements ProbabilityRepository {
  final ProbabilityApiService apiService;

  ProbabilityRepositoryImpl({required this.apiService});

  @override
  Future<ProbabilityResponseModel> getProbability(ProbabilityRequestModel request) async {
    try {
      final response = await apiService.getProbability(request);
      return response;
    } catch (e) {
      throw Exception('Failed to get probability from repository: $e');
    }
  }
}