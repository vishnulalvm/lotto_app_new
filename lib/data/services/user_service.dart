// lib/data/services/user_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserService {
  static const String _userIdKey = 'user_id';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userNameKey = 'user_name';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _appInstallationIdKey = 'app_installation_id';
  static const String _appVersionKey = 'app_version';

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
    
    // First check if this is a fresh installation
    if (await _isFreshInstallation()) {
      // Clear any existing login data from previous installation
      await clearUserData();
      return false;
    }
    
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Check if this is a fresh app installation
  Future<bool> _isFreshInstallation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      
      final storedInstallationId = prefs.getString(_appInstallationIdKey);
      final storedAppVersion = prefs.getString(_appVersionKey);
      final currentVersion = packageInfo.version;
      
      // Generate a unique installation ID based on current timestamp if not exists
      if (storedInstallationId == null) {
        final newInstallationId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString(_appInstallationIdKey, newInstallationId);
        await prefs.setString(_appVersionKey, currentVersion);
        return true; // This is definitely a fresh installation
      }
      
      // Update version if it has changed
      if (storedAppVersion != currentVersion) {
        await prefs.setString(_appVersionKey, currentVersion);
      }
      
      return false; // Not a fresh installation
    } catch (e) {
      // If there's any error, treat as fresh installation for safety
      return true;
    }
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
    // Don't remove installation ID and app version as they're used to detect fresh installations
  }

  // Force clear all data including installation markers (use with caution)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_appInstallationIdKey);
    await prefs.remove(_appVersionKey);
  }
}