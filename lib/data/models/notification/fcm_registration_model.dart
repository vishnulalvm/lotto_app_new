class FcmRegistrationResponse {
  final String status;
  final String message;
  final int userId;
  final String username;
  final String name;
  final String phoneNumber;
  final bool notificationsEnabled;

  FcmRegistrationResponse({
    required this.status,
    required this.message,
    required this.userId,
    required this.username,
    required this.name,
    required this.phoneNumber,
    required this.notificationsEnabled,
  });

  factory FcmRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return FcmRegistrationResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      userId: json['user_id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'user_id': userId,
      'username': username,
      'name': name,
      'phone_number': phoneNumber,
      'notifications_enabled': notificationsEnabled,
    };
  }
}