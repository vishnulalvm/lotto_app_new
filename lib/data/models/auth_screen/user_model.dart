// lib/data/models/user_model.dart
class UserModel {
  final String phoneNumber;
  final String? name;
  final String? message;

  UserModel({
    required this.phoneNumber,
    this.name,
    this.message,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phoneNumber: json['phone_number'],
      name: json['name'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      if (name != null) 'name': name,
    };
  }
}