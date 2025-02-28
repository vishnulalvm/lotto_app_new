// lottery_result_model.dart
class LotteryResult {
  final String title;
  final String prizeAmount;
  final String winningNumber;
  final String location;
  final String consolationPrize;
  final List<String> consolationNumbers;
  final DateTime drawDate;

  LotteryResult({
    required this.title,
    required this.prizeAmount,
    required this.winningNumber,
    required this.location,
    required this.consolationPrize,
    required this.consolationNumbers,
    required this.drawDate,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      title: json['title'] ?? '',
      prizeAmount: json['prize_amount'] ?? '',
      winningNumber: json['winning_number'] ?? '',
      location: json['location'] ?? '',
      consolationPrize: json['consolation_prize'] ?? '',
      consolationNumbers: List<String>.from(json['consolation_numbers'] ?? []),
      drawDate: DateTime.parse(json['draw_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'prize_amount': prizeAmount,
      'winning_number': winningNumber,
      'location': location,
      'consolation_prize': consolationPrize,
      'consolation_numbers': consolationNumbers,
      'draw_date': drawDate.toIso8601String(),
    };
  }
}