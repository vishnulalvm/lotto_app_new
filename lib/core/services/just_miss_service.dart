import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/scrach_card_screen/result_check.dart';

/// Service for computing "just miss" numbers from full lottery results
///
/// This service analyzes a user's ticket number against all winning tickets
/// to find near-misses in three categories:
/// 1. Shuffle matches: Same digits but different order
/// 2. One number difference: Only one digit is different
/// 3. Two number difference: Only two digits are different
class JustMissService {
  /// Find all just miss matches for a given ticket number in a lottery result
  ///
  /// Parameters:
  /// - [ticketNumber]: The user's ticket number to check
  /// - [fullResult]: The complete lottery result with all prizes
  ///
  /// Returns: [JustMissData] containing all categorized matches
  static JustMissData findJustMissNumbers({
    required String ticketNumber,
    required LotteryResultModel fullResult,
  }) {
    // Validate ticket number
    if (ticketNumber.isEmpty || ticketNumber.length < 4) {
      return JustMissData(
        hasJustMiss: false,
        shuffleMatches: [],
        oneNumberMatches: [],
        twoNumberMatches: [],
      );
    }

    // Extract last 4 digits from user's ticket for comparison
    final userLast4Digits = _getLast4Digits(ticketNumber);

    final shuffleMatches = <JustMissMatch>[];
    final oneNumberMatches = <JustMissMatch>[];
    final twoNumberMatches = <JustMissMatch>[];

    // Iterate through all prizes and their winning tickets
    for (final prize in fullResult.prizes) {
      // Skip consolation prizes
      if (prize.prizeTypeFormatted.toLowerCase().contains('consolation')) {
        continue;
      }

      final winningTickets = prize.getAllTicketNumbers(shouldReOrder: false);

      for (final winningTicket in winningTickets) {
        // Extract last 4 digits from winning ticket
        // If ticket is 8 digits (series + 6 digits), take last 4
        // If ticket is 4 digits, use all 4
        final winningLast4Digits = _getLast4Digits(winningTicket);

        // Skip if it's the exact match on last 4 digits (user already won)
        if (winningLast4Digits == userLast4Digits) {
          continue;
        }

        // Check for different types of matches using last 4 digits
        final isShuffleMatch =
            _isShuffleMatch(userLast4Digits, winningLast4Digits);
        final isOneNumberDiff =
            _isOneNumberDifferent(userLast4Digits, winningLast4Digits);
        final isTwoNumberDiff =
            _isTwoNumbersDifferent(userLast4Digits, winningLast4Digits);

        if (isShuffleMatch) {
          shuffleMatches.add(JustMissMatch(
            ticketNumber: winningTicket,
            prizeType: prize.prizeTypeFormatted,
            prizeAmount: prize.prizeAmount,
          ));
        } else if (isOneNumberDiff) {
          oneNumberMatches.add(JustMissMatch(
            ticketNumber: winningTicket,
            prizeType: prize.prizeTypeFormatted,
            prizeAmount: prize.prizeAmount,
          ));
        } else if (isTwoNumberDiff) {
          twoNumberMatches.add(JustMissMatch(
            ticketNumber: winningTicket,
            prizeType: prize.prizeTypeFormatted,
            prizeAmount: prize.prizeAmount,
          ));
        }
      }
    }

    // Remove duplicates (in case same ticket appears in multiple prize categories)
    final uniqueShuffleMatches = _removeDuplicates(shuffleMatches);
    final uniqueOneNumberMatches = _removeDuplicates(oneNumberMatches);
    final uniqueTwoNumberMatches = _removeDuplicates(twoNumberMatches);

    final hasAnyMatches = uniqueShuffleMatches.isNotEmpty ||
        uniqueOneNumberMatches.isNotEmpty ||
        uniqueTwoNumberMatches.isNotEmpty;

    return JustMissData(
      hasJustMiss: hasAnyMatches,
      shuffleMatches: uniqueShuffleMatches,
      oneNumberMatches: uniqueOneNumberMatches,
      twoNumberMatches: uniqueTwoNumberMatches,
    );
  }

  /// Check if two ticket numbers are shuffled versions of each other
  /// Example: "123456" and "654321" are shuffle matches
  static bool _isShuffleMatch(String ticket1, String ticket2) {
    // Must be same length
    if (ticket1.length != ticket2.length) {
      return false;
    }

    // Convert to sorted character lists
    final sorted1 = ticket1.split('')..sort();
    final sorted2 = ticket2.split('')..sort();
    final sorted1Str = sorted1.join();
    final sorted2Str = sorted2.join();

    // Compare sorted versions
    return sorted1Str == sorted2Str && ticket1 != ticket2;
  }

  /// Check if two ticket numbers differ by exactly one digit
  /// Example: "123456" and "123457" differ by one number
  static bool _isOneNumberDifferent(String ticket1, String ticket2) {
    // Must be same length
    if (ticket1.length != ticket2.length) {
      return false;
    }

    int differenceCount = 0;
    for (int i = 0; i < ticket1.length; i++) {
      if (ticket1[i] != ticket2[i]) {
        differenceCount++;
        if (differenceCount > 1) {
          return false; // More than one difference
        }
      }
    }

    return differenceCount == 1;
  }

