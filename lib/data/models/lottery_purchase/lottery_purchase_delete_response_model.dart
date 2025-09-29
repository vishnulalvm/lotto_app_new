class LotteryPurchaseDeleteResponseModel {
  final String message;

  LotteryPurchaseDeleteResponseModel({
    required this.message,
  });

  factory LotteryPurchaseDeleteResponseModel.fromJson(Map<String, dynamic> json) {
    return LotteryPurchaseDeleteResponseModel(
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
    };
  }
}