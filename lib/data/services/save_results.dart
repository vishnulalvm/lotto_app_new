import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/home_screen/home_screen_model.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';
import 'package:lotto_app/data/models/results_screen/save_result.dart';

class SavedResultsService {
  static const String _boxName = 'saved_lottery_results';
  static Box<SavedLotteryResult>? _box;

  // Initialize Hive box
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SavedLotteryResultAdapter());
    }
    _box = await Hive.openBox<SavedLotteryResult>(_boxName);
  }

  // Get the box instance
  static Box<SavedLotteryResult> get _getBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SavedResultsService not initialized. Call init() first.');
    }
    return _box!;
  }

  // Save a home screen lottery result
  static Future<bool> saveHomeScreenResult(HomeScreenResultModel result) async {
    try {
      final box = _getBox;
      
      // Check if already saved
      if (isResultSaved(result.uniqueId)) {
        return false; // Already saved
      }

      final savedResult = SavedLotteryResult.fromHomeScreenResult(result);
      await box.put(result.uniqueId, savedResult);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Save a detailed lottery result
  static Future<bool> saveLotteryResult(LotteryResultModel result) async {
    try {
      final box = _getBox;
      
      // Check if already saved
      if (isResultSaved(result.uniqueId)) {
        return false; // Already saved
      }

      final savedResult = SavedLotteryResult.fromLotteryResult(result);
      await box.put(result.uniqueId, savedResult);
      return true;
    } catch (e) {
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Remove a saved lottery result
  static Future<bool> removeSavedResult(String uniqueId) async {
    try {
      final box = _getBox;
      await box.delete(uniqueId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if a result is saved
  static bool isResultSaved(String uniqueId) {
    try {
      final box = _getBox;
      return box.containsKey(uniqueId);
    } catch (e) {
      return false;
    }
  }

  // Get all saved results
  static List<SavedLotteryResult> getAllSavedResults() {
    try {
      final box = _getBox;
      return box.values.toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt)); // Sort by newest first
    } catch (e) {
      return [];
    }
  }

  // Get saved result by uniqueId
  static SavedLotteryResult? getSavedResult(String uniqueId) {
    try {
      final box = _getBox;
      return box.get(uniqueId);
    } catch (e) {
      return null;
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String uniqueId) async {
    try {
      final box = _getBox;
      final savedResult = box.get(uniqueId);
      if (savedResult != null) {
        savedResult.isFavorite = !savedResult.isFavorite;
        await savedResult.save(); // Hive object save method
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get favorite results only
  static List<SavedLotteryResult> getFavoriteResults() {
    try {
      final box = _getBox;
      return box.values.where((result) => result.isFavorite).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (e) {
      return [];
    }
  }

  // Clear all saved results
  static Future<bool> clearAllSavedResults() async {
    try {
      final box = _getBox;
      await box.clear();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get total count of saved results
  static int getSavedResultsCount() {
    try {
      final box = _getBox;
      return box.length;
    } catch (e) {
      return 0;
    }
  }
}