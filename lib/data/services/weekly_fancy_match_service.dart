import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/services/fancy_number_generator.dart';
import 'package:lotto_app/data/services/prediction_match_service.dart';

/// Model for a single fancy number match
class FancyNumberMatch {
  final String number;
  final String lotteryName;
  final String date;
  final String prizeType;
  final int prizeRank; // For sorting (1 = first prize, 2 = second, etc.)

  FancyNumberMatch({
    required this.number,
    required this.lotteryName,
    required this.date,
    required this.prizeType,
    required this.prizeRank,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'lotteryName': lotteryName,
        'date': date,
        'prizeType': prizeType,
        'prizeRank': prizeRank,
      };

  factory FancyNumberMatch.fromJson(Map<String, dynamic> json) {
    return FancyNumberMatch(
      number: json['number'] ?? '',
      lotteryName: json['lotteryName'] ?? '',
      date: json['date'] ?? '',
      prizeType: json['prizeType'] ?? '',
      prizeRank: json['prizeRank'] ?? 999,
    );
  }
}

/// Service for managing weekly fancy numbers and their matches
class WeeklyFancyMatchService {
  static const String _keyFancyNumbers = 'weekly_fancy_numbers';
  static const String _keyStartDate = 'weekly_fancy_start_date';
  static const String _keyMatches = 'weekly_fancy_matches';

  /// Gets the current week's fancy numbers, generates new if week expired
  static Future<List<String>> getCurrentWeekNumbers() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset (new week)
    if (await _shouldResetWeek()) {
      return await _generateNewWeek();
    }

    // Load existing numbers
    final numbersJson = prefs.getString(_keyFancyNumbers);
    if (numbersJson == null) {
      return await _generateNewWeek();
    }

    try {
      final List<dynamic> numbersList = jsonDecode(numbersJson);
      return numbersList.map((e) => e.toString()).toList();
    } catch (e) {
      return await _generateNewWeek();
    }
  }

  /// Checks if the current week has expired (past Saturday)
  static Future<bool> _shouldResetWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final startDateStr = prefs.getString(_keyStartDate);

    if (startDateStr == null) return true;

