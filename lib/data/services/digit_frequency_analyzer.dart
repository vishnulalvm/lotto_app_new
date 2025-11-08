import '../models/prediction_statistics_model.dart';

/// Service for analyzing digit frequency in lottery winning numbers
class DigitFrequencyAnalyzer {
  /// Analyzes digit frequency from a list of 4-digit ticket numbers
  /// with optional time-decay weighting
  static DigitFrequency analyze(
    List<String> ticketNumbers, {
    double weight = 1.0,
  }) {
    if (ticketNumbers.isEmpty) {
      return DigitFrequency(
        overallFrequency: {},
        positionalFrequency: {},
      );
    }

    // Initialize counters
    final Map<int, double> overallCount = {
      for (var i = 0; i < 10; i++) i: 0.0
    };
    final Map<int, Map<int, double>> positionalCount = {
      for (var pos = 0; pos < 4; pos++)
        pos: {for (var i = 0; i < 10; i++) i: 0.0}
    };

    int totalDigits = 0;

    // Count digit occurrences
    for (final ticket in ticketNumbers) {
      if (ticket.length != 4) continue;

      for (var position = 0; position < 4; position++) {
        final digitChar = ticket[position];
        final digit = int.tryParse(digitChar);

        if (digit != null) {
          // Add weighted count
          overallCount[digit] = (overallCount[digit] ?? 0.0) + weight;
          positionalCount[position]![digit] =
              (positionalCount[position]![digit] ?? 0.0) + weight;
          totalDigits++;
        }
      }
    }

    // Convert counts to frequencies (probabilities)
    final Map<int, double> overallFrequency = {};
    for (var digit = 0; digit < 10; digit++) {
      overallFrequency[digit] = totalDigits > 0
          ? (overallCount[digit] ?? 0.0) / (totalDigits * weight)
          : 0.0;
    }

    final Map<int, Map<int, double>> positionalFrequency = {};
    for (var position = 0; position < 4; position++) {
      positionalFrequency[position] = {};
      final positionTotal = ticketNumbers.length * weight;

      for (var digit = 0; digit < 10; digit++) {
        positionalFrequency[position]![digit] = positionTotal > 0
            ? (positionalCount[position]![digit] ?? 0.0) / positionTotal
            : 0.0;
      }
    }

    return DigitFrequency(
      overallFrequency: overallFrequency,
      positionalFrequency: positionalFrequency,
    );
  }

  /// Combines multiple DigitFrequency analyses into one
  static DigitFrequency combine(List<DigitFrequency> frequencies) {
    if (frequencies.isEmpty) {
      return DigitFrequency(
        overallFrequency: {},
        positionalFrequency: {},
      );
    }

    if (frequencies.length == 1) {
      return frequencies.first;
    }

    // Average the frequencies
    final Map<int, double> combinedOverall = {for (var i = 0; i < 10; i++) i: 0.0};
    final Map<int, Map<int, double>> combinedPositional = {
      for (var pos = 0; pos < 4; pos++)
        pos: {for (var i = 0; i < 10; i++) i: 0.0}
    };

    for (final freq in frequencies) {
      // Add overall frequencies
      freq.overallFrequency.forEach((digit, probability) {
        combinedOverall[digit] = (combinedOverall[digit] ?? 0.0) + probability;
      });

      // Add positional frequencies
      freq.positionalFrequency.forEach((position, digitMap) {
        digitMap.forEach((digit, probability) {
          combinedPositional[position]![digit] =
              (combinedPositional[position]![digit] ?? 0.0) + probability;
        });
      });
    }

    // Average by dividing by count
    final count = frequencies.length;
    combinedOverall.updateAll((digit, value) => value / count);
    for (var position = 0; position < 4; position++) {
      combinedPositional[position]!
          .updateAll((digit, value) => value / count);
    }

    return DigitFrequency(
      overallFrequency: combinedOverall,
      positionalFrequency: combinedPositional,
    );
  }

  /// Selects a digit based on frequency probabilities for a given position
  /// Higher frequency digits have higher chance of being selected
  static int selectDigitByFrequency(
    DigitFrequency frequency,
    int position, {
    List<int> excludeDigits = const [],
  }) {
    // Get probabilities for all digits at this position
    final probabilities = <int, double>{};
    for (var digit = 0; digit < 10; digit++) {
      if (!excludeDigits.contains(digit)) {
        probabilities[digit] = frequency.getCombinedProbability(digit, position);
      }
    }

    // If no valid probabilities, return random
    if (probabilities.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch % 10;
    }

    // Normalize probabilities
    final total = probabilities.values.fold(0.0, (sum, prob) => sum + prob);
    if (total == 0.0) {
      // All probabilities are zero, select random
      final availableDigits = probabilities.keys.toList();
      return availableDigits[
          DateTime.now().millisecondsSinceEpoch % availableDigits.length];
    }

    // Weighted random selection
    final random = (DateTime.now().millisecondsSinceEpoch % 1000000) / 1000000;
    double cumulative = 0.0;

    for (final entry in probabilities.entries) {
      cumulative += entry.value / total;
      if (random <= cumulative) {
        return entry.key;
      }
    }

    // Fallback (shouldn't reach here)
    return probabilities.keys.first;
  }
}
