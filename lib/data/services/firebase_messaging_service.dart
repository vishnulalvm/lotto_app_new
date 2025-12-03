import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lotto_app/data/datasource/api/notification/fcm_api_service.dart';
import 'package:lotto_app/data/services/user_service.dart';
import 'package:go_router/go_router.dart';
import 'package:lotto_app/routes/app_routes.dart';
import 'package:lotto_app/routes/route_names.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FcmApiService _fcmApiService = FcmApiService();
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Singleton instances to avoid repeated instantiation
  static UserService? _userService;
  static SharedPreferences? _sharedPreferences;
  static String? _currentToken;

  /// Get singleton UserService instance
  static UserService get _userServiceInstance {
    return _userService ??= UserService();
  }

  /// Get singleton SharedPreferences instance
  static Future<SharedPreferences> get _prefsInstance async {
    return _sharedPreferences ??= await SharedPreferences.getInstance();
  }

  /// Initialize Firebase messaging
  static Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request notification permissions
    await _requestPermissions();

    // Get the token
    await _getToken();

    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      developer.log('Local notifications initialized successfully',
          name: 'FirebaseMessaging');
    } catch (e) {
      developer.log('Failed to initialize local notifications: $e',
          name: 'FirebaseMessaging', error: e);
    }
  }

  /// Handle notification tap from local notifications
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        // Parse JSON payload and navigate accordingly
        final data = jsonDecode(response.payload!);
        _navigateBasedOnData(data);
      } else {
        // Default navigation when no payload
        _navigateToHome();
      }
    } catch (e) {
      developer.log('Failed to handle notification tap: $e',
          name: 'FirebaseMessaging', error: e);
      // Fallback to home screen
      _navigateToHome();
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Get FCM token
  static Future<String?> _getToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      developer.log('FCM token retrieved successfully',
          name: 'FirebaseMessaging');
      return _currentToken;
    } catch (e) {
      developer.log('Failed to get FCM token: $e',
          name: 'FirebaseMessaging', error: e);
      return null;
    }
  }

  /// Get current FCM token
  static String? get currentToken => _currentToken;

  /// Register FCM token with backend
  /// Smart registration: only registers if token or user changed
  static Future<bool> registerToken({bool notificationsEnabled = true}) async {
    try {
      final prefs = await _prefsInstance;
      final token = _currentToken ?? await _getToken();
      final phoneNumber = await _userServiceInstance.getPhoneNumber();

      if (token == null || phoneNumber == null) {
        developer.log('Cannot register: token or phone number is null',
            name: 'FirebaseMessaging');
        return false;
      }

      // Check if we've already registered this token for this user
      final lastRegisteredToken = prefs.getString('last_registered_fcm_token');
      final lastRegisteredPhone = prefs.getString('last_registered_phone_number');
      final lastRegistrationTime = prefs.getInt('last_fcm_registration_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Skip registration if:
      // 1. Same token AND same phone number
      // 2. Last registration was within 24 hours (prevent server spam)
      final timeSinceLastRegistration = now - lastRegistrationTime;
      final twentyFourHoursInMs = 24 * 60 * 60 * 1000;

      if (lastRegisteredToken == token &&
          lastRegisteredPhone == phoneNumber &&
          timeSinceLastRegistration < twentyFourHoursInMs) {
        developer.log(
          'Skipping FCM registration: token already registered '
          '${Duration(milliseconds: timeSinceLastRegistration).inHours}h ago',
          name: 'FirebaseMessaging'
        );
        return true; // Return true since token is already registered
      }

      // Log reason for registration
      if (lastRegisteredToken != token) {
        developer.log('FCM token changed, re-registering', name: 'FirebaseMessaging');
      } else if (lastRegisteredPhone != phoneNumber) {
        developer.log('Phone number changed, re-registering FCM token',
            name: 'FirebaseMessaging');
      } else {
        developer.log('24+ hours since last registration, refreshing',
            name: 'FirebaseMessaging');
      }

      // Perform registration
      final success = await _handleTokenOperation(
        notificationsEnabled: notificationsEnabled,
        isUpdate: false,
      );

      // Save registration details on success
      if (success) {
        await prefs.setString('last_registered_fcm_token', token);
        await prefs.setString('last_registered_phone_number', phoneNumber);
        await prefs.setInt('last_fcm_registration_time', now);
        developer.log('FCM registration successful and cached',
            name: 'FirebaseMessaging');
      }

      return success;
    } catch (e) {
      developer.log('FCM smart registration failed: $e',
          name: 'FirebaseMessaging', error: e);
      return false;
    }
  }

  /// Update notification settings
  static Future<bool> updateNotificationSettings(bool enabled) async {
    return await _handleTokenOperation(
      notificationsEnabled: enabled,
      isUpdate: true,
    );
  }

  /// Common method to handle token registration and updates
  static Future<bool> _handleTokenOperation({
    required bool notificationsEnabled,
    required bool isUpdate,
  }) async {
    try {
      final token = _currentToken ?? await _getToken();
      if (token == null) {
        developer.log('FCM token is null', name: 'FirebaseMessaging');
        return false;
      }

      final phoneNumber = await _userServiceInstance.getPhoneNumber();
      final name = await _userServiceInstance.getUserName();

      if (phoneNumber == null) {
        developer.log('Phone number is null', name: 'FirebaseMessaging');
        return false;
      }

      if (isUpdate) {
        await _fcmApiService.updateNotificationSettings(
          fcmToken: token,
          phoneNumber: phoneNumber,
          name: name ?? 'User',
          notificationsEnabled: notificationsEnabled,
        );
      } else {
        await _fcmApiService.registerFcmToken(
          fcmToken: token,
          phoneNumber: phoneNumber,
          name: name ?? 'User',
          notificationsEnabled: notificationsEnabled,
        );
      }

      // Save notification preference locally using singleton instance
      final prefs = await _prefsInstance;
      await prefs.setBool('notifications_enabled', notificationsEnabled);

      return true;
    } catch (e) {
      developer.log('Token operation failed: $e',
          name: 'FirebaseMessaging', error: e);
      return false;
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        // Encode data as JSON for proper parsing later
        final payload =
            message.data.isNotEmpty ? jsonEncode(message.data) : null;

        // Show local notification with large icon for foreground messages
        _showLocalNotification(
          id: notification.hashCode,
          title: notification.title ?? 'Kerala Lottery',
          body: notification.body ?? 'New lottery notification',
          payload: payload,
        );

        developer.log('Foreground notification displayed',
            name: 'FirebaseMessaging');
      }
    } catch (e) {
      developer.log('Failed to handle foreground message: $e',
          name: 'FirebaseMessaging', error: e);
    }
  }

  /// Show local notification with large icon
  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'Channel for foreground notifications',
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('ic_stat_new_small_logo'),
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      developer.log('Local notification shown successfully',
          name: 'FirebaseMessaging');
    } catch (e) {
      developer.log('Failed to show local notification: $e',
          name: 'FirebaseMessaging', error: e);
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      _navigateBasedOnData(message.data);
      developer.log('Notification tap handled successfully',
          name: 'FirebaseMessaging');
    } catch (e) {
      developer.log('Failed to handle notification tap: $e',
          name: 'FirebaseMessaging', error: e);
      _navigateToHome();
    }
  }

  /// Navigate based on notification data
  static void _navigateBasedOnData(Map<String, dynamic> data) {
    // If context is not available, wait and retry
    _attemptNavigation(data, retryCount: 0);
  }
  
  /// Attempt navigation with retry logic for app initialization
  static void _attemptNavigation(Map<String, dynamic> data, {int retryCount = 0}) {
    final context = AppRouter.navigatorKey.currentContext;

    if (context == null) {
      if (retryCount < 10) { // Max 10 retries (5 seconds)
        developer.log('Navigation context null, retrying in 500ms (attempt ${retryCount + 1})', 
            name: 'FirebaseMessaging');
        Future.delayed(const Duration(milliseconds: 500), () {
          _attemptNavigation(data, retryCount: retryCount + 1);
        });
        return;
      } else {
        developer.log('Navigation context still null after retries', 
            name: 'FirebaseMessaging');
        return;
      }
    }

    final notificationType = data['type'];

    try {
      switch (notificationType) {
        case 'live_result_starts':
          context.pushNamed(RouteNames.liveVideoScreen);
          break;
        case 'new_result':
        case 'result_ready':
        case 'result_published':
          final uniqueId = data['uniqueId'];
          if (uniqueId != null) {
            context.push('/result-details', extra: {
              'uniqueId': uniqueId,
              'isNew': true,
            });
          } else {
            context.go('/');
          }
          break;
        case 'test':
          context.go('/');
          break;
        default:
          context.go('/');
          break;
      }
      
      developer.log('Navigation completed successfully for type: $notificationType', 
          name: 'FirebaseMessaging');
    } catch (e) {
      developer.log('Navigation failed, falling back to home: $e',
          name: 'FirebaseMessaging', error: e);
      _navigateToHome();
    }
  }

  /// Safe navigation to home screen
  static void _navigateToHome() {
    try {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        context.go('/');
      }
    } catch (e) {
      developer.log('Failed to navigate to home: $e',
          name: 'FirebaseMessaging', error: e);
    }
  }

  /// Handle token refresh
  static void _onTokenRefresh(String token) {
    _currentToken = token;
    developer.log('FCM token refreshed', name: 'FirebaseMessaging');

    // Re-register with the new token (smart registration will detect token change)
    registerToken().catchError((error) {
      developer.log('Failed to re-register token after refresh: $error',
          name: 'FirebaseMessaging', error: error);
      return false;
    });
  }

  /// Clear FCM registration cache
  /// Call this when user logs out to force re-registration on next login
  static Future<void> clearRegistrationCache() async {
    try {
      final prefs = await _prefsInstance;
      await prefs.remove('last_registered_fcm_token');
      await prefs.remove('last_registered_phone_number');
      await prefs.remove('last_fcm_registration_time');
      developer.log('FCM registration cache cleared', name: 'FirebaseMessaging');
    } catch (e) {
      developer.log('Failed to clear FCM registration cache: $e',
          name: 'FirebaseMessaging', error: e);
    }
  }
}

// Background message handler should be in main.dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle the background message
  // This function must be a top-level function
}
