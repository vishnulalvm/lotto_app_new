
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

class PatternAnalysisService {
  static Map<String, int> analyzePatterns(List<LotteryResultModel> results) {
    final Map<String, int> patternCounts = {};

    for (final result in results) {
      for (final prize in result.prizes) {
        final ticketNumbers = prize.getAllTicketNumbers();
        for (final ticketNumber in ticketNumbers) {
          if (ticketNumber.length == 4) {
            final patternType = _detectPatternType(ticketNumber);
            if (patternType != null) {
              patternCounts[patternType] = (patternCounts[patternType] ?? 0) + 1;
            }
          }
        }
      }
    }

    return patternCounts;
  }
  
  /// Get ALL ticket numbers (exactly 4 digits) that have detected patterns
  /// Used for highlighting - returns all matches, no limit
  static Set<String> getAllNumbersWithPatterns(List<LotteryResultModel> results) {
    final Set<String> matchingNumbers = {};

    for (final result in results) {
      for (final prize in result.prizes) {
        final ticketNumbers = prize.getAllTicketNumbers();
        for (final ticketNumber in ticketNumbers) {
          // Only analyze tickets that are exactly 4 digits
          if (ticketNumber.length == 4) {
            final patternType = _detectPatternType(ticketNumber);
            if (patternType != null) {
              matchingNumbers.add(ticketNumber);
            }
          }
        }
      }
    }

    return matchingNumbers;
  }

  /// Get only FANCY pattern numbers (user-friendly patterns)
  /// Excludes technical/sequential patterns that don't feel special
  static Set<String> getFancyNumbersOnly(List<LotteryResultModel> results) {
    final Set<String> fancyNumbers = {};

    // Define which patterns are considered "fancy" by users
    // Only includes truly special patterns that are rare and visually interesting
    const fancyPatternTypes = {
      'Triple Digits (AAAB)',        // Three same digits: 1711, 3373, 2228
      'Double Pair (AABB)',           // Two pairs: 5599, 6656
      'Leading Zero (000X)',          // Three zeros: 0001, 0068 (very rare)
      'Leading Zero (00XY)',          // Two zeros: 0018, 0113 (rare)
      'Round Thousands (X000)',       // Exact thousands: 7000, 8000
      'Round End Variation (X00Y)',   // Hundreds variation: 7003, 7006
      'Double + Ending Zeros (XX00)', // Double zeros at end: 4200, 2300
      'Repeating Pair (ABAB)',        // Repeating pattern: 7171, 8282
      'Mirror (ABBA)',                // Mirror/palindrome: 3993, 7177
      // Removed 'Leading Zero (0XXX)' - too common (10% of all numbers)
      // Removed 'Ending Zero Style' - XY0Z pattern is too common
    };

    for (final result in results) {
      for (final prize in result.prizes) {
        final ticketNumbers = prize.getAllTicketNumbers();
        for (final ticketNumber in ticketNumbers) {
          // Only analyze tickets that are exactly 4 digits
          if (ticketNumber.length == 4) {
            final patternType = _detectPatternType(ticketNumber);

            // Only include if it's a fancy pattern type
            if (patternType != null && fancyPatternTypes.contains(patternType)) {
              fancyNumbers.add(ticketNumber);
            }
          }
        }
      }
    }

    return fancyNumbers;
  }

  /// Get pattern examples (up to 5 per pattern) for UI display
  static Map<String, List<String>> getPatternExamples(List<LotteryResultModel> results) {
    final Map<String, Set<String>> patternExamples = {};

    for (final result in results) {
      for (final prize in result.prizes) {
        final ticketNumbers = prize.getAllTicketNumbers();
        for (final ticketNumber in ticketNumbers) {
          // Only analyze tickets that are exactly 4 digits
          if (ticketNumber.length == 4) {
            final patternType = _detectPatternType(ticketNumber);
            if (patternType != null) {
              patternExamples[patternType] ??= <String>{};
              if (patternExamples[patternType]!.length < 5) {
                patternExamples[patternType]!.add(ticketNumber);
              }
            }
          }
        }
      }
    }

    return patternExamples.map((key, value) => MapEntry(key, value.toList()));
  }
  
