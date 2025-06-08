import 'package:lotto_app/data/datasource/api/auth_screen/auth_api_service.dart';
import 'package:lotto_app/data/models/auth_screen/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final AuthApiService apiService;

  AuthRepository({required this.apiService});

  Future<UserModel> login(String phoneNumber) async {
    final user = await apiService.login(phoneNumber);
    await _saveUserData(user);
    await _setLoggedIn(true); // Set login status to true
    return user;
  }

  Future<UserModel> register(String name, String phoneNumber) async {
    final user = await apiService.register(name, phoneNumber);
    await _saveUserData(user);
    await _setLoggedIn(true); // Set login status to true
    return user;
  }

  Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', user.phoneNumber);
    if (user.name != null) {
      await prefs.setString('user_name', user.name!);
    }
  }

  // Add this method to set the login status
  Future<void> _setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
  }

  // Optionally add a logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    // You can decide whether to clear other user data or keep it
    await prefs.remove('phone_number');
    await prefs.remove('user_name');
  }
}
