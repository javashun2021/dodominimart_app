import 'user_model.dart';

class LoginResponse {
  final String token;
  final UserModel? user;

  const LoginResponse({required this.token, this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // API: {code:200, msg:"...", data:{token:"...", member:{...}}}
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return LoginResponse(
      token: data['token'] as String? ?? '',
      user: data['member'] != null
          ? UserModel.fromJson(data['member'] as Map<String, dynamic>)
          : null,
    );
  }
}
