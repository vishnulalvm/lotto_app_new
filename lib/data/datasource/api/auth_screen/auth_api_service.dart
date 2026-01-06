import 'package:dio/dio.dart';
import 'package:lotto_app/core/constants/api_constants/api_constants.dart';
import 'package:lotto_app/core/network/dio_client.dart';
import 'package:lotto_app/data/models/auth_screen/user_model.dart';

class AuthApiService {
  final Dio _dio;

  AuthApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  Future<UserModel> login(String phoneNumber) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'phone_number': phoneNumber},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to login: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<UserModel> register(String name, String phoneNumber) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Failed to register: ${response.data}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }
}
