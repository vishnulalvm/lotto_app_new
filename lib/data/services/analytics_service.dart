import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// Initialize Firebase Analytics
  static Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
    
    // Set analytics collection enabled
    await _analytics!.setAnalyticsCollectionEnabled(true);
    
    // Track first time user
    await _trackFirstTimeUser();
  }

  /// Get analytics instance
  static FirebaseAnalytics get analytics {
    assert(_analytics != null, 'Analytics not initialized');
    return _analytics!;
  }

  /// Get analytics observer for navigation
  static FirebaseAnalyticsObserver get observer {
    assert(_observer != null, 'Analytics observer not initialized');
    return _observer!;
  }

  /// Track first time user
  static Future<void> _trackFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = !(prefs.getBool('user_opened_app_before') ?? false);
    
    if (isFirstTime) {
      await _analytics!.logEvent(
        name: 'app_first_open', // changed from 'first_open' to avoid reserved name
        parameters: {
          'platform': defaultTargetPlatform.name,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Mark user as having opened the app
      await prefs.setBool('user_opened_app_before', true);
      await prefs.setString('first_open_date', DateTime.now().toIso8601String());
    }
    
    // Always log app open for active user tracking
    await _analytics!.logEvent(
      name: 'app_open',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_new_user': isFirstTime ? 1 : 0, // changed from bool to int
      },
    );
  }

  /// Track screen views
  static Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) async {
    // Convert any boolean parameters to int
    final safeParameters = parameters?.map((key, value) =>
      value is bool ? MapEntry(key, value ? 1 : 0) : MapEntry(key, value)
    );
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
      parameters: safeParameters,
    );
  }

  /// Track user engagement
  static Future<void> trackUserEngagement({
    required String action,
    String? category,
    String? label,
    int? value,
    Map<String, Object>? parameters,
  }) async {
    final Map<String, Object> eventParameters = {
      'action': action,
      if (category != null) 'category': category,
      if (label != null) 'label': label,
      if (value != null) 'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?parameters,
    };

    await _analytics?.logEvent(
      name: 'custom_user_engagement',
      parameters: eventParameters,
    );
  }

  /// Track custom events
  static Future<void> trackEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    await _analytics?.logEvent(
      name: eventName,
      parameters: parameters ?? {},
    );
  }

  /// Track lottery-specific events
  static Future<void> trackLotteryEvent({
    required String eventType,
    String? lotteryName,
    String? ticketNumber,
    String? resultDate,
    Map<String, Object>? additionalParams,
  }) async {
    final Map<String, Object> parameters = {
      'event_type': eventType,
      if (lotteryName != null) 'lottery_name': lotteryName,
      if (ticketNumber != null) 'ticket_number': ticketNumber,
      if (resultDate != null) 'result_date': resultDate,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?additionalParams,
    };

    await _analytics?.logEvent(
      name: 'lottery_interaction',
      parameters: parameters,
    );
  }

  /// Track search events
  static Future<void> trackSearch({
    required String searchTerm,
    String? searchCategory,
    int? resultsCount,
  }) async {
    await _analytics?.logSearch(
      searchTerm: searchTerm,
      parameters: {
        if (searchCategory != null) 'search_category': searchCategory,
        if (resultsCount != null) 'results_count': resultsCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track sharing events
  static Future<void> trackShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _analytics?.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method ?? 'unknown',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track login events
  static Future<void> trackLogin({
    required String loginMethod,
    bool success = true,
  }) async {
    await _analytics?.logLogin(
      loginMethod: loginMethod,
      parameters: {
        'success': success ? 'true' : 'false', // Convert boolean to string for Firebase Analytics
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track signup events
  static Future<void> trackSignUp({
    required String signUpMethod,
    bool success = true,
  }) async {
    await _analytics?.logSignUp(
      signUpMethod: signUpMethod,
      parameters: {
        'success': success ? 'true' : 'false', // Convert boolean to string for Firebase Analytics
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track session timing
  static Future<void> trackSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_start', DateTime.now().millisecondsSinceEpoch);
    await _analytics?.logEvent(
      name: 'custom_session_start', // changed from reserved 'session_start'
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> trackSessionEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStart = prefs.getInt('session_start');
    
    if (sessionStart != null) {
      final sessionDuration = DateTime.now().millisecondsSinceEpoch - sessionStart;
      
      await _analytics?.logEvent(
        name: 'custom_session_end',
        parameters: {
          'session_duration': sessionDuration,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Clear session start time
      await prefs.remove('session_start');
    }
  }

  /// Track user properties
  static Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? preferredLanguage,
    Map<String, String>? customProperties,
  }) async {
    if (userId != null && userId.isNotEmpty) {
      await _analytics?.setUserId(id: userId);
    }
    
    if (userType != null && userType.isNotEmpty) {
      await _analytics?.setUserProperty(name: 'user_type', value: userType);
    }
    
    if (preferredLanguage != null && preferredLanguage.isNotEmpty) {
      await _analytics?.setUserProperty(name: 'preferred_language', value: preferredLanguage);
    }
    
    if (customProperties != null) {
      for (final entry in customProperties.entries) {
        if (entry.value.isNotEmpty) {
          await _analytics?.setUserProperty(name: entry.key, value: entry.value);
        }
      }
    }
  }

  /// Track errors
  static Future<void> trackError({
    required String errorMessage,
    String? errorCode,
    String? stackTrace,
    String? screen,
  }) async {
    await _analytics?.logEvent(
      name: 'app_error',
      parameters: {
        'error_message': errorMessage,
        if (errorCode != null) 'error_code': errorCode,
        if (stackTrace != null) 'stack_trace': stackTrace,
        if (screen != null) 'screen': screen,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track feature usage
  static Future<void> trackFeatureUsage({
    required String featureName,
    String? action,
    Map<String, Object>? parameters,
  }) async {
    await _analytics?.logEvent(
      name: 'feature_usage',
      parameters: {
        'feature_name': featureName,
        if (action != null) 'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?parameters,
      },
    );
  }

  /// Track widget views with daily count
  static Future<void> track({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toLocal().toString().split(' ')[0]; // YYYY-MM-DD format
    final countKey = '${eventName}_count_$today';
    
    // Get current daily count and increment
    final currentCount = prefs.getInt(countKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(countKey, newCount);
    
    // Track the event with daily count
    await _analytics?.logEvent(
      name: eventName,
      parameters: {
        'daily_count': newCount,
        'date': today,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...parameters ?? {},
      },
    );
  }

  /// Get daily view count for a specific event
  static Future<int> getDailyCount(String eventName) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toLocal().toString().split(' ')[0];
    final countKey = '${eventName}_count_$today';
    return prefs.getInt(countKey) ?? 0;
  }

  /// Clear old analytics data (older than 30 days)
  static Future<void> cleanupOldAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    for (final key in keys) {
      if (key.contains('_count_')) {
        final parts = key.split('_count_');
        if (parts.length == 2) {
          try {
            final dateStr = parts[1];
            final date = DateTime.parse(dateStr);
            if (date.isBefore(cutoffDate)) {
              await prefs.remove(key);
            }
          } catch (e) {
            // Invalid date format, remove the key
            await prefs.remove(key);
          }
        }
      }
    }
  }

  // ============================================================================
  // GOOGLE ADS OPTIMIZATION - Ad Impression & Revenue Tracking
  // ============================================================================

  /// Track ad impressions with revenue for LTV calculation
  /// This helps Google Ads optimize for high-value users
  static Future<void> trackAdImpression({
    required String adFormat, // 'interstitial', 'native', 'rewarded', 'banner'
    required String adUnitId,
    String? adSource, // e.g., 'admob'
    double? value, // estimated revenue in USD
    String? currency,
    String? placement, // where ad was shown (e.g., 'home_screen', 'result_details')
  }) async {
    await _analytics?.logEvent(
      name: 'ad_impression',
      parameters: {
        'ad_format': adFormat,
        'ad_unit_id': adUnitId,
        if (adSource != null) 'ad_source': adSource,
        if (value != null) 'value': value,
        if (currency != null) 'currency': currency,
        if (placement != null) 'ad_placement': placement,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Update cumulative ad revenue for user LTV
    await _updateUserLTV(value ?? 0.0);
  }

  /// Track when user clicks on an ad
  static Future<void> trackAdClick({
    required String adFormat,
    required String adUnitId,
    String? placement,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_click',
      parameters: {
        'ad_format': adFormat,
        'ad_unit_id': adUnitId,
        if (placement != null) 'ad_placement': placement,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track when user dismisses/closes an ad
  static Future<void> trackAdDismissed({
    required String adFormat,
    required String adUnitId,
    String? placement,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_dismissed',
      parameters: {
        'ad_format': adFormat,
        'ad_unit_id': adUnitId,
        if (placement != null) 'ad_placement': placement,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track when ad fails to load
  static Future<void> trackAdLoadFailed({
    required String adFormat,
    required String adUnitId,
    required String errorCode,
    String? errorMessage,
  }) async {
    await _analytics?.logEvent(
      name: 'ad_load_failed',
      parameters: {
        'ad_format': adFormat,
        'ad_unit_id': adUnitId,
        'error_code': errorCode,
        if (errorMessage != null) 'error_message': errorMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Update user's lifetime value based on ad revenue
  static Future<void> _updateUserLTV(double revenueValue) async {
    if (revenueValue <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final currentLTV = prefs.getDouble('user_ltv') ?? 0.0;
    final newLTV = currentLTV + revenueValue;

    await prefs.setDouble('user_ltv', newLTV);

    // Update user property for audience segmentation
    String ltvTier = 'low';
    if (newLTV >= 1.0) ltvTier = 'medium';
    if (newLTV >= 5.0) ltvTier = 'high';
    if (newLTV >= 10.0) ltvTier = 'very_high';

    await _analytics?.setUserProperty(name: 'ltv_tier', value: ltvTier);
  }

  /// Get current user LTV (Lifetime Value)
  static Future<double> getUserLTV() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('user_ltv') ?? 0.0;
  }

  // ============================================================================
  // GOOGLE ADS OPTIMIZATION - Feature Adoption & Engagement
  // ============================================================================

  /// Track when user completes onboarding/tutorial
  /// This is a recommended event for Google Ads app campaigns
  static Future<void> trackTutorialComplete() async {
    await _analytics?.logEvent(
      name: 'tutorial_complete',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Mark user as having completed tutorial
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  /// Track barcode scanning events
  static Future<void> trackBarcodeScan({
    required String status, // 'attempt', 'success', 'failure'
    String? scanSource, // 'camera', 'gallery'
    String? resultType, // 'lottery_ticket', 'unknown'
    String? errorReason,
  }) async {
    await _analytics?.logEvent(
      name: 'barcode_scan',
      parameters: {
        'scan_status': status,
        if (scanSource != null) 'scan_source': scanSource,
        if (resultType != null) 'result_type': resultType,
        if (errorReason != null) 'error_reason': errorReason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Track first-time feature usage
    if (status == 'success') {
      await _trackFirstTimeFeatureUsage('barcode_scanner');
    }
  }

  /// Track scratch card interactions
  static Future<void> trackScratchCard({
    required String action, // 'started', 'completed', 'result_revealed'
    String? ticketNumber,
    String? resultDate,
    bool? isWinner,
    String? prizeAmount,
  }) async {
    await _analytics?.logEvent(
      name: 'scratch_card',
      parameters: {
        'scratch_action': action,
        if (ticketNumber != null) 'ticket_number': ticketNumber,
        if (resultDate != null) 'result_date': resultDate,
        if (isWinner != null) 'is_winner': isWinner ? 1 : 0,
        if (prizeAmount != null) 'prize_amount': prizeAmount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Track first-time feature usage
    if (action == 'started') {
      await _trackFirstTimeFeatureUsage('scratch_card');
    }
  }

  /// Track prize claim events
  static Future<void> trackPrizeClaim({
    required String status, // 'initiated', 'completed', 'failed'
    String? ticketNumber,
    String? prizeAmount,
    String? claimMethod, // 'online', 'in_person'
    String? errorReason,
  }) async {
    await _analytics?.logEvent(
      name: 'prize_claim',
      parameters: {
        'claim_status': status,
        if (ticketNumber != null) 'ticket_number': ticketNumber,
        if (prizeAmount != null) 'prize_amount': prizeAmount,
        if (claimMethod != null) 'claim_method': claimMethod,
        if (errorReason != null) 'error_reason': errorReason,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track result viewing with engagement depth
  static Future<void> trackResultViewed({
    required String lotteryName,
    String? resultDate,
    String? uniqueId,
    String? viewSource, // 'home', 'search', 'notification'
    int? viewDuration, // milliseconds
  }) async {
    await _analytics?.logEvent(
      name: 'result_viewed',
      parameters: {
        'lottery_name': lotteryName,
        if (resultDate != null) 'result_date': resultDate,
        if (uniqueId != null) 'unique_id': uniqueId,
        if (viewSource != null) 'view_source': viewSource,
        if (viewDuration != null) 'view_duration_ms': viewDuration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// Track first-time usage of a feature (internal helper)
  static Future<void> _trackFirstTimeFeatureUsage(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_use_$featureName';

    if (!prefs.containsKey(key)) {
      await prefs.setBool(key, true);
      await _analytics?.logEvent(
        name: 'feature_first_use',
        parameters: {
          'feature_name': featureName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
  }

  // ============================================================================
  // GOOGLE ADS OPTIMIZATION - User Segmentation & Properties
  // ============================================================================

  /// Set comprehensive user properties for Google Ads audience targeting
  static Future<void> setEnhancedUserProperties({
    String? userId,
    String? userType,
    String? preferredLanguage,
    String? engagementLevel, // 'high', 'medium', 'low'
    String? featurePreference, // 'scanner', 'scratch_card', 'results_viewer'
    Map<String, String>? customProperties,
  }) async {
    // Set standard properties
    if (userId != null && userId.isNotEmpty) {
      await _analytics?.setUserId(id: userId);
    }

    if (userType != null && userType.isNotEmpty) {
      await _analytics?.setUserProperty(name: 'user_type', value: userType);
    }

    if (preferredLanguage != null && preferredLanguage.isNotEmpty) {
      await _analytics?.setUserProperty(name: 'language', value: preferredLanguage);
    }

    // Set engagement-based properties
    if (engagementLevel != null && engagementLevel.isNotEmpty) {
      await _analytics?.setUserProperty(name: 'engagement_level', value: engagementLevel);
    }

    if (featurePreference != null && featurePreference.isNotEmpty) {
      await _analytics?.setUserProperty(name: 'feature_preference', value: featurePreference);
    }

    // Set device info
    await _analytics?.setUserProperty(name: 'platform', value: defaultTargetPlatform.name);

    // Calculate and set user tenure
    final prefs = await SharedPreferences.getInstance();
    final firstOpenDate = prefs.getString('first_open_date');
    if (firstOpenDate != null) {
      try {
        final firstOpen = DateTime.parse(firstOpenDate);
        final daysSinceInstall = DateTime.now().difference(firstOpen).inDays;

        String tenure = 'new'; // 0-7 days
        if (daysSinceInstall > 7) tenure = 'active'; // 8-30 days
        if (daysSinceInstall > 30) tenure = 'loyal'; // 31+ days

        await _analytics?.setUserProperty(name: 'user_tenure', value: tenure);
      } catch (e) {
        // Invalid date format, skip
      }
    }

    // Set custom properties
    if (customProperties != null) {
      for (final entry in customProperties.entries) {
        if (entry.value.isNotEmpty) {
          await _analytics?.setUserProperty(name: entry.key, value: entry.value);
        }
      }
    }
  }

  /// Calculate and update user engagement level based on activity
  static Future<void> updateEngagementLevel() async {
    final prefs = await SharedPreferences.getInstance();

    // Count sessions in last 7 days
    int sessionCount = 0;
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toLocal().toString().split(' ')[0];
      final key = 'app_open_count_$dateStr';
      sessionCount += prefs.getInt(key) ?? 0;
    }

    // Classify engagement level
    String engagementLevel = 'low'; // 0-2 sessions
    if (sessionCount >= 3) engagementLevel = 'medium'; // 3-7 sessions
    if (sessionCount >= 8) engagementLevel = 'high'; // 8+ sessions

    await _analytics?.setUserProperty(name: 'engagement_level', value: engagementLevel);
  }

  /// Track daily active user (DAU)
  /// This automatically increments a daily counter
  static Future<void> trackDailyActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toLocal().toString().split(' ')[0];
    final key = 'dau_tracked_$today';

    // Only track once per day
    if (!prefs.containsKey(key)) {
      await prefs.setBool(key, true);
      await _analytics?.logEvent(
        name: 'daily_active_user',
        parameters: {
          'date': today,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
  }

  /// Track session with quality metrics
  static Future<void> trackEnhancedSessionStart({
    String? referrer,
    String? campaignId,
    String? campaignSource,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_start', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('session_screen_count', 0);
    await prefs.setInt('session_event_count', 0);

    await _analytics?.logEvent(
      name: 'session_start',
      parameters: {
        if (referrer != null) 'referrer': referrer,
        if (campaignId != null) 'campaign_id': campaignId,
        if (campaignSource != null) 'campaign_source': campaignSource,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    // Track DAU
    await trackDailyActiveUser();

    // Update engagement level
    await updateEngagementLevel();
  }

  /// Increment session screen count (call on each screen view)
  static Future<void> incrementSessionScreenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('session_screen_count') ?? 0;
    await prefs.setInt('session_screen_count', count + 1);
  }

  /// Track enhanced session end with quality metrics
  static Future<void> trackEnhancedSessionEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStart = prefs.getInt('session_start');
    final screenCount = prefs.getInt('session_screen_count') ?? 0;

    if (sessionStart != null) {
      final sessionDuration = DateTime.now().millisecondsSinceEpoch - sessionStart;

      // Classify session quality
      String sessionQuality = 'bounce'; // < 10 seconds
      if (sessionDuration > 10000) sessionQuality = 'short'; // 10-30 seconds
      if (sessionDuration > 30000) sessionQuality = 'medium'; // 30-120 seconds
      if (sessionDuration > 120000) sessionQuality = 'long'; // 2+ minutes

      await _analytics?.logEvent(
        name: 'session_end',
        parameters: {
          'session_duration_ms': sessionDuration,
          'session_duration_sec': (sessionDuration / 1000).round(),
          'screen_count': screenCount,
          'session_quality': sessionQuality,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Clear session data
      await prefs.remove('session_start');
      await prefs.remove('session_screen_count');
      await prefs.remove('session_event_count');
    }
  }
}