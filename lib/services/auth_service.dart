import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _backendBaseUrl =
      'http://10.0.2.2:3000/api';

  static int? userId;
  static String? name;
  static String? email;

  static bool get isLoggedIn => userId != null;

  static Future<bool> loginOrRegister({
    required String userName,
    required String userEmail,
    required String password,
  }) async {
    try {
      // Try login first.
      final loginResponse = await http.post(
        Uri.parse('$_backendBaseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': userEmail,
          'password': password,
        }),
      );

      if (loginResponse.statusCode == 200) {
        final data = jsonDecode(loginResponse.body);

        if (data['userId'] != null) {
          userId = data['userId'];
          name = data['name']?.toString() ?? userName;
          email = data['email']?.toString() ?? userEmail;

          return true;
        }
      }

      // If login fails, register the user.
      final registerResponse = await http.post(
        Uri.parse('$_backendBaseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': userName,
          'email': userEmail,
          'password': password,
        }),
      );

      if (registerResponse.statusCode == 200 ||
          registerResponse.statusCode == 201) {
        final data = jsonDecode(registerResponse.body);

        if (data['userId'] != null) {
          userId = data['userId'];
          name = data['name']?.toString() ?? userName;
          email = data['email']?.toString() ?? userEmail;

          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static void logout() {
    userId = null;
    name = null;
    email = null;
  }
}