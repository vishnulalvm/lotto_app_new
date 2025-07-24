import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lotto_app/data/datasource/api/notification/fcm_api_service.dart';
import 'package:lotto_app/data/services/user_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FcmApiService _fcmApiService = FcmApiService();
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  static String? _currentToken;
  
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
    } catch (e) {
    }
  }
  
  /// Handle notification tap from local notifications
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on payload
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
      return _currentToken;
    } catch (e) {
      return null;
    }
  }
  
  /// Get current FCM token
  static String? get currentToken => _currentToken;
  
  /// Register FCM token with backend
  static Future<bool> registerToken({bool notificationsEnabled = true}) async {
    try {
      final token = _currentToken ?? await _getToken();
      if (token == null) {
        return false;
      }
      
      final userService = UserService();
      final phoneNumber = await userService.getPhoneNumber();
      final name = await userService.getUserName();
      
      if (phoneNumber == null) {
        return false;
      }

      await _fcmApiService.registerFcmToken(
        fcmToken: token,
        phoneNumber: phoneNumber,
        name: name ?? 'User',
        notificationsEnabled: notificationsEnabled,
      );
      
      // Save notification preference locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', notificationsEnabled);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Update notification settings
  static Future<bool> updateNotificationSettings(bool enabled) async {
    try {
      final token = _currentToken ?? await _getToken();
      if (token == null) {
        return false;
      }
      
      final userService = UserService();
      final phoneNumber = await userService.getPhoneNumber();
      final name = await userService.getUserName();
      
      if (phoneNumber == null) {
        return false;
      }
      
      await _fcmApiService.updateNotificationSettings(
        fcmToken: token,
        phoneNumber: phoneNumber,
        name: name ?? 'User',
        notificationsEnabled: enabled,
      );
      
      // Save notification preference locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    
    if (notification != null) {
      // Show local notification with large icon for foreground messages
      _showLocalNotification(
        id: notification.hashCode,
        title: notification.title ?? 'Kerala Lottery',
        body: notification.body ?? 'New lottery notification',
        payload: message.data.toString(),
      );
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
            largeIcon: DrawableResourceAndroidBitmap('ic_stat_new_small_logo'), // Use your custom icon
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
    } catch (e) {
      // Fallback - notification will still be handled by FCM automatically
    }
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification data
    final notificationType = message.data['type'];
    
    switch (notificationType) {
      case 'live_result_starts':
        // Navigate to live results or home screen
        break;
      case 'result_published':
        // Navigate to specific result details
        break;
      case 'test':
        // Handle test notification
        break;
      default:
        // Navigate to home screen
        break;
    }
  }
  
  /// Handle token refresh
  static void _onTokenRefresh(String token) {
    _currentToken = token;
    
    // Re-register with the new token
    registerToken().catchError((error) {
      return false;
    });
  }
}

// Background message handler should be in main.dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle the background message
  // This function must be a top-level function
}