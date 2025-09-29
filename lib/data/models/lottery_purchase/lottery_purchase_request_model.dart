class LotteryPurchaseRequestModel {
  final String userId;
  final String? lotteryNumber;
  final String? lotteryName;
  final int? ticketPrice;
  final String? purchaseDate;
  final int? id;
  final bool? isDeleted;

  LotteryPurchaseRequestModel({
    required this.userId,
    this.lotteryNumber,
    this.lotteryName,
    this.ticketPrice,
    this.purchaseDate,
    this.id,
    this.isDeleted,
  });

  // Factory constructor for create operation
  factory LotteryPurchaseRequestModel.create({
    required String userId,
    required String lotteryNumber,
    required String lotteryName,
    required int ticketPrice,
    required String purchaseDate,
  }) {
    return LotteryPurchaseRequestModel(
      userId: userId,
      lotteryNumber: lotteryNumber,
      lotteryName: lotteryName,
      ticketPrice: ticketPrice,
      purchaseDate: purchaseDate,
    );
  }

  // Factory constructor for delete operation
  factory LotteryPurchaseRequestModel.delete({
    required String userId,
    required int id,
    bool isDeleted = true,
  }) {
    return LotteryPurchaseRequestModel(
      userId: userId,
      id: id,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'user_id': userId,
    };

    // Add fields for create operation
    if (lotteryNumber != null) json['lottery_number'] = lotteryNumber;
    if (lotteryName != null) json['lottery_name'] = lotteryName;
    if (ticketPrice != null) json['ticket_price'] = ticketPrice;
    if (purchaseDate != null) json['purchase_date'] = purchaseDate;

    // Add fields for delete operation
    if (id != null) json['id'] = id;
    if (isDeleted != null) json['is_deleted'] = isDeleted;

    return json;
  }

  // Helper methods to identify operation type
  bool get isCreateOperation => lotteryNumber != null && lotteryName != null;
  bool get isDeleteOperation => id != null && isDeleted == true;
}