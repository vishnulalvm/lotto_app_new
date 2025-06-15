import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/repositories/home_screen/home_screen_repo.dart';

class HomeScreenResultsUseCase {
  final HomeScreenResultsRepository _repository;

  HomeScreenResultsUseCase(this._repository);

  Future<HomeScreenResultsModel> execute() async {
    return await _repository.getHomeScreenResults();
  }
}