  static String? _detectPatternType(String number) {
    if (number.length != 4) return null;

    final digits = number.split('').map(int.parse).toList();

    // Check leading zeros patterns (most specific first)
    if (_isLeadingZeroThree(digits)) return 'Leading Zero (000X)';
    if (_isLeadingZeroTwo(digits)) return 'Leading Zero (00XY)';
    if (_isLeadingZeroOne(digits)) return 'Leading Zero (0XXX)';

    // Check round number patterns (most specific first)
    if (_isRoundThousands(digits)) return 'Round Thousands (X000)';
    if (_isRoundEndVariation(digits)) return 'Round End Variation (X00Y)';
    if (_isDoubleEndingZeros(digits)) return 'Double + Ending Zeros (XX00)';
    if (_isEndingZeroStyle(digits)) return 'Ending Zero Style';

    // Check repeating digit patterns
    if (_isRepeatingPair(digits)) return 'Repeating Pair (ABAB)';
    if (_isDoublePair(digits)) return 'Double Pair (AABB)';
    if (_isMirrorPattern(digits)) return 'Mirror (ABBA)';
    if (_isTripleDigits(digits)) return 'Triple Digits (AAAB)';

    // Check sandwich pattern
    if (_isSandwichPattern(digits)) return 'Sandwich Pattern';

    // Check sequential patterns (most specific first)
    if (_isAscendingSequential(digits)) return 'Ascending Sequential';
    if (_isDescendingSequential(digits)) return 'Descending Sequential';
    if (_isNearSequential(digits)) return 'Near Sequential';

    // No pattern detected
    return null;
  }
  
  static bool _isRepeatingPair(List<int> digits) {
    // ABAB pattern: 8383, 2424, 1414
    return digits[0] == digits[2] && digits[1] == digits[3] && digits[0] != digits[1];
  }
  
  static bool _isDoublePair(List<int> digits) {
    // AABB pattern: 9911, 7744, 1122 (two pairs of consecutive same digits)
    return digits[0] == digits[1] && digits[2] == digits[3] && digits[0] != digits[2];
  }
  
  static bool _isMirrorPattern(List<int> digits) {
    // ABBA pattern: 7447, 2552, 1331 (palindrome/mirror symmetry)
    return digits[0] == digits[3] && digits[1] == digits[2] && digits[0] != digits[1];
  }
  
  static bool _isTripleDigits(List<int> digits) {
    // AAAB or ABBB pattern: 9993
    final counts = <int, int>{};
    for (final digit in digits) {
      counts[digit] = (counts[digit] ?? 0) + 1;
    }
    return counts.values.any((count) => count >= 3);
  }
  
  static bool _isNearSequential(List<int> digits) {
    // Check for patterns like 0902, 1716 (close progression)
    int sequentialCount = 0;
    for (int i = 1; i < digits.length; i++) {
      final diff = (digits[i] - digits[i-1]).abs();
      if (diff <= 2) sequentialCount++;
    }
    return sequentialCount >= 2;
  }

  // New specific pattern detectors
  static bool _isRoundThousands(List<int> digits) {
    // X000 pattern: 1000, 2000, 3000
    return digits[1] == 0 && digits[2] == 0 && digits[3] == 0 && digits[0] != 0;
  }

  static bool _isRoundEndVariation(List<int> digits) {
    // X00Y pattern: 3001, 5002, 7009
    return digits[1] == 0 && digits[2] == 0 && digits[3] != 0 && digits[0] != 0;
  }

  static bool _isDoubleEndingZeros(List<int> digits) {
    // XX00 pattern: 1200, 3400, 5600, 2300, 5100
    return digits[2] == 0 && digits[3] == 0 && digits[0] != 0 && digits[1] != 0;
  }

  static bool _isEndingZeroStyle(List<int> digits) {
    // X0Y0 or XY0Z pattern: 9040, 1030, 5070
    return (digits[1] == 0 && digits[3] == 0 && digits[0] != 0 && digits[2] != 0) ||
           (digits[2] == 0 && digits[3] != 0 && digits[0] != 0 && digits[1] != 0);
  }

