import 'dart:math';

/// Service for generating fancy pattern lottery numbers
/// Generates numbers with repeating digits, palindromes, sequences, etc.
class FancyNumberGenerator {
  static final Random _random = Random();

  /// Generates 4 unique fancy pattern numbers
  static List<String> generateWeeklyFancyNumbers() {
    final numbers = <String>{};

    // Keep generating until we have 4 unique numbers
    while (numbers.length < 4) {
      final number = _generateSingleFancyNumber();
      numbers.add(number);
    }

    return numbers.toList();
  }

  /// Generates a single fancy pattern number
  static String _generateSingleFancyNumber() {
    final patternType = _random.nextInt(5);

    switch (patternType) {
      case 0:
        return _generateRepeatingDigits();
      case 1:
        return _generatePalindrome();
      case 2:
        return _generateSequential();
      case 3:
        return _generateDoublePairs();
      default:
        return _generateMirrorPattern();
    }
  }

  /// Generates repeating digit numbers (1111, 2222, 9999)
  static String _generateRepeatingDigits() {
    final digit = _random.nextInt(10);
    return digit.toString() * 4;
  }

  /// Generates palindrome numbers (1221, 3443, 9009)
  static String _generatePalindrome() {
    final d1 = _random.nextInt(10);
    final d2 = _random.nextInt(10);
    return '$d1$d2$d2$d1';
  }

  /// Generates sequential numbers (1234, 5678, 3210)
  static String _generateSequential() {
    final start = _random.nextInt(7); // 0-6 to ensure we don't exceed 9
    final ascending = _random.nextBool();

    if (ascending) {
      return '$start${start + 1}${start + 2}${start + 3}';
    } else {
      final startDesc = start + 3;
      return '$startDesc${startDesc - 1}${startDesc - 2}${startDesc - 3}';
    }
  }

  /// Generates double pair numbers (1212, 4545, 7878)
  static String _generateDoublePairs() {
    final d1 = _random.nextInt(10);
    final d2 = _random.nextInt(10);
    return '$d1$d2$d1$d2';
  }

  /// Generates mirror pattern numbers (1331, 2442, 8998)
  static String _generateMirrorPattern() {
    final outer = _random.nextInt(10);
    final inner = _random.nextInt(10);
    return '$outer$inner$inner$outer';
  }

  /// Format number with leading zeros if needed (e.g., 98 -> 0098)
  static String formatNumber(int number) {
    return number.toString().padLeft(4, '0');
  }

  /// Validates if a number is a fancy pattern
  static bool isFancyPattern(String number) {
    if (number.length != 4) return false;

    // Check repeating
    if (number[0] == number[1] &&
        number[1] == number[2] &&
        number[2] == number[3]) {
      return true;
    }

    // Check palindrome
    if (number[0] == number[3] && number[1] == number[2]) {
      return true;
    }

    // Check sequential
    final digits = number.split('').map(int.parse).toList();
    bool isSequential = true;
    for (int i = 0; i < digits.length - 1; i++) {
      if ((digits[i] + 1) != digits[i + 1] && (digits[i] - 1) != digits[i + 1]) {
        isSequential = false;
        break;
      }
    }
    if (isSequential) return true;

    // Check double pairs
    if (number[0] == number[2] && number[1] == number[3]) {
      return true;
    }

    return false;
  }
}
