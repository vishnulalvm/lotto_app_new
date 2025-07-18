import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lotto_app/data/datasource/api/notification/fcm_api_service.dart';
import 'package:lotto_app/data/services/user_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FcmApiService _fcmApiService = FcmApiService();
  
  static String? _currentToken;
  
  /// Initialize Firebase messaging
  static Future<void> initialize() async {
    print("🔥 Starting Firebase Messaging initialization...");
    
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
      print("📱 App opened from terminated state by notification: ${initialMessage.messageId}");
      _handleNotificationTap(initialMessage);
    }
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
    
    print("✅ Firebase Messaging initialization complete!");
  }
  
  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    print("🔔 Requesting notification permissions...");
    
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('🔔 Notification permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permissions');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permissions');
    } else {
      print('❌ User declined or has not accepted notification permissions');
    }
  }
  
  /// Get FCM token
  static Future<String?> _getToken() async {
    try {
      print("🔑 Getting FCM token...");
      _currentToken = await _firebaseMessaging.getToken();
      
      if (_currentToken != null) {
        print('✅ FCM Token received: ${_currentToken!.substring(0, 20)}...');
        print('📋 Full FCM Token: $_currentToken');
        print('🧪 Test this token at: https://console.firebase.google.com/project/lotto-app-f3440/messaging');
      } else {
        print('❌ Failed to get FCM token');
      }
      
      return _currentToken;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
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
        print('❌ No FCM token available for registration');
        return false;
      }
      
      final userService = UserService();
      final phoneNumber = await userService.getPhoneNumber();
      final name = await userService.getUserName();
      
      if (phoneNumber == null) {
        print('❌ No user logged in for token registration');
        return false;
      }
      
      print('📤 Registering FCM token with backend...');
      print('📱 Token: ${token.substring(0, 20)}...');
      print('📞 Phone: $phoneNumber');
      print('👤 Name: $name');
      print('🔔 Notifications enabled: $notificationsEnabled');
      
      await _fcmApiService.registerFcmToken(
        fcmToken: token,
        phoneNumber: phoneNumber,
        name: name ?? 'User',
        notificationsEnabled: notificationsEnabled,
      );
      
      // Save notification preference locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', notificationsEnabled);
      
      print('✅ FCM token registered successfully with backend');
      return true;
    } catch (e) {
      print('❌ Error registering FCM token: $e');
      return false;
    }
  }
  
  /// Update notification settings
  static Future<bool> updateNotificationSettings(bool enabled) async {
    try {
      final token = _currentToken ?? await _getToken();
      if (token == null) {
        print('❌ No FCM token available for settings update');
        return false;
      }
      
      final userService = UserService();
      final phoneNumber = await userService.getPhoneNumber();
      final name = await userService.getUserName();
      
      if (phoneNumber == null) {
        print('❌ No user logged in for settings update');
        return false;
      }
      
      print('⚙️ Updating notification settings: $enabled');
      
      await _fcmApiService.updateNotificationSettings(
        fcmToken: token,
        phoneNumber: phoneNumber,
        name: name ?? 'User',
        notificationsEnabled: enabled,
      );
      
      // Save notification preference locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      
      print('✅ Notification settings updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating notification settings: $e');
      return false;
    }
  }
  
  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 === FOREGROUND MESSAGE RECEIVED ===');
    print('🆔 Message ID: ${message.messageId}');
    print('📤 From: ${message.from}');
    print('⏰ Sent time: ${message.sentTime}');
    print('📊 Data: ${message.data}');
    
    if (message.notification != null) {
      print('🔔 Notification:');
      print('   📰 Title: ${message.notification?.title}');
      print('   📝 Body: ${message.notification?.body}');
      print('   🖼️ Image: ${message.notification?.apple?.imageUrl ?? message.notification?.android?.imageUrl ?? 'none'}');
    } else {
      print('🔔 No notification payload (data-only message)');
    }
    
    // Handle notification type
    final notificationType = message.data['type'];
    print('🏷️ Notification type: $notificationType');
    
    // You can show a local notification here or handle it as needed
    // For now, we'll just log it
  }
  
  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 === NOTIFICATION TAPPED ===');
    print('🆔 Message ID: ${message.messageId}');
    print('📊 Data: ${message.data}');
    
    // Handle navigation based on notification data
    final notificationType = message.data['type'];
    
    switch (notificationType) {
      case 'live_result_starts':
        print('🎯 Navigating to live results...');
        // Navigate to live results or home screen
        break;
      case 'result_published':
        print('🎉 Navigating to result details...');
        // Navigate to specific result details
        break;
      case 'test':
        print('🧪 Test notification tapped');
        // Handle test notification
        break;
      default:
        print('🏠 Navigating to home screen...');
        // Navigate to home screen
        break;
    }
  }
  
  /// Handle token refresh
  static void _onTokenRefresh(String token) {
    print('🔄 === FCM TOKEN REFRESHED ===');
    print('🆕 New token: ${token.substring(0, 20)}...');
    print('📋 Full new token: $token');
    
    _currentToken = token;
    
    // Re-register with the new token
    print('📤 Re-registering new token with backend...');
    registerToken();
  }
}

// Background message handler should be in main.dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔄 === BACKGROUND MESSAGE RECEIVED ===');
  print('🆔 Message ID: ${message.messageId}');
  print('📊 Data: ${message.data}');
  
  if (message.notification != null) {
    print('🔔 Background notification:');
    print('   📰 Title: ${message.notification?.title}');
    print('   📝 Body: ${message.notification?.body}');
  }
  
  // Handle the background message
  // This function must be a top-level function
}