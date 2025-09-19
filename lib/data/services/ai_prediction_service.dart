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
    // Define fancy number patterns based on analysis
    final List<String Function()> fancyPatterns = [
      // Repeating digit patterns (like 3454, 2244, 2525, 4455, 7007, 0770)
      () => _generateRepeatingPattern(),
      // Round numbers with trailing zeros (like 3001, 1000)
      () => _generateRoundNumber(),
      // Sequential or pattern numbers (like 1210, 3530)
      () => _generateSequentialPattern(),
      // Numbers with leading zeros (like 0007, 0770)
      () => _generateLeadingZeroPattern(),
      // Double digit patterns (like 1122, 3344, 5566)
      () => _generateDoubleDigitPattern(),
    ];
    
    // Randomly select a pattern type (70% fancy patterns, 30% regular random)
    if (_random.nextDouble() < 0.7) {
      final patternGenerator = fancyPatterns[_random.nextInt(fancyPatterns.length)];
      return patternGenerator();
    } else {
      // 30% chance for regular random numbers
      return _generateRegularNumber();
    }
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
      // Sequential ascending (like 1234, 2345)
      () {
        final start = _random.nextInt(7);
        return '$start${start + 1}${start + 2}${start + 3}';
      },
      // Sequential descending (like 4321, 5432)
      () {
        final start = 3 + _random.nextInt(7);
        return '$start${start - 1}${start - 2}${start - 3}';
      },
      // Mixed pattern (like 1210, 3530)
      () {
        final a = _random.nextInt(10);
        final b = _random.nextInt(10);
        return '$a$b${(a + 1) % 10}$a';
      },
    ];
    
    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateLeadingZeroPattern() {
    final patterns = [
      // 000X pattern (like 0007, 0009)
      () {
        final last = 1 + _random.nextInt(9);
        return '000$last';
      },
      // 00XY pattern (like 0012, 0034, 0077)
      () {
        final third = _random.nextInt(10);
        final fourth = _random.nextInt(10);
        return '00$third$fourth';
      },
      // 0XXX pattern with specific patterns (like 0770)
      () {
        final second = _random.nextInt(10);
        final third = second; // Same digit
        final fourth = _random.nextInt(10);
        return '0$second$third$fourth';
      },
    ];
    
    return patterns[_random.nextInt(patterns.length)]();
  }

  static String _generateDoubleDigitPattern() {
    // Generate numbers like 1122, 3344, 5566, 7788
    final first = 1 + _random.nextInt(9);
    final second = 1 + _random.nextInt(9);
    return '$first$first$second$second';
  }

  static String _generateRegularNumber() {
    final number = 1000 + _random.nextInt(9000);
    return number.toString().padLeft(4, '0');
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