  static bool _isAscendingSequential(List<int> digits) {
    // Ascending: 1234, 2345, 3456
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i-1] + 1) return false;
    }
    return true;
  }

  static bool _isDescendingSequential(List<int> digits) {
    // Descending: 4321, 5432, 6543
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i-1] - 1) return false;
    }
    return true;
  }

  static bool _isLeadingZeroThree(List<int> digits) {
    // 000X pattern: 0007, 0009, 0005
    return digits[0] == 0 && digits[1] == 0 && digits[2] == 0 && digits[3] != 0;
  }

  static bool _isLeadingZeroTwo(List<int> digits) {
    // 00XY pattern: 0012, 0034, 0077
    return digits[0] == 0 && digits[1] == 0 && digits[2] != 0;
  }

  static bool _isLeadingZeroOne(List<int> digits) {
    // 0XXX pattern: 0770, 0334, 0556
    return digits[0] == 0 && digits[1] != 0;
  }

  static bool _isSandwichPattern(List<int> digits) {
    // ACBA pattern: 1716 (A=1, C=7, B=1, A... wait that's wrong)
    // Looking at examples: 7464, 1716, 2717, 6535
    // 7464: pos[1]=pos[3] (4=4), pos[0]!=pos[2] (7!=6) - ABCB ✓
    // 1716: pos[0]=pos[2] (1=1), pos[1]!=pos[3] (7!=6) - ACBA ✓
    // 2717: pos[1]=pos[3] (7=7), pos[0]!=pos[2] (2!=1) - ABCB ✓
    // 6535: pos[1]=pos[3] (5=5), pos[0]!=pos[2] (6!=3) - ABCB ✓

    // ACBA: positions 0 and 2 match (but not all 4, and not mirror/double pair)
    bool isACBA = digits[0] == digits[2] && digits[1] != digits[3] &&
                  digits[0] != digits[1] && digits[0] != digits[3];

    // ABCB: positions 1 and 3 match (but not all 4, and not mirror/double pair)
    bool isABCB = digits[1] == digits[3] && digits[0] != digits[2] &&
                  digits[0] != digits[1] && digits[1] != digits[2];

    return isACBA || isABCB;
  }

  static List<PatternStatistic> getTopPatterns(List<LotteryResultModel> results, {int limit = 6}) {
    final patternCounts = analyzePatterns(results);
    final patternExamples = getPatternExamples(results);
    
    final statistics = patternCounts.entries.map((entry) {
      return PatternStatistic(
        patternType: entry.key,
        count: entry.value,
        examples: patternExamples[entry.key] ?? [],
        percentage: _calculatePercentage(entry.value, patternCounts.values.fold(0, (a, b) => a + b)),
      );
    }).toList();
    
    statistics.sort((a, b) => b.count.compareTo(a.count));
    return statistics.take(limit).toList();
  }
  
  static double _calculatePercentage(int count, int total) {
    if (total == 0) return 0.0;
    return (count / total) * 100;
  }
  
  // Grouped mock data for demonstration if no real data is available
  static List<PatternStatistic> getMockPatternData() {
    return [
      PatternStatistic(
        patternType: 'Repeating Patterns',
        count: 342,
        examples: ['8383', '2244', '7447', '1117'],
        percentage: 28.5,
      ),
      PatternStatistic(
        patternType: 'Round & Zero-Based Patterns',
        count: 268,
        examples: ['1000', '3001', '2300', '9040'],
        percentage: 22.3,
      ),
      PatternStatistic(
        patternType: 'Sequential Patterns',
        count: 195,
        examples: ['1234', '4321', '1210', '3530'],
        percentage: 16.2,
      ),
      PatternStatistic(
        patternType: 'Leading-Zero Patterns',
        count: 142,
        examples: ['0007', '0012', '0770', '0334'],
        percentage: 11.8,
      ),
      PatternStatistic(
        patternType: 'Double Digit Variations',
        count: 134,
        examples: ['1122', '3344', '5566', '7788'],
        percentage: 11.2,
      ),
      PatternStatistic(
        patternType: 'Triple Digits',
        count: 119,
        examples: ['9993', '1117', '5554', '7770'],
        percentage: 10.0,
      ),
    ];
  }
}

