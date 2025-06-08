import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/data/models/auth_screen/user_model.dart';

class AuthApiService {
  final http.Client client;

  AuthApiService({http.Client? client}) : client = client ?? http.Client();

  Future<UserModel> login(String phoneNumber) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': phoneNumber}),
      );
      print('Response: ${response.body}');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<UserModel> register(String name, String phoneNumber) async {
    try {
      final response = await client.post(
        Uri.parse(ApiConstants.baseUrl + ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'phone_number': phoneNumber,
        }),
      );
      print('Response: ${response.body}');
      print('Status Code: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
