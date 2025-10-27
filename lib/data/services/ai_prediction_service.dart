import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/predict_screen/ai_prediction_model.dart';

class AiPredictionService {
  static const String _boxName = 'ai_predictions';
  static const String _lastGeneratedDateKey = 'last_generated_date';
  
  static Box<AiPredictionModel>? _box;
  static final Random _random = Random();

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<AiPredictionModel>(_boxName);
    } else {
      _box = Hive.box<AiPredictionModel>(_boxName);
    }
  }

  static Future<AiPredictionModel?> getTodaysPrediction(int prizeType) async {
    await init();
    
    final today = _getTodayDateString();
    final key = '${today}_$prizeType';
    
    // Check if we have prediction for today and this prize type
    final prediction = _box?.get(key);
    if (prediction != null) {
      return prediction;
    }

    // Generate new prediction for today
    return await _generateAndStorePrediction(prizeType);
  }

  /// Gets prediction specifically for the actual today's date (not affected by 3 PM rule)
  /// This is used for comparing with today's lottery results
  static Future<AiPredictionModel?> getActualTodaysPrediction(int prizeType) async {
    await init();
    
    final now = DateTime.now();
    final actualToday = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final key = '${actualToday}_$prizeType';
    
    // Check if we have prediction stored for actual today's date
    final prediction = _box?.get(key);
    if (prediction != null) {
      return prediction;
    }

    // If no prediction for actual today, generate one with actual today's date
    final numbers = _generateRandomNumbers(prizeType);
    
    final newPrediction = AiPredictionModel(
      date: actualToday,
      prizeType: prizeType,
      predictedNumbers: numbers,
      generatedAt: DateTime.now(),
    );

    await _box?.put(key, newPrediction);
    return newPrediction;
  }

  /// Gets prediction for a specific date and prize type
  static Future<AiPredictionModel?> getPredictionForDate(String date, int prizeType) async {
    await init();
    
    final key = '${date}_$prizeType';
    
    // Check if we have prediction for this date and prize type
    final prediction = _box?.get(key);
    if (prediction != null) {
      return prediction;
    }

    // Generate new prediction for this specific date
    final numbers = _generateRandomNumbers(prizeType);
    
    final newPrediction = AiPredictionModel(
      date: date,
      prizeType: prizeType,
      predictedNumbers: numbers,
      generatedAt: DateTime.now(),
    );

    await _box?.put(key, newPrediction);
    return newPrediction;
  }

  static Future<AiPredictionModel> _generateAndStorePrediction(int prizeType) async {
    final today = _getTodayDateString();
    final numbers = _generateRandomNumbers(prizeType);
    
    final prediction = AiPredictionModel(
      date: today,
      prizeType: prizeType,
      predictedNumbers: numbers,
      generatedAt: DateTime.now(),
    );

    final key = '${today}_$prizeType';
    await _box?.put(key, prediction);
    
    return prediction;
  }

  static List<String> _generateRandomNumbers(int prizeType) {
    final numbers = <String>[];
    final usedNumbers = <String>{};
    
    // Generate 12 unique fancy 4-digit numbers
    while (numbers.length < 12) {
      String number = _generateFancyNumber();
      
      if (!usedNumbers.contains(number)) {
        numbers.add(number);
        usedNumbers.add(number);
      }
    }
    
    return numbers;
  }

  static String _generateFancyNumber() {
    // Define all pattern types matching PatternAnalysisService
    // 100% pattern-based generation - no random numbers
    final List<String Function()> patternGenerators = [
      // Repeating digit patterns
      () => _generateRepeatingPattern(),

      // Round number patterns
      () => _generateRoundNumber(),

      // Sequential patterns
      () => _generateSequentialPattern(),

      // Leading zero patterns
      () => _generateLeadingZeroPattern(),

      // Sandwich pattern (NEW)
      () => _generateSandwichPattern(),

      // Ending zero style (NEW)
      () => _generateEndingZeroStyle(),
    ];

    // 100% pattern-based: randomly select a pattern type
    final patternGenerator = patternGenerators[_random.nextInt(patternGenerators.length)];
    return patternGenerator();
  }

  static String _generateRepeatingPattern() {
    final patterns = [
      // ABAB pattern (like 3454, 2525)
      () {
        final a = _random.nextInt(10);
        final b = _random.nextInt(10);
        return '$a$b$a$b';
      },
      // AABB pattern (like 2244, 4455, 7007)
      () {
        final a = _random.nextInt(10);
        final b = _random.nextInt(10);
        return '$a$a$b$b';
      },
      // ABBA pattern (like 3553, 2112)
      () {
        final a = _random.nextInt(10);
        final b = _random.nextInt(10);
        return '$a$b$b$a';
      },
      // AAAB pattern (like 1117, 3339)
      () {
        final a = _random.nextInt(10);
        final b = _random.nextInt(10);
        return '$a$a$a$b';
      },
    ];
    
    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateRoundNumber() {
    final patterns = [
      // X000 pattern (like 1000, 2000, 3000)
      () {
        final first = 1 + _random.nextInt(9);
        return '${first}000';
      },
      // X00Y pattern (like 3001, 5002, 7009)
      () {
        final first = 1 + _random.nextInt(9);
        final last = 1 + _random.nextInt(9);
        return '${first}00$last';
      },
      // XX00 pattern (like 1200, 3400, 5600)
      () {
        final first = 1 + _random.nextInt(9);
        final second = _random.nextInt(10);
        return '$first${second}00';
      },
    ];
    
    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateSequentialPattern() {
    final patterns = [
      // Ascending Sequential (like 1234, 2345, 3456)
      () {
        final start = _random.nextInt(7); // 0-6, so max is 6789
        return '$start${start + 1}${start + 2}${start + 3}';
      },
      // Descending Sequential (like 4321, 5432, 6543)
      () {
        final start = 3 + _random.nextInt(7); // 3-9, so min is 3210, max is 9876
        return '$start${start - 1}${start - 2}${start - 3}';
      },
      // Near Sequential - close progression with small gaps
      () {
        final start = _random.nextInt(8);
        final second = start + 1 + _random.nextInt(2); // +1 or +2
        final third = second + 1 + _random.nextInt(2); // +1 or +2
        final fourth = third + (_random.nextBool() ? -1 : 1); // fluctuate
        return '$start$second${third % 10}${fourth % 10}';
      },
    ];

    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateLeadingZeroPattern() {
    final patterns = [
      // Leading Zero (000X) - like 0007, 0009, 0005
      () {
        final last = 1 + _random.nextInt(9); // 1-9
        return '000$last';
      },
      // Leading Zero (00XY) - like 0012, 0034, 0077
      () {
        final third = _random.nextInt(10);
        final fourth = _random.nextInt(10);
        return '00$third$fourth';
      },
      // Leading Zero (0XXX) - like 0770, 0334, 0556
      () {
        final second = _random.nextInt(10);
        final third = _random.nextInt(10); // Any digit, not forced to match
        final fourth = _random.nextInt(10);
        return '0$second$third$fourth';
      },
    ];

    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateSandwichPattern() {
    final patterns = [
      // ACBA pattern - positions 0 and 2 match (like 1716)
      () {
        final a = _random.nextInt(10);
        final c = _random.nextInt(10);
        final b = _random.nextInt(10);
        // Ensure it's not ABAB (which would be caught as repeating pair)
        if (a == c || b == a) {
          // Try again with different values
          final newC = (c + 1) % 10;
          return '$a$newC$a$b';
        }
        return '$a$c$a$b';
      },
      // ABCB pattern - positions 1 and 3 match (like 7464, 2717, 6535)
      () {
        final a = _random.nextInt(10);
        final b = _random.nextInt(10);
        final c = _random.nextInt(10);
        // Ensure it's not mirror (ABBA) or other patterns
        if (a == c || a == b || c == b) {
          final newC = (c + 1) % 10;
          return '$a$b$newC$b';
        }
        return '$a$b$c$b';
      },
    ];

    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateEndingZeroStyle() {
    final patterns = [
      // X0Y0 pattern (like 1030, 5070, 9040)
      () {
        final first = 1 + _random.nextInt(9); // 1-9
        final third = 1 + _random.nextInt(9); // 1-9
        return '${first}0${third}0';
      },
      // XY0Z pattern with zero in third position (like 9040, 2105)
      () {
        final first = _random.nextInt(10);
        final second = _random.nextInt(10);
        final fourth = _random.nextInt(10);
        return '$first${second}0$fourth';
      },
    ];

    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _getTodayDateString() {
    final now = DateTime.now();
    
    // If it's after 3 PM, generate predictions for tomorrow's lottery
    final targetDate = now.hour >= 15 ? now.add(const Duration(days: 1)) : now;
    
    return '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
  }

  static Future<void> clearOldPredictions() async {
    await init();
    
    final today = DateTime.now();
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    
    final keysToDelete = <String>[];
    final box = _box;
    
    if (box != null) {
      for (var key in box.keys) {
        final prediction = box.get(key);
        if (prediction != null && prediction.generatedAt.isBefore(sevenDaysAgo)) {
          keysToDelete.add(key.toString());
        }
      }
      
      for (final key in keysToDelete) {
        await box.delete(key);
      }
    }
  }

  static Future<bool> hasGeneratedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastGeneratedDateKey);
    final today = _getTodayDateString();
    return lastDate == today;
  }

  static Future<void> markGeneratedToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastGeneratedDateKey, _getTodayDateString());
  }

  static Future<Map<String, dynamic>> getPredictionStats() async {
    await init();
    
    final box = _box;
    int totalPredictions = 0;
    int todayPredictions = 0;
    final today = _getTodayDateString();
    
    if (box != null) {
      totalPredictions = box.length;
      
      for (var prediction in box.values) {
        if (prediction.date == today) {
          todayPredictions++;
        }
      }
    }
    
    return {
      'total': totalPredictions,
      'today': todayPredictions,
      'last_cleanup': DateTime.now().toIso8601String(),
    };
  }
}