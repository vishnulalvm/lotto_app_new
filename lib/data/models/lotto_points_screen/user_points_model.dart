class UserPointsModel {
  final String status;
  final String message;
  final UserPointsData data;

  UserPointsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UserPointsModel.fromJson(Map<String, dynamic> json) {
    return UserPointsModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: UserPointsData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class UserPointsData {
  final String userId;
  final int totalPoints;
  final List<PointHistoryItem> history;
  final List<CashbackHistoryItem> cashbackHistory;

  UserPointsData({
    required this.userId,
    required this.totalPoints,
    required this.history,
    required this.cashbackHistory,
  });

  factory UserPointsData.fromJson(Map<String, dynamic> json) {
    return UserPointsData(
      userId: json['user_id'] ?? '',
      totalPoints: json['total_points'] ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((item) => PointHistoryItem.fromJson(item))
              .toList() ??
          [],
      cashbackHistory: (json['cashback_history'] as List<dynamic>?)
              ?.map((item) => CashbackHistoryItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'history': history.map((item) => item.toJson()).toList(),
      'cashback_history': cashbackHistory.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods for UI display
  String get formattedTotalPoints => totalPoints.toString();

  // Get unclaimed cashback items
  List<CashbackHistoryItem> get unclaimedCashback => 
      cashbackHistory.where((item) => !item.isClaimed).toList();

  // Get claimed cashback items  
  List<CashbackHistoryItem> get claimedCashback => 
      cashbackHistory.where((item) => item.isClaimed).toList();

  // Calculate total unclaimed cashback amount
  double get totalUnclaimedCashback => 
      unclaimedCashback.fold(0.0, (sum, item) => sum + item.amount);

  // Calculate total claimed cashback amount
  double get totalClaimedCashback => 
      claimedCashback.fold(0.0, (sum, item) => sum + item.amount);

  // Check if user has any unclaimed cashback
  bool get hasUnclaimedCashback => unclaimedCashback.isNotEmpty;

  // Get recent point history (last 5 items)
  List<PointHistoryItem> get recentHistory => 
      history.take(5).toList();
}

class PointHistoryItem {
  final String lotteryName;
  final String date;
  final int pointsEarned;

  PointHistoryItem({
    required this.lotteryName,
    required this.date,
    required this.pointsEarned,
  });

  factory PointHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointHistoryItem(
      lotteryName: json['lottery_name'] ?? '',
      date: json['date'] ?? '',
      pointsEarned: json['points_earned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lottery_name': lotteryName,
      'date': date,
      'points_earned': pointsEarned,
    };
  }
}

class CashbackHistoryItem {
  final String cashbackId;
  final String date;
  final double amount;
  final bool isClaimed;

  CashbackHistoryItem({
    required this.cashbackId,
    required this.date,
    required this.amount,
    required this.isClaimed,
  });

  factory CashbackHistoryItem.fromJson(Map<String, dynamic> json) {
    return CashbackHistoryItem(
      cashbackId: json['cashback_id'] ?? '',
      date: json['date'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      isClaimed: json['isClaimed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cashback_id': cashbackId,
      'date': date,
      'amount': amount,
      'isClaimed': isClaimed,
    };
  }

  String get formattedAmount {
    final amountInt = amount.toInt();
    return '₹ $amountInt';
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String get statusText {
    if (isClaimed) return 'Claimed';
    if (isExpired) return 'Expired';
    return 'Available';
  }

  // Check if cashback has expired (7 days from received date)
  bool get isExpired {
    try {
      final dateTime = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;
      return difference > 7;
    } catch (e) {
      return false;
    }
  }

  // Check if cashback is available (not claimed and not expired)
  bool get isAvailable => !isClaimed && !isExpired;
}

class UserPointsRequestModel {
  final String phoneNumber;

  UserPointsRequestModel({
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
    };
  }
}