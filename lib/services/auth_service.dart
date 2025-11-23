import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_response.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/auth';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Store token securely
  static Future<void> storeToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Get stored token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Remove token (logout)
  static Future<void> removeToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Registration
  static Future<AuthResponse> register({
    required String mobileNumber,
    required String fullName,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mobileNumber': mobileNumber,
          'fullName': fullName,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        await storeToken(data['token']);
        return AuthResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login
  static Future<AuthResponse> login({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobileNumber': mobileNumber, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storeToken(data['token']);
        return AuthResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Forgot Password
  static Future<void> forgotPassword(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobileNumber': mobileNumber}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Failed to initiate password reset',
        );
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Validate Reset Token
  static Future<bool> validateResetToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate-reset-token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Reset Password
  static Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'newPassword': newPassword}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Logout
  static Future<void> logout() async {
    await removeToken();
  }
}
