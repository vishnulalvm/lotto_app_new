import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/notification/fcm_registration_model.dart';
import 'dart:developer' as developer;

class FcmApiService {
  final http.Client client;

  FcmApiService({http.Client? client}) : client = client ?? http.Client();

  Future<FcmRegistrationResponse> registerFcmToken({
    required String fcmToken,
    required String phoneNumber,
    required String name,
    required bool notificationsEnabled,
  }) async {
    final url = ApiConstants.baseUrl + ApiConstants.fcmRegister;

    developer.log('Registering FCM token',
        name: 'FcmApiService',
        error: null,
        level: 800);
    developer.log('API URL: $url', name: 'FcmApiService');
    developer.log('Phone: $phoneNumber, Name: $name, Enabled: $notificationsEnabled',
        name: 'FcmApiService');

    try {
      final requestBody = {
        'fcm_token': fcmToken,
        'phone_number': phoneNumber,
        'name': name,
        'notifications_enabled': notificationsEnabled,
      };

      developer.log('Request body: ${json.encode(requestBody)}',
          name: 'FcmApiService');

      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      developer.log('Response status: ${response.statusCode}',
          name: 'FcmApiService');
      developer.log('Response body: ${response.body}',
          name: 'FcmApiService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = FcmRegistrationResponse.fromJson(
          json.decode(response.body)
        );
        developer.log('FCM token registered successfully',
            name: 'FcmApiService');
        return responseData;
      } else {
        developer.log('Failed to register FCM token: Status ${response.statusCode}',
            name: 'FcmApiService',
            error: response.body);
        throw Exception('Failed to register FCM token: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      developer.log('Network error during FCM registration',
          name: 'FcmApiService',
          error: e);
      throw Exception('Network error: $e');
    } catch (e) {
      developer.log('Unexpected error during FCM registration',
          name: 'FcmApiService',
          error: e);
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
