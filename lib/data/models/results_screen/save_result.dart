import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

part 'save_result.g.dart';

@HiveType(typeId: 5)
class SavedLotteryResult extends HiveObject {
  @HiveField(0)
  final String uniqueId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final String prize;

  @HiveField(4)
  final String winner;

  @HiveField(5)
  final List<String> consolationPrizes;

  @HiveField(6)
  final DateTime savedAt;

  @HiveField(7)
  bool isFavorite;

  SavedLotteryResult({
    required this.uniqueId,
    required this.title,
    required this.date,
    required this.prize,
    required this.winner,
    required this.consolationPrizes,
    required this.savedAt,
    this.isFavorite = false,
  });

  // Convert from HomeScreenResultModel
  factory SavedLotteryResult.fromHomeScreenResult(HomeScreenResultModel result) {
    return SavedLotteryResult(
      uniqueId: result.uniqueId,
      title: result.formattedTitle,
      date: result.formattedDate,
      prize: result.formattedFirstPrize,
      winner: result.formattedWinner,
      consolationPrizes: result.consolationTicketsList,
      savedAt: DateTime.now(),
    );
  }

  // Convert from LotteryResultModel
  factory SavedLotteryResult.fromLotteryResult(LotteryResultModel result) {
    final firstPrize = result.getFirstPrize();
    final consolationPrize = result.getConsolationPrize();
    
    return SavedLotteryResult(
      uniqueId: result.uniqueId,
      title: result.formattedTitle,
      date: result.formattedDate,
      prize: firstPrize?.formattedPrizeAmount ?? 'No First Prize',
      winner: firstPrize?.ticketsWithLocation.isNotEmpty == true 
          ? firstPrize!.ticketsWithLocation.first.displayText
          : firstPrize?.allTicketNumbers.isNotEmpty == true
              ? firstPrize!.allTicketNumbers.first
              : 'No Winner',
      consolationPrizes: consolationPrize?.allTicketNumbers ?? [],
      savedAt: DateTime.now(),
    );
  }

  // Convert to Map for UI display (backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'uniqueId': uniqueId,
      'title': title,
      'date': date,
      'prize': prize,
      'winner': winner,
      'consolationPrizes': consolationPrizes,
      'isFavorite': isFavorite,
      'savedAt': savedAt.toIso8601String(),
    };
  }
}