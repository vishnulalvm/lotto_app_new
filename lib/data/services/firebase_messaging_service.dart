import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/datasource/api/notification/fcm_api_service.dart';
import 'package:lotto_app/data/services/user_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FcmApiService _fcmApiService = FcmApiService();
  
  static String? _currentToken;
  
  /// Initialize Firebase messaging
  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();
    
    // Get the token
    await _getToken();
    
    // Configure foreground message handling
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Configure background message handling
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessageTopLevel);
    
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
  
  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      print('Notification permission granted: ${settings.authorizationStatus}');
    }
  }
  
  /// Get FCM token
  static Future<String?> _getToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $_currentToken');
      }
      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
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
        if (kDebugMode) {
          print('No FCM token available');
        }
        return false;
      }
      
      final userService = UserService();
      final phoneNumber = await userService.getPhoneNumber();
      final name = await userService.getUserName();
      
      if (phoneNumber == null) {
        if (kDebugMode) {
          print('No user logged in');
        }
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
      
      if (kDebugMode) {
        print('FCM token registered successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
      return false;
    }
  }
  
  /// Update notification settings
  static Future<bool> updateNotificationSettings(bool enabled) async {
    try {
      final token = _currentToken ?? await _getToken();
      if (token == null) {
        if (kDebugMode) {
          print('No FCM token available');
        }
        return false;
      }
      
      final userService = UserService();
      final phoneNumber = await userService.getPhoneNumber();
      final name = await userService.getUserName();
      
      if (phoneNumber == null) {
        if (kDebugMode) {
          print('No user logged in');
        }
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
      
      if (kDebugMode) {
        print('Notification settings updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating notification settings: $e');
      }
      return false;
    }
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Handling foreground message: ${message.messageId}');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification?.title}');
    }
    
    // You can show a local notification here or handle it as needed
    // For now, we'll just log it
  }
  
  /// Handle background messages
  // static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  //   if (kDebugMode) {
  //     print('Handling background message: ${message.messageId}');
  //   }
    
  //   // Handle the background message
  //   // This function must be a top-level function
  // }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Notification tapped: ${message.messageId}');
    }
    
    // Handle navigation based on notification data
    final notificationType = message.data['type'];
    
    switch (notificationType) {
      case 'live_result_starts':
        
        // Navigate to live results or home screen
        break;
      case 'result_published':
        // Navigate to specific result details
        break;
      default:
        // Navigate to home screen
        break;
    }
  }
  
  /// Handle token refresh
  static void _onTokenRefresh(String token) {
    if (kDebugMode) {
      print('FCM Token refreshed: $token');
    }
    _currentToken = token;
    
    // Re-register with the new token
    registerToken();
  }
}

/// Top-level function for handling background messages
Future<void> _handleBackgroundMessageTopLevel(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background message received: ${message.messageId}');
  }
}