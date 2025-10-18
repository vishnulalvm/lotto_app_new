
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
            patternCounts[patternType] = (patternCounts[patternType] ?? 0) + 1;
          }
        }
      }
    }
    
    return patternCounts;
  }
  
  static Map<String, List<String>> getPatternExamples(List<LotteryResultModel> results) {
    final Map<String, Set<String>> patternExamples = {};
    
    for (final result in results) {
      for (final prize in result.prizes) {
        final ticketNumbers = prize.getAllTicketNumbers();
        for (final ticketNumber in ticketNumbers) {
          if (ticketNumber.length == 4) {
            final patternType = _detectPatternType(ticketNumber);
            patternExamples[patternType] ??= <String>{};
            if (patternExamples[patternType]!.length < 5) {
              patternExamples[patternType]!.add(ticketNumber);
            }
          }
        }
      }
    }
    
    return patternExamples.map((key, value) => MapEntry(key, value.toList()));
  }
  
  static String _detectPatternType(String number) {
    if (number.length != 4) return 'Invalid';
    
    final digits = number.split('').map(int.parse).toList();
    
    // Check for repeating patterns
    if (_isRepeatingPair(digits)) return 'Repeating Pair (ABAB)';
    if (_isDoublePair(digits)) return 'Double Pair (AABB)';
    if (_isMirrorPattern(digits)) return 'Mirror (ABBA)';
    if (_isTripleDigits(digits)) return 'Triple Digits (AAAB)';
    
    // Check for sequential patterns
    if (_isSequential(digits)) return 'Sequential';
    if (_isNearSequential(digits)) return 'Near Sequential';
    
    // Check for round numbers
    if (_isRoundNumber(digits)) return 'Round Numbers';
    
    // Check for leading zeros
    if (_hasLeadingZeros(digits)) return 'Leading Zeros';
    
    // Default to regular
    return 'Regular Numbers';
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
  
  static bool _isSequential(List<int> digits) {
    // Ascending: 1234, 2345 or Descending: 4321, 5432
    bool ascending = true;
    bool descending = true;
    
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i-1] + 1) ascending = false;
      if (digits[i] != digits[i-1] - 1) descending = false;
    }
    
    return ascending || descending;
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
  
  static bool _isRoundNumber(List<int> digits) {
    // Patterns ending with zeros: 2300, 5100, 9040
    return digits[2] == 0 || digits[3] == 0 || 
           (digits[2] == 0 && digits[3] == 0);
  }
  
  static bool _hasLeadingZeros(List<int> digits) {
    // Patterns starting with zeros: 0902
    return digits[0] == 0;
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
  
  // Mock data for demonstration if no real data is available
  static List<PatternStatistic> getMockPatternData() {
    return [
      PatternStatistic(
        patternType: 'Repeating Pair (ABAB)',
        count: 156,
        examples: ['8383', '2424', '1414', '0909'],
        percentage: 23.5,
      ),
      PatternStatistic(
        patternType: 'Double Pair (AABB)',
        count: 134,
        examples: ['6535', '9911', '7744', '1122'],
        percentage: 20.2,
      ),
      PatternStatistic(
        patternType: 'Sequential',
        count: 98,
        examples: ['1234', '2345', '4321', '5432'],
        percentage: 14.8,
      ),
      PatternStatistic(
        patternType: 'Mirror (ABBA)',
        count: 87,
        examples: ['7447', '2552', '1331', '9119'],
        percentage: 13.1,
      ),
      PatternStatistic(
        patternType: 'Round Numbers',
        count: 76,
        examples: ['2300', '5100', '9040', '1000'],
        percentage: 11.5,
      ),
      PatternStatistic(
        patternType: 'Triple Digits',
        count: 67,
        examples: ['9993', '1117', '5554', '7770'],
        percentage: 10.1,
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
      case 'Repeating Pair (ABAB)':
        return 'First two digits repeat at the end';
      case 'Double Pair (AABB)':
        return 'Double digits grouped together';
      case 'Sequential':
        return 'Consecutive or reverse consecutive digits';
      case 'Mirror (ABBA)':
        return 'Palindrome-like reflection pattern';
      case 'Round Numbers':
        return 'Numbers ending with zeros';
      case 'Triple Digits':
        return 'Three or more same digits';
      case 'Near Sequential':
        return 'Close progression with small variation';
      case 'Leading Zeros':
        return 'Numbers starting with zero';
      case 'Regular Numbers':
        return 'Standard random patterns';
      default:
        return 'Unique number pattern';
    }
  }

  String get icon {
    switch (patternType) {
      case 'Repeating Pair (ABAB)':
        return '🔄';
      case 'Double Pair (AABB)':
        return '👥';
      case 'Sequential':
        return '📈';
      case 'Mirror (ABBA)':
        return '🪞';
      case 'Round Numbers':
        return '🔵';
      case 'Triple Digits':
        return '🎯';
      case 'Near Sequential':
        return '📊';
      case 'Leading Zeros':
        return '0️⃣';
      case 'Regular Numbers':
        return '🎲';
      default:
        return '🔢';
    }
  }
}