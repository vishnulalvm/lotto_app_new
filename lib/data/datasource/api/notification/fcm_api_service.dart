import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/notification/fcm_registration_model.dart';

class FcmApiService {
  final http.Client client;

  FcmApiService({http.Client? client}) : client = client ?? http.Client();

  Future<FcmRegistrationResponse> registerFcmToken({
    required String fcmToken,
    required String phoneNumber,
    required String name,
    required bool notificationsEnabled,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.backUpUrl + ApiConstants.fcmRegister),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fcm_token': fcmToken,
          'phone_number': phoneNumber,
          'name': name,
          'notifications_enabled': notificationsEnabled,
        }),
      );
      print("FCM token registration request sent to server.:fcmToken: $fcmToken, phoneNumber: $phoneNumber, name: $name, notificationsEnabled: $notificationsEnabled");
print('FCM Registration Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FcmRegistrationResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to register FCM token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<FcmRegistrationResponse> updateNotificationSettings({
    required String fcmToken,
    required String phoneNumber,
    required String name,
    required bool notificationsEnabled,
  }) async {
    // Same endpoint, but this will update existing user's notification settings
    return registerFcmToken(
      fcmToken: fcmToken,
      phoneNumber: phoneNumber,
      name: name,
      notificationsEnabled: notificationsEnabled,
    );
  }
}