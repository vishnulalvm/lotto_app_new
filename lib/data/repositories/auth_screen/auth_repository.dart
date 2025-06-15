import 'package:lotto_app/data/datasource/api/auth_screen/auth_api_service.dart';
import 'package:lotto_app/data/models/auth_screen/user_model.dart';
import 'package:lotto_app/data/services/user_service.dart';

class AuthRepository {
  final AuthApiService apiService;
  final UserService userService;

  AuthRepository({
    required this.apiService,
    required this.userService,
  });

  Future<UserModel> login(String phoneNumber) async {
    final user = await apiService.login(phoneNumber);
    await userService.saveUserData(
      phoneNumber: user.phoneNumber,
      name: user.name,
    );
    return user;
  }

  Future<UserModel> register(String name, String phoneNumber) async {
    final user = await apiService.register(name, phoneNumber);
    await userService.saveUserData(
      phoneNumber: user.phoneNumber,
      name: user.name,
    );
    return user;
  }

  // Logout method using UserService
  Future<void> logout() async {
    await userService.clearUserData();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await userService.isLoggedIn();
  }

  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    final phoneNumber = await userService.getPhoneNumber();
    final name = await userService.getUserName();

    if (phoneNumber != null) {
      return UserModel(
        phoneNumber: phoneNumber,
        name: name,
      );
    }
    return null;
  }
}
