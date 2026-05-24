class UserModel {
  final String uid;
  final String username;
  final String nickname;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final String role;
  final String? defaultAddress; // kept for legacy; not used in API responses

  const UserModel({
    required this.uid,
    required this.username,
    required this.nickname,
    this.email,
    this.phoneNumber,
    this.avatar,
    required this.role,
    this.defaultAddress,
  });

  bool get isAdmin => role == 'admin';

  // Onboarding required until phone is set
  bool get needsOnboarding =>
      phoneNumber == null || phoneNumber!.trim().isEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['memberId']?.toString() ??
            json['userId']?.toString() ??
            json['uid']?.toString() ?? '',
        username: json['email'] as String? ??
            json['userName'] as String? ??
            json['username'] as String? ?? '',
        nickname: json['nickName'] as String? ??
            json['nickname'] as String? ?? '',
        email: json['email'] as String?,
        phoneNumber: json['phone'] as String? ??
            json['phonenumber'] as String? ??
            json['phoneNumber'] as String?,
        avatar: json['avatarUrl'] as String? ?? json['avatar'] as String?,
        role: json['role'] as String? ?? 'customer',
        defaultAddress: json['defaultAddress'] as String?,
      );

  UserModel copyWith({
    String? nickname,
    String? email,
    String? phoneNumber,
    String? defaultAddress,
    String? avatar,
  }) =>
      UserModel(
        uid: uid,
        username: username,
        nickname: nickname ?? this.nickname,
        email: email ?? this.email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        avatar: avatar ?? this.avatar,
        role: role,
        defaultAddress: defaultAddress ?? this.defaultAddress,
      );
}
