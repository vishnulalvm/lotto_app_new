import 'dart:math';
import '../models/home_screen/cached_home_screen_model.dart';
import '../models/prediction_statistics_model.dart';
import 'digit_frequency_analyzer.dart';

/// Core engine for statistical lottery number prediction
/// Uses pattern analysis and digit frequency to generate intelligent predictions
class StatisticalPredictionEngine {
  final Random _random = Random();

  /// Time-decay weights for different days
  /// Day 0 (today) = 100%, Day 1 = 80%, Day 2 = 60%, Day 3 = 40%, Day 4+ = 20%
  static const List<double> timeDecayWeights = [1.0, 0.8, 0.6, 0.4, 0.2];

  /// Calculates time-decay weight based on days ago
  double _getTimeDecayWeight(int daysAgo) {
    if (daysAgo < 0) return 1.0;
    if (daysAgo < timeDecayWeights.length) {
      return timeDecayWeights[daysAgo];
    }
    return timeDecayWeights.last;
  }

  /// Analyzes patterns in ticket numbers
  Map<String, int> _analyzePatterns(List<String> ticketNumbers) {
    final Map<String, int> patternCounts = {};

    for (final ticketNumber in ticketNumbers) {
      if (ticketNumber.length == 4) {
        final patternType = _detectPatternType(ticketNumber);
        if (patternType != null) {
          patternCounts[patternType] = (patternCounts[patternType] ?? 0) + 1;
        }
      }
    }

    return patternCounts;
  }

  /// Gets examples for a specific pattern type
  List<String> _getPatternExamples(List<String> ticketNumbers, String patternType) {
    final List<String> examples = [];

    for (final ticketNumber in ticketNumbers) {
      if (ticketNumber.length == 4) {
        final detectedPattern = _detectPatternType(ticketNumber);
        if (detectedPattern == patternType && examples.length < 5) {
          examples.add(ticketNumber);
        }
      }
    }

    return examples;
  }

  /// Detects the pattern type of a 4-digit number
  String? _detectPatternType(String number) {
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
    if (_isSandwichPattern(digits)) return 'Sandwich Pattern (ACBA/ABCB)';

    // Check sequential patterns (most specific first)
    if (_isAscendingSequential(digits)) return 'Ascending Sequential';
    if (_isDescendingSequential(digits)) return 'Descending Sequential';

    // No pattern detected
    return null;
  }

  // Pattern detection helper methods
  bool _isRepeatingPair(List<int> digits) {
    return digits[0] == digits[2] && digits[1] == digits[3] && digits[0] != digits[1];
  }

  bool _isDoublePair(List<int> digits) {
    return digits[0] == digits[1] && digits[2] == digits[3] && digits[0] != digits[2];
  }

  bool _isMirrorPattern(List<int> digits) {
    return digits[0] == digits[3] && digits[1] == digits[2] && digits[0] != digits[1];
  }

  bool _isTripleDigits(List<int> digits) {
    final counts = <int, int>{};
    for (final digit in digits) {
      counts[digit] = (counts[digit] ?? 0) + 1;
    }
    return counts.values.any((count) => count >= 3);
  }

  bool _isRoundThousands(List<int> digits) {
    return digits[1] == 0 && digits[2] == 0 && digits[3] == 0 && digits[0] != 0;
  }

  bool _isRoundEndVariation(List<int> digits) {
    return digits[1] == 0 && digits[2] == 0 && digits[3] != 0 && digits[0] != 0;
  }

  bool _isDoubleEndingZeros(List<int> digits) {
    return digits[2] == 0 && digits[3] == 0 && digits[0] != 0 && digits[1] != 0;
  }

  bool _isEndingZeroStyle(List<int> digits) {
    return (digits[1] == 0 && digits[3] == 0 && digits[0] != 0 && digits[2] != 0) ||
           (digits[2] == 0 && digits[3] != 0 && digits[0] != 0 && digits[1] != 0);
  }

