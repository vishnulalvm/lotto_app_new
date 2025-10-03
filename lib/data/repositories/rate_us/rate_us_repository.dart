import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing rate us dialog preferences
abstract class RateUsRepository {
  Future<bool> isPermanentlyDismissed();
  Future<int> getVisitCount();
  Future<void> incrementVisitCount();
  Future<void> resetVisitCount();
  Future<void> markPermanentlyDismissed();
}

class RateUsRepositoryImpl implements RateUsRepository {
  static const String _prefKeyHomeVisitCount = 'home_visit_count';
  static const String _prefKeyRateUsShown = 'rate_us_permanently_dismissed';

  @override
  Future<bool> isPermanentlyDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyRateUsShown) ?? false;
  }

  @override
  Future<int> getVisitCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyHomeVisitCount) ?? 0;
  }

  @override
  Future<void> incrementVisitCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_prefKeyHomeVisitCount) ?? 0;
    await prefs.setInt(_prefKeyHomeVisitCount, currentCount + 1);
  }

  @override
  Future<void> resetVisitCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyHomeVisitCount, 0);
  }

  @override
  Future<void> markPermanentlyDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyRateUsShown, true);
  }
}