class PatternStatistic {
  final String patternType;
  final int count;
  final List<String> examples;
  final double percentage;

  const PatternStatistic({
    required this.patternType,
    required this.count,
    required this.examples,
    required this.percentage,
  });

  String get description {
    switch (patternType) {
      // Grouped patterns (for mock data)
      case 'Repeating Patterns':
        return 'ABAB, AABB, ABBA, AAAB variations';
      case 'Round & Zero-Based Patterns':
        return 'Round numbers with zeros (X000, XX00, X0Y0)';
      case 'Sequential Patterns':
        return 'Ascending, descending, near-sequential';
      case 'Leading-Zero Patterns':
        return 'Numbers starting with zeros (000X, 00XY, 0XXX)';
      case 'Double Digit Variations':
        return 'Paired double digits (AABB style)';
      case 'Triple Digits':
        return 'Three or more same digits';

      // Individual patterns (for real data analysis)
      case 'Repeating Pair (ABAB)':
        return 'First two digits repeat at the end';
      case 'Double Pair (AABB)':
        return 'Double digits grouped together';
      case 'Mirror (ABBA)':
        return 'Palindrome-like reflection pattern';
      case 'Triple Digits (AAAB)':
        return 'Three or more same digits';
      case 'Sandwich Pattern':
        return 'Alternating digit pattern (ACBA/ABCB)';

      // Round number patterns
      case 'Round Thousands (X000)':
        return 'Exact thousands (1000, 2000, 3000)';
      case 'Round End Variation (X00Y)':
        return 'Hundreds with single digit variation';
      case 'Double + Ending Zeros (XX00)':
        return 'Two digits followed by double zeros';
      case 'Ending Zero Style':
        return 'Numbers with zeros in middle/end positions';

      // Sequential patterns
      case 'Ascending Sequential':
        return 'Consecutive ascending digits';
      case 'Descending Sequential':
        return 'Consecutive descending digits';
      case 'Near Sequential':
        return 'Close progression with small variation';

      // Leading zero patterns
      case 'Leading Zero (000X)':
        return 'Three leading zeros with single digit';
      case 'Leading Zero (00XY)':
        return 'Two leading zeros with two digits';
      case 'Leading Zero (0XXX)':
        return 'Single leading zero with three digits';

      default:
        return 'Unique number pattern';
    }
  }

  String get icon {
    switch (patternType) {
      // Grouped patterns (for mock data)
      case 'Repeating Patterns':
        return '🔄';
      case 'Round & Zero-Based Patterns':
        return '🔵';
      case 'Sequential Patterns':
        return '📈';
      case 'Leading-Zero Patterns':
        return '0️⃣';
      case 'Double Digit Variations':
        return '👥';
      case 'Triple Digits':
        return '🎯';

      // Individual patterns (for real data analysis)
      case 'Repeating Pair (ABAB)':
        return '🔄';
      case 'Double Pair (AABB)':
        return '👥';
      case 'Mirror (ABBA)':
        return '🪞';
      case 'Triple Digits (AAAB)':
        return '🎯';
      case 'Sandwich Pattern':
        return '🥪';

      // Round number patterns
      case 'Round Thousands (X000)':
        return '🔵';
      case 'Round End Variation (X00Y)':
        return '🔘';
      case 'Double + Ending Zeros (XX00)':
        return '💯';
      case 'Ending Zero Style':
        return '⭕';

      // Sequential patterns
      case 'Ascending Sequential':
        return '📈';
      case 'Descending Sequential':
        return '📉';
      case 'Near Sequential':
        return '📊';

      // Leading zero patterns
      case 'Leading Zero (000X)':
        return '0️⃣';
      case 'Leading Zero (00XY)':
        return '🔢';
      case 'Leading Zero (0XXX)':
        return '🅾️';

      default:
        return '🔢';
    }
  }
}