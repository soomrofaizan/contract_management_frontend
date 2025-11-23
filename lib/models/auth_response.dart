class AuthResponse {
  final String message;
  final String token;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message'],
      token: json['token'],
      user: json['user'],
    );
  }
}
