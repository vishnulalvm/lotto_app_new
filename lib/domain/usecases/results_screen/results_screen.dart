import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/repositories/results_screen/result_screen.dart';

class LotteryResultDetailsUseCase {
  final LotteryResultDetailsRepository _repository;

  LotteryResultDetailsUseCase(this._repository);

  Future<LotteryResultDetailsModel> execute(String uniqueId) async {
    return await _repository.getLotteryResultDetails(uniqueId);
  }
}