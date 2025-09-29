enum LotteryEntryStatus {
  pending,
  won,
  lost;

  static LotteryEntryStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return LotteryEntryStatus.won;
      case 'lost':
        return LotteryEntryStatus.lost;
      case 'pending':
      default:
        return LotteryEntryStatus.pending;
    }
  }
}

class LotteryEntryModel {
  final int id;
  final String? lotteryUniqueId;
  final int slNo;
  final String lotteryNumber;
  final String lotteryName;
  final double price;
  final String purchaseDate;
  final double? winnings;
  final LotteryEntryStatus status;

  LotteryEntryModel({
    required this.id,
    this.lotteryUniqueId,
    required this.slNo,
    required this.lotteryNumber,
    required this.lotteryName,
    required this.price,
    required this.purchaseDate,
    this.winnings,
    required this.status,
  });

  factory LotteryEntryModel.fromJson(Map<String, dynamic> json) {
    return LotteryEntryModel(
      id: json['id'] ?? 0,
      lotteryUniqueId: json['lottery_unique_id'],
      slNo: json['sl_no'] ?? 0,
      lotteryNumber: json['lottery_number'] ?? '',
      lotteryName: json['lottery_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      purchaseDate: json['purchase_date'] ?? '',
      winnings: json['winnings']?.toDouble(),
      status: LotteryEntryStatus.fromString(json['status'] ?? 'pending'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lottery_unique_id': lotteryUniqueId,
      'sl_no': slNo,
      'lottery_number': lotteryNumber,
      'lottery_name': lotteryName,
      'price': price,
      'purchase_date': purchaseDate,
      'winnings': winnings,
      'status': status.name,
    };
  }

  // Convert to the existing LotteryEntry class used in UI
  DateTime get dateAdded => DateTime.tryParse(purchaseDate) ?? DateTime.now();
  double get winningAmount => winnings ?? 0.0;
  String get uniqueId => lotteryUniqueId ?? '$id-$lotteryNumber';
}