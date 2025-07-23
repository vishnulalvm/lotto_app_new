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

  UserPointsData({
    required this.userId,
    required this.totalPoints,
    required this.history,
  });

  factory UserPointsData.fromJson(Map<String, dynamic> json) {
    return UserPointsData(
      userId: json['user_id'] ?? '',
      totalPoints: json['total_points'] ?? 0,
      history: (json['history'] as List<dynamic>?)
              ?.map((item) => PointHistoryItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_points': totalPoints,
      'history': history.map((item) => item.toJson()).toList(),
    };
  }
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