/// Model for storing pattern probability data with time-decay weighting
class PatternProbability {
  final String patternType;
  final int rawCount;
  final double weightedCount;
  final double probability;
  final List<String> examples;

  PatternProbability({
    required this.patternType,
    required this.rawCount,
    required this.weightedCount,
    required this.probability,
    required this.examples,
  });

  @override
  String toString() =>
      'PatternProbability(type: $patternType, count: $rawCount, probability: ${(probability * 100).toStringAsFixed(2)}%)';
}

/// Model for storing digit frequency analysis
class DigitFrequency {
  final Map<int, double> overallFrequency; // digit -> frequency (0.0-1.0)
  final Map<int, Map<int, double>>
      positionalFrequency; // position -> (digit -> frequency)

  DigitFrequency({
    required this.overallFrequency,
    required this.positionalFrequency,
  });

  /// Get the probability of a digit appearing anywhere
  double getDigitProbability(int digit) {
    return overallFrequency[digit] ?? 0.0;
  }

  /// Get the probability of a digit appearing at a specific position (0-3)
  double getPositionalProbability(int digit, int position) {
    return positionalFrequency[position]?[digit] ?? 0.0;
  }

  /// Get combined probability (60% overall + 40% positional)
  double getCombinedProbability(int digit, int position) {
    final overall = getDigitProbability(digit);
    final positional = getPositionalProbability(digit, position);
    return (overall * 0.6) + (positional * 0.4);
  }

  @override
  String toString() {
    final topDigits = overallFrequency.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    return 'DigitFrequency(top3: ${topDigits.take(3).map((e) => '${e.key}:${(e.value * 100).toStringAsFixed(1)}%').join(', ')})';
  }
}

/// Model for complete prediction statistics
class PredictionStatistics {
  final List<PatternProbability> patternProbabilities;
  final DigitFrequency digitFrequency;
  final int totalSamplesAnalyzed;
  final DateTime analyzedAt;

  PredictionStatistics({
    required this.patternProbabilities,
    required this.digitFrequency,
    required this.totalSamplesAnalyzed,
    required this.analyzedAt,
  });

  @override
  String toString() =>
      'PredictionStatistics(patterns: ${patternProbabilities.length}, samples: $totalSamplesAnalyzed, at: $analyzedAt)';
}