    try {
      final startDate = DateTime.parse(startDateStr);
      final now = DateTime.now();

      // Calculate week end (Saturday at 23:59:59)
      final weekEnd = startDate.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      // If current time is past week end, we need to reset
      return now.isAfter(weekEnd);
    } catch (e) {
      return true;
    }
  }

  /// Generates new fancy numbers for the week and saves them
  static Future<List<String>> _generateNewWeek() async {
    final prefs = await SharedPreferences.getInstance();

    // Generate new fancy numbers
    final numbers = FancyNumberGenerator.generateWeeklyFancyNumbers();

    // Get current Sunday as start date
    final now = DateTime.now();
    final sunday = _getThisSunday(now);

    // Save to storage
    await prefs.setString(_keyFancyNumbers, jsonEncode(numbers));
    await prefs.setString(_keyStartDate, sunday.toIso8601String());
    await prefs.remove(_keyMatches); // Clear old matches

    return numbers;
  }

  /// Gets this week's Sunday date
  static DateTime _getThisSunday(DateTime date) {
    // If today is Sunday, use today; otherwise find previous Sunday
    final daysFromSunday = date.weekday % 7; // 0 = Sunday, 1 = Monday, etc.
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromSunday));
  }

  /// Gets the start date of the current week
  static Future<DateTime?> getWeekStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final startDateStr = prefs.getString(_keyStartDate);

    if (startDateStr == null) return null;

    try {
      return DateTime.parse(startDateStr);
    } catch (e) {
      return null;
    }
  }

  /// Gets the current day of the week (1-7)
  static Future<int> getCurrentDayOfWeek() async {
    final startDate = await getWeekStartDate();
    if (startDate == null) return 1;

    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;

    // Return 1-7 (clamped)
    return (difference + 1).clamp(1, 7);
  }

  /// Checks for matches and updates storage
  static Future<void> checkAndUpdateMatches() async {
    final numbers = await getCurrentWeekNumbers();
    if (numbers.isEmpty) return;

    // Get today's results
    final homeResult = await PredictionMatchService.getTodaysResults();
    if (homeResult == null || !homeResult.isPublished) return;

    // Get detailed results
    final detailedResult =
        await PredictionMatchService.getDetailedResults(homeResult.uniqueId);
    if (detailedResult == null) return;

    // Check each fancy number for matches
    final newMatches = <FancyNumberMatch>[];

    for (final number in numbers) {
      final match = await _findBestMatchForNumber(
        number,
        detailedResult,
        homeResult.lotteryName,
        homeResult.date,
      );
      if (match != null) {
        newMatches.add(match);
      }
    }

    // Update stored matches (merge with existing)
    if (newMatches.isNotEmpty) {
      await _updateStoredMatches(newMatches);
    }
  }

  /// Finds the best match (highest prize) for a given number
  static Future<FancyNumberMatch?> _findBestMatchForNumber(
    String number,
    dynamic detailedResult,
    String lotteryName,
    String date,
  ) async {
    FancyNumberMatch? bestMatch;
    int bestRank = 999;

    // Check all prize categories
    final prizeCategories = [
      {'type': 'firstPrize', 'name': '1st Prize', 'rank': 1},
      {'type': 'secondPrize', 'name': '2nd Prize', 'rank': 2},
      {'type': 'thirdPrize', 'name': '3rd Prize', 'rank': 3},
      {'type': 'fourthPrize', 'name': '4th Prize', 'rank': 4},
      {'type': 'fifthPrize', 'name': '5th Prize', 'rank': 5},
      {'type': 'sixthPrize', 'name': '6th Prize', 'rank': 6},
      {'type': 'seventhPrize', 'name': '7th Prize', 'rank': 7},
      {'type': 'eighthPrize', 'name': '8th Prize', 'rank': 8},
      {'type': 'consolation', 'name': 'Consolation', 'rank': 99},
    ];

    for (final category in prizeCategories) {
      final prizes = detailedResult.getPrizesByType(category['type'] as String);

      for (final prize in prizes) {
        final ticketNumbers = prize.getAllTicketNumbers();

        // Check if our fancy number matches any ticket
        if (ticketNumbers.contains(number)) {
          final rank = category['rank'] as int;

          // Keep only the best (lowest rank number = highest prize)
          if (rank < bestRank) {
            bestMatch = FancyNumberMatch(
              number: number,
              lotteryName: lotteryName,
              date: date,
              prizeType: category['name'] as String,
              prizeRank: rank,
            );
            bestRank = rank;
          }
        }
      }
    }

    return bestMatch;
  }

  /// Updates stored matches (keeps best match per number)
  static Future<void> _updateStoredMatches(List<FancyNumberMatch> newMatches) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getMatches();

    // Merge: keep best match per number
    final mergedMap = <String, FancyNumberMatch>{};

    // Add existing matches
    for (final match in existing) {
      mergedMap[match.number] = match;
    }

    // Add or update with new matches (if better)
    for (final newMatch in newMatches) {
      final existingMatch = mergedMap[newMatch.number];
      if (existingMatch == null || newMatch.prizeRank < existingMatch.prizeRank) {
        mergedMap[newMatch.number] = newMatch;
      }
    }

    // Save back to storage
    final matchesList = mergedMap.values.map((m) => m.toJson()).toList();
    await prefs.setString(_keyMatches, jsonEncode(matchesList));
  }

  /// Gets all matches for the current week
  static Future<List<FancyNumberMatch>> getMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final matchesJson = prefs.getString(_keyMatches);

    if (matchesJson == null) return [];

    try {
      final List<dynamic> matchesList = jsonDecode(matchesJson);
      return matchesList.map((json) => FancyNumberMatch.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets matches for a specific number
  static Future<FancyNumberMatch?> getMatchForNumber(String number) async {
    final matches = await getMatches();
    try {
      return matches.firstWhere((m) => m.number == number);
    } catch (e) {
      return null;
    }
  }

  /// Manually resets the week (for testing)
  static Future<void> resetWeek() async {
    await _generateNewWeek();
  }
}
