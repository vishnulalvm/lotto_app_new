import 'package:lotto_app/data/datasource/api/notification/fcm_api_service.dart';
import 'package:lotto_app/data/models/notification/fcm_registration_model.dart';
import 'package:lotto_app/data/services/firebase_messaging_service.dart';

abstract class NotificationRepository {
  Future<bool> enableNotifications();
  Future<bool> disableNotifications();
  Future<bool> isNotificationEnabled();
  Future<FcmRegistrationResponse?> registerFcmToken({
    required String fcmToken,
    required String phoneNumber,
    required String name,
    required bool notificationsEnabled,
  });
}

class NotificationRepositoryImpl implements NotificationRepository {
  final FcmApiService _fcmApiService;

  NotificationRepositoryImpl({FcmApiService? fcmApiService})
      : _fcmApiService = fcmApiService ?? FcmApiService();

  @override
  Future<bool> enableNotifications() async {
    try {
      return await FirebaseMessagingService.updateNotificationSettings(true);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> disableNotifications() async {
    try {
      return await FirebaseMessagingService.updateNotificationSettings(false);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isNotificationEnabled() async {
    try {
      // This should check with the backend, but for now we'll use local storage
      return await FirebaseMessagingService.registerToken();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<FcmRegistrationResponse?> registerFcmToken({
    required String fcmToken,
    required String phoneNumber,
    required String name,
    required bool notificationsEnabled,
  }) async {
    try {
      return await _fcmApiService.registerFcmToken(
        fcmToken: fcmToken,
        phoneNumber: phoneNumber,
        name: name,
        notificationsEnabled: notificationsEnabled,
      );
    } catch (e) {
      return null;
    }
  }
}