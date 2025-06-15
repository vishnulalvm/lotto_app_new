// lib/data/services/user_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userIdKey = 'user_id';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'isLoggedIn';

  // Set user ID (phone number)
  Future<void> setUserId(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, phoneNumber);
    await prefs.setString(_phoneNumberKey, phoneNumber);
  }

  // Get user ID (phone number)
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get phone number
  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  // Get user name
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Clear user ID
  Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_phoneNumberKey);
  }

  // Set login status
  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Save complete user data
  Future<void> saveUserData({
    required String phoneNumber,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await setUserId(phoneNumber);
    if (name != null) {
      await prefs.setString(_userNameKey, name);
    }
    await setLoggedIn(true);
  }

  // Clear all user data (logout)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_userNameKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}