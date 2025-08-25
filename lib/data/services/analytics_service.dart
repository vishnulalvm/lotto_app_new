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
        'success': success,
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
        'success': success,
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
}