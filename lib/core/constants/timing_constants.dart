/// Timing constants for app initialization
/// Used in splash screen for staggered service initialization
abstract class TimingConstants {
  // Background service initialization delays (splash screen)
  // Staggered to prevent UI jank and spread CPU load

  /// Delay before analytics initialization
  static const Duration analyticsInitDelay = Duration(milliseconds: 50);

  /// Delay before app update service initialization
  static const Duration appUpdateInitDelay = Duration(milliseconds: 100);

  /// Delay before FCM initialization
  static const Duration fcmInitDelay = Duration(milliseconds: 200);

  /// Delay before AdMob initialization (heavy operation)
  static const Duration adMobInitDelay = Duration(milliseconds: 300);

  /// Delay before cache manager initialization
  static const Duration cacheManagerInitDelay = Duration(milliseconds: 400);

  /// Delay before user activity tracking (least critical)
  static const Duration userActivityInitDelay = Duration(milliseconds: 500);

  /// Audio warm-up delay
  static const Duration audioWarmUpDelay = Duration(milliseconds: 50);
}
