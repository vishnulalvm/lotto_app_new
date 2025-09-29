class ChallengeStatisticsModel {
  final double totalExpense;
  final double totalWinnings;
  final int totalTickets;
  final double winRate;
  final double netResult;

  ChallengeStatisticsModel({
    required this.totalExpense,
    required this.totalWinnings,
    required this.totalTickets,
    required this.winRate,
    required this.netResult,
  });

  factory ChallengeStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ChallengeStatisticsModel(
      totalExpense: (json['total_expense'] ?? 0).toDouble(),
      totalWinnings: (json['total_winnings'] ?? 0).toDouble(),
      totalTickets: json['total_tickets'] ?? 0,
      winRate: (json['win_rate'] ?? 0.0).toDouble(),
      netResult: (json['net_result'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_expense': totalExpense,
      'total_winnings': totalWinnings,
      'total_tickets': totalTickets,
      'win_rate': winRate,
      'net_result': netResult,
    };
  }
}