  /// Check if two ticket numbers differ by exactly two digits
  /// Example: "123456" and "123478" differ by two numbers
  static bool _isTwoNumbersDifferent(String ticket1, String ticket2) {
    // Must be same length
    if (ticket1.length != ticket2.length) {
      return false;
    }

    int differenceCount = 0;
    for (int i = 0; i < ticket1.length; i++) {
      if (ticket1[i] != ticket2[i]) {
        differenceCount++;
        if (differenceCount > 2) {
          return false; // More than two differences
        }
      }
    }

    return differenceCount == 2;
  }

  /// Extract last 4 digits from a ticket number
  /// Examples:
  /// - "BS735398" -> "5398"
  /// - "735398" -> "5398"
  /// - "5398" -> "5398"
  static String _getLast4Digits(String ticketNumber) {
    // Remove any non-digit characters first
    final digitsOnly = ticketNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Return last 4 digits
    if (digitsOnly.length >= 4) {
      return digitsOnly.substring(digitsOnly.length - 4);
    }

    // If less than 4 digits, return as is (this shouldn't happen with valid tickets)
    return digitsOnly;
  }

  /// Remove duplicate matches, keeping the one with highest prize
  static List<JustMissMatch> _removeDuplicates(List<JustMissMatch> matches) {
    if (matches.isEmpty) {
      return [];
    }

    final Map<String, JustMissMatch> uniqueMatches = {};

    for (final match in matches) {
      final existing = uniqueMatches[match.ticketNumber];

      // Keep the match with higher prize amount
      if (existing == null || match.prizeAmount > existing.prizeAmount) {
        uniqueMatches[match.ticketNumber] = match;
      }
    }

    // Sort by prize amount (highest first)
    final result = uniqueMatches.values.toList()
      ..sort((a, b) => b.prizeAmount.compareTo(a.prizeAmount));

    return result;
  }

  /// Helper method to analyze a specific ticket against specific prize categories
  ///
  /// Useful when you want to check against specific prize types only
  /// (e.g., only check against consolation prizes)
  static JustMissData findJustMissNumbersForPrizes({
    required String ticketNumber,
    required List<PrizeModel> prizes,
  }) {
    if (ticketNumber.isEmpty || ticketNumber.length < 4) {
      return JustMissData(
        hasJustMiss: false,
        shuffleMatches: [],
        oneNumberMatches: [],
        twoNumberMatches: [],
      );
    }

    // Extract last 4 digits from user's ticket
    final userLast4Digits = _getLast4Digits(ticketNumber);

    final shuffleMatches = <JustMissMatch>[];
    final oneNumberMatches = <JustMissMatch>[];
    final twoNumberMatches = <JustMissMatch>[];

    for (final prize in prizes) {
      // Skip consolation prizes
      if (prize.prizeTypeFormatted.toLowerCase().contains('consolation')) {
        continue;
      }

      final winningTickets = prize.getAllTicketNumbers(shouldReOrder: false);

      for (final winningTicket in winningTickets) {
        // Extract last 4 digits from winning ticket
        final winningLast4Digits = _getLast4Digits(winningTicket);

        // Skip exact matches
        if (winningLast4Digits == userLast4Digits) {
          continue;
        }

        // Compare using last 4 digits
        if (_isShuffleMatch(userLast4Digits, winningLast4Digits)) {
          shuffleMatches.add(JustMissMatch(
            ticketNumber: winningTicket,
            prizeType: prize.prizeTypeFormatted,
            prizeAmount: prize.prizeAmount,
          ));
        } else if (_isOneNumberDifferent(userLast4Digits, winningLast4Digits)) {
          oneNumberMatches.add(JustMissMatch(
            ticketNumber: winningTicket,
            prizeType: prize.prizeTypeFormatted,
            prizeAmount: prize.prizeAmount,
          ));
        } else if (_isTwoNumbersDifferent(
            userLast4Digits, winningLast4Digits)) {
          twoNumberMatches.add(JustMissMatch(
            ticketNumber: winningTicket,
            prizeType: prize.prizeTypeFormatted,
            prizeAmount: prize.prizeAmount,
          ));
        }
      }
    }

    final uniqueShuffleMatches = _removeDuplicates(shuffleMatches);
    final uniqueOneNumberMatches = _removeDuplicates(oneNumberMatches);
    final uniqueTwoNumberMatches = _removeDuplicates(twoNumberMatches);

    final hasAnyMatches = uniqueShuffleMatches.isNotEmpty ||
        uniqueOneNumberMatches.isNotEmpty ||
        uniqueTwoNumberMatches.isNotEmpty;

    return JustMissData(
      hasJustMiss: hasAnyMatches,
      shuffleMatches: uniqueShuffleMatches,
      oneNumberMatches: uniqueOneNumberMatches,
      twoNumberMatches: uniqueTwoNumberMatches,
    );
  }

  /// Check if a specific ticket number has any just miss matches
  /// Returns true if there are any matches in any category
  static bool hasAnyJustMiss({
    required String ticketNumber,
    required LotteryResultModel fullResult,
  }) {
    final result = findJustMissNumbers(
      ticketNumber: ticketNumber,
      fullResult: fullResult,
    );
    return result.hasAnyMatches;
  }

  /// Get total count of all just miss matches across all categories
  static int getTotalJustMissCount({
    required String ticketNumber,
    required LotteryResultModel fullResult,
  }) {
    final result = findJustMissNumbers(
      ticketNumber: ticketNumber,
      fullResult: fullResult,
    );
    return result.shuffleMatches.length +
        result.oneNumberMatches.length +
        result.twoNumberMatches.length;
  }
}
