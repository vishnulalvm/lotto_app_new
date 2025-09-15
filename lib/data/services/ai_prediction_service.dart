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
    
    // Generate 12 unique random 4-digit numbers
    while (numbers.length < 12) {
      String number;
      
      switch (prizeType) {
        case 5:
          number = _generateNumber(1000, 9999); // 4-digit for 5th prize
          break;
        case 6:
          number = _generateNumber(1000, 9999); // 4-digit for 6th prize
          break;
        case 7:
          number = _generateNumber(1000, 9999); // 4-digit for 7th prize
          break;
        case 8:
          number = _generateNumber(1000, 9999); // 4-digit for 8th prize
          break;
        case 9:
          number = _generateNumber(1000, 9999); // 4-digit for 9th prize
          break;
        default:
          number = _generateNumber(1000, 9999); // Default 4-digit
          break;
      }
      
      if (!usedNumbers.contains(number)) {
        numbers.add(number);
        usedNumbers.add(number);
      }
    }
    
    return numbers;
  }

  static String _generateNumber(int min, int max) {
    final number = min + _random.nextInt(max - min + 1);
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