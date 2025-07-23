import 'package:lotto_app/data/models/lotto_points_screen/user_points_model.dart';
import 'package:lotto_app/data/repositories/lotto_points_screen/user_points_repository.dart';

class UserPointsUseCase {
  final UserPointsRepository _repository;

  UserPointsUseCase({UserPointsRepository? repository})
      : _repository = repository ?? UserPointsRepositoryImpl();

  Future<UserPointsModel> execute(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      throw Exception('Phone number cannot be empty');
    }

    try {
      return await _repository.getUserPoints(phoneNumber);
    } catch (e) {
      throw Exception('UseCase error: $e');
    }
  }
}