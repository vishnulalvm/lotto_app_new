import 'package:lotto_app/data/models/probability_screen/probability_request_model.dart';
import 'package:lotto_app/data/models/probability_screen/probability_response_model.dart';
import 'package:lotto_app/data/repositories/probability_screen/probability_repository.dart';

class ProbabilityUseCase {
  final ProbabilityRepository repository;

  ProbabilityUseCase({required this.repository});

  Future<ProbabilityResponseModel> execute(
      ProbabilityRequestModel request) async {
    try {
      return await repository.getProbability(request);
    } catch (e) {
      throw Exception('Failed to get probability: $e');
    }
  }

  /// Helper method to extract lottery name from lottery number
  String extractLotteryName(String lotteryNumber) {
    final upperCaseNumber = lotteryNumber.toUpperCase();

    if (upperCaseNumber.startsWith('V')) {
      return 'vishu bumper';
    } else if (upperCaseNumber.startsWith('BR')) {
      return 'summer bumper';
    } else if (upperCaseNumber.startsWith('P')) {
      return 'karunya plus';
    } else if (upperCaseNumber.startsWith('R')) {
      return 'suvarna_keralam';
    } else if (upperCaseNumber.startsWith('K')) {
      return 'karunya';
    } else if (upperCaseNumber.startsWith('M')) {
      return 'samrudhi';
    } else if (upperCaseNumber.startsWith('B')) {
      return 'bhagyathara';
    } else if (upperCaseNumber.startsWith('S')) {
      return 'sthree sakthi';
    } else if (upperCaseNumber.startsWith('D')) {
      return 'dhanalekshmi';
    } else {
      // Default if no match
      return 'karunya';
    }
  }

  /// Helper method to create a request with extracted lottery name
  ProbabilityRequestModel createRequest(String lotteryNumber) {
    return ProbabilityRequestModel(
      lotteryName: extractLotteryName(lotteryNumber),
      lotteryNumber: lotteryNumber,
    );
  }
}
