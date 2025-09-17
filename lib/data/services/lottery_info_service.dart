/// Service for lottery-related information and utilities
class LotteryInfoService {
  
  /// Gets the lottery name for today based on weekday
  static String getLotteryNameForToday() {
    final now = DateTime.now();
    // If it's after 3 PM, show tomorrow's lottery
    final targetDate = now.hour >= 15 ? now.add(const Duration(days: 1)) : now;
    final weekday = targetDate.weekday;

    return switch (weekday) {
      DateTime.sunday => 'SAMRUDHI',
      DateTime.monday => 'BHAGYATHARA',
      DateTime.tuesday => 'STHREE SAKTHI',
      DateTime.wednesday => 'DHANALEKSHMI',
      DateTime.thursday => 'KARUNYA PLUS',
      DateTime.friday => 'SUVARNA KERALAM',
      DateTime.saturday => 'KARUNYA',
      _ => 'KARUNYA',
    };
  }

  /// Gets the ordinal suffix for prize numbers
  static String getOrdinalSuffix(int number) {
    return switch (number) {
      5 || 6 || 7 || 8 || 9 => 'th',
      _ => 'th',
    };
  }

  /// Gets the formatted prize type string
  static String getPrizeTypeFormatted(int prizeType) {
    final suffix = getOrdinalSuffix(prizeType);
    return '$prizeType$suffix Prize';
  }

  /// Gets available prize types for dropdown
  static List<int> getAvailablePrizeTypes() {
    return [5, 6, 7, 8, 9];
  }

  /// Gets the default prize type
  static int getDefaultPrizeType() {
    return 5; // 5th prize as default
  }

  /// Checks if the given prize type is valid
  static bool isValidPrizeType(int prizeType) {
    return getAvailablePrizeTypes().contains(prizeType);
  }
}