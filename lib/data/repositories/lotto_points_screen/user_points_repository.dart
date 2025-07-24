import 'package:lotto_app/data/datasource/api/lotto_points_screen/user_points_api_service.dart';
import 'package:lotto_app/data/models/lotto_points_screen/user_points_model.dart';

abstract class UserPointsRepository {
  Future<UserPointsModel> getUserPoints(String phoneNumber);
}

class UserPointsRepositoryImpl implements UserPointsRepository {
  final UserPointsApiService _apiService;

  UserPointsRepositoryImpl({UserPointsApiService? apiService})
      : _apiService = apiService ?? UserPointsApiService();

  @override
  Future<UserPointsModel> getUserPoints(String phoneNumber) async {
    try {
      return await _apiService.getUserPoints(phoneNumber);
    } catch (e) {
      print('Error in UserPointsRepository: $e');
      throw Exception('Repository error: $e');
    }
  }
}