  bool _isAscendingSequential(List<int> digits) {
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i-1] + 1) return false;
    }
    return true;
  }

  bool _isDescendingSequential(List<int> digits) {
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] != digits[i-1] - 1) return false;
    }
    return true;
  }

  bool _isLeadingZeroThree(List<int> digits) {
    return digits[0] == 0 && digits[1] == 0 && digits[2] == 0 && digits[3] != 0;
  }

  bool _isLeadingZeroTwo(List<int> digits) {
    return digits[0] == 0 && digits[1] == 0 && digits[2] != 0;
  }

  bool _isLeadingZeroOne(List<int> digits) {
    return digits[0] == 0 && digits[1] != 0;
  }

  bool _isSandwichPattern(List<int> digits) {
    bool isACBA = digits[0] == digits[2] && digits[1] != digits[3] &&
                  digits[0] != digits[1] && digits[0] != digits[3];

    bool isABCB = digits[1] == digits[3] && digits[0] != digits[2] &&
                  digits[0] != digits[1] && digits[1] != digits[2];

    return isACBA || isABCB;
  }

  /// Analyzes cached results and generates prediction statistics
  PredictionStatistics analyzeResults(List<CachedHomeScreenResultModel> results) {
    final now = DateTime.now();
    final List<DigitFrequency> digitFrequencies = [];
    final Map<String, double> patternWeightedCounts = {};
    final Map<String, List<String>> patternExamples = {};
    int totalSamples = 0;

    // Analyze each result with time-decay weighting
    for (final result in results) {
      final resultDate = DateTime.parse(result.date);
      final daysAgo = now.difference(resultDate).inDays;
      final weight = _getTimeDecayWeight(daysAgo);

      // Collect all ticket numbers from the cached result
      final List<String> allTickets = [];

      // Add first prize ticket number
      allTickets.add(result.firstPrize.ticketNumber);

      // Add consolation prize ticket numbers if available
      if (result.consolationPrizes != null) {
        final consolationNumbers = result.consolationPrizes!.ticketNumbers
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        allTickets.addAll(consolationNumbers);
      }

      if (allTickets.isEmpty) continue;

      // Analyze digit frequency for this result
      final digitFreq = DigitFrequencyAnalyzer.analyze(allTickets, weight: weight);
      digitFrequencies.add(digitFreq);

      // Analyze patterns for this result using static method
      final patterns = _analyzePatterns(allTickets);

      patterns.forEach((patternType, count) {
        patternWeightedCounts[patternType] =
            (patternWeightedCounts[patternType] ?? 0.0) + (count * weight);

        // Store examples (if not already stored)
        if (!patternExamples.containsKey(patternType)) {
          final examples = _getPatternExamples(allTickets, patternType);
          if (examples.isNotEmpty) {
            patternExamples[patternType] = examples.take(3).toList();
          }
        }
      });

      totalSamples += allTickets.length;
    }

    // Combine digit frequencies
    final combinedDigitFreq = DigitFrequencyAnalyzer.combine(digitFrequencies);

    // Calculate pattern probabilities
    final totalWeightedCount = patternWeightedCounts.values
        .fold(0.0, (sum, count) => sum + count);

    final List<PatternProbability> patternProbabilities = [];
    patternWeightedCounts.forEach((patternType, weightedCount) {
      final probability = totalWeightedCount > 0
          ? weightedCount / totalWeightedCount
          : 0.0;

      patternProbabilities.add(PatternProbability(
        patternType: patternType,
        rawCount: weightedCount.round(),
        weightedCount: weightedCount,
        probability: probability,
        examples: patternExamples[patternType] ?? [],
      ));
    });

    // Sort by probability (descending)
    patternProbabilities.sort((a, b) => b.probability.compareTo(a.probability));

    return PredictionStatistics(
      patternProbabilities: patternProbabilities,
      digitFrequency: combinedDigitFreq,
      totalSamplesAnalyzed: totalSamples,
      analyzedAt: DateTime.now(),
    );
  }

  /// Selects a pattern type based on weighted probabilities
  String _selectPatternByProbability(List<PatternProbability> patterns) {
    if (patterns.isEmpty) {
      // Fallback to random pattern
      final allPatterns = [
        'Repeating Pair (ABAB)',
        'Double Pair (AABB)',
        'Mirror (ABBA)',
        'Ascending Sequential',
        'Triple Digits (AAAB)',
      ];
      return allPatterns[_random.nextInt(allPatterns.length)];
    }

    // Weighted random selection
    final totalProbability = patterns.fold(0.0, (sum, p) => sum + p.probability);
    if (totalProbability == 0.0) {
      return patterns[_random.nextInt(patterns.length)].patternType;
    }

    final randomValue = _random.nextDouble() * totalProbability;
    double cumulative = 0.0;

    for (final pattern in patterns) {
      cumulative += pattern.probability;
      if (randomValue <= cumulative) {
        return pattern.patternType;
      }
    }

    // Fallback
    return patterns.first.patternType;
  }

  /// Generates a number based on a pattern type using digit frequency
  String _generateNumberForPattern(
    String patternType,
    DigitFrequency digitFreq,
  ) {
    // Generate based on specific pattern type
    switch (patternType) {
      case 'Repeating Pair (ABAB)':
        return _generateRepeatingPair(digitFreq);
      case 'Double Pair (AABB)':
        return _generateDoublePair(digitFreq);
      case 'Mirror (ABBA)':
        return _generateMirror(digitFreq);
      case 'Triple Digits (AAAB)':
        return _generateTripleDigits(digitFreq);
      case 'Round Thousands (X000)':
        return _generateRoundThousands(digitFreq);
      case 'Round End Variation (X00Y)':
        return _generateRoundEndVariation(digitFreq);
      case 'Double + Ending Zeros (XX00)':
        return _generateDoubleEndingZeros(digitFreq);
      case 'Ending Zero Style':
        return _generateEndingZeroStyle(digitFreq);
      case 'Ascending Sequential':
        return _generateAscendingSequential(digitFreq);
      case 'Descending Sequential':
        return _generateDescendingSequential(digitFreq);
      case 'Leading Zero (000X)':
        return _generateLeadingZero000X(digitFreq);
      case 'Leading Zero (00XY)':
        return _generateLeadingZero00XY(digitFreq);
      case 'Leading Zero (0XXX)':
        return _generateLeadingZero0XXX(digitFreq);
      case 'Sandwich Pattern (ACBA/ABCB)':
        return _generateSandwich(digitFreq);
      default:
        return _generateRepeatingPair(digitFreq); // fallback
    }
  }

  // Pattern generators using digit frequency

  String _generateRepeatingPair(DigitFrequency freq) {
    final a = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0);
    final b = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 1, excludeDigits: [a]);
    return '$a$b$a$b';
  }

  String _generateDoublePair(DigitFrequency freq) {
    final a = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0);
    final b = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 2, excludeDigits: [a]);
    return '$a$a$b$b';
  }

  String _generateMirror(DigitFrequency freq) {
    final a = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0);
    final b = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 1, excludeDigits: [a]);
    return '$a$b$b$a';
  }

  String _generateTripleDigits(DigitFrequency freq) {
    final a = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0);
    final b = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 3, excludeDigits: [a]);
    return '$a$a$a$b';
  }

  String _generateRoundThousands(DigitFrequency freq) {
    final x = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0, excludeDigits: [0]);
    return '$x' '000';
  }

  String _generateRoundEndVariation(DigitFrequency freq) {
    final x = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0, excludeDigits: [0]);
    final y = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 3, excludeDigits: [0, x]);
    return '$x' '00' '$y';
  }

  String _generateDoubleEndingZeros(DigitFrequency freq) {
    final x = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0, excludeDigits: [0]);
    final y = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 1, excludeDigits: [0]);
    return '$x$y' '00';
  }

  String _generateEndingZeroStyle(DigitFrequency freq) {
    final a = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0, excludeDigits: [0]);
    final b = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 1);
    final c = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 2, excludeDigits: [0]);
    return '$a$b${c}0';
  }

  String _generateAscendingSequential(DigitFrequency freq) {
    final start = _random.nextInt(7); // 0-6 to allow room for +3
    final digits = [start, start + 1, start + 2, start + 3];
    return digits.join();
  }

  String _generateDescendingSequential(DigitFrequency freq) {
    final start = _random.nextInt(7) + 3; // 3-9 to allow room for -3
    final digits = [start, start - 1, start - 2, start - 3];
    return digits.join();
  }

  String _generateLeadingZero000X(DigitFrequency freq) {
    final x = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 3, excludeDigits: [0]);
    return '000$x';
  }

  String _generateLeadingZero00XY(DigitFrequency freq) {
    final x = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 2);
    final y = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 3);
    return '00$x$y';
  }

  String _generateLeadingZero0XXX(DigitFrequency freq) {
    final x = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 1);
    final y = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 2);
    final z = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 3);
    return '0$x$y$z';
  }

  String _generateSandwich(DigitFrequency freq) {
    final a = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 0);
    final b = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 1, excludeDigits: [a]);
    final c = DigitFrequencyAnalyzer.selectDigitByFrequency(freq, 2, excludeDigits: [a, b]);
    return '$a$c$b$a';
  }

  /// Main prediction generation method
  /// Generates [count] unique predictions based on statistical analysis
  List<String> generatePredictions(
    PredictionStatistics statistics, {
    int count = 12,
  }) {
    final Set<String> predictions = {};
    int attempts = 0;
    final maxAttempts = count * 10; // Prevent infinite loops

    while (predictions.length < count && attempts < maxAttempts) {
      attempts++;

      // Select pattern based on probability
      final patternType = _selectPatternByProbability(statistics.patternProbabilities);

      // Generate number for this pattern using digit frequency
      final number = _generateNumberForPattern(
        patternType,
        statistics.digitFrequency,
      );

      // Ensure it's 4 digits and unique
      if (number.length == 4 && !predictions.contains(number)) {
        predictions.add(number);
      }
    }

    // If we couldn't generate enough unique numbers, fill with random patterns
    while (predictions.length < count) {
      final randomPattern = statistics.patternProbabilities.isNotEmpty
          ? statistics.patternProbabilities[
              _random.nextInt(statistics.patternProbabilities.length)].patternType
          : 'Repeating Pair (ABAB)';

      final number = _generateNumberForPattern(
        randomPattern,
        statistics.digitFrequency,
      );

      if (number.length == 4 && !predictions.contains(number)) {
        predictions.add(number);
      }
    }

    return predictions.toList();
  }
}
