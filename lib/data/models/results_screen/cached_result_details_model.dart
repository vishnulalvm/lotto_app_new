import 'package:hive/hive.dart';
import 'package:lotto_app/data/models/results_screen/results_screen.dart';

part 'cached_result_details_model.g.dart';

@HiveType(typeId: 5)
class CachedResultDetailsModel {
  @HiveField(0)
  final String uniqueId;

  @HiveField(1)
  final Map<String, dynamic> data;

  @HiveField(2)
  final DateTime cachedAt;

  @HiveField(3)
  final DateTime expiresAt;

  CachedResultDetailsModel({
    required this.uniqueId,
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
  });

  factory CachedResultDetailsModel.fromResultDetails(
    String uniqueId,
    LotteryResultDetailsModel result,
  ) {
    final now = DateTime.now();
    return CachedResultDetailsModel(
      uniqueId: uniqueId,
      data: result.toJson(),
      cachedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
  }

  LotteryResultDetailsModel toResultDetails() {
    // Convert Map<dynamic, dynamic> to Map<String, dynamic> if needed
    final Map<String, dynamic> jsonData = _convertToStringKeyMap(data);
    return LotteryResultDetailsModel.fromJson(jsonData);
  }

  Map<String, dynamic> _convertToStringKeyMap(Map<dynamic, dynamic> input) {
    final Map<String, dynamic> result = {};
    
    for (final entry in input.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      if (value is Map<dynamic, dynamic>) {
        result[key] = _convertToStringKeyMap(value);
      } else if (value is List) {
        result[key] = _convertList(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }

  List<dynamic> _convertList(List<dynamic> input) {
    return input.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertToStringKeyMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isStale {
    final now = DateTime.now();
    // Consider data stale after 30 minutes
    return now.difference(cachedAt).inMinutes > 30;
  }

  bool get shouldRefreshInLiveHours {
    final now = DateTime.now();
    // During live hours (3-4 PM), refresh more frequently
    final isLiveHour = now.hour >= 15 && now.hour < 16;
    if (isLiveHour) {
      // Refresh every 2 minutes during live hours
      return now.difference(cachedAt).inMinutes > 2;
    }
    return isStale;
  }
}