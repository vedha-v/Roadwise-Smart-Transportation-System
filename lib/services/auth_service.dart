import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult.success() : success = true, message = null;

  const AuthResult.failure(this.message) : success = false;
}

class AuthService {
  static int? userId;
  static String? name;
  static String? email;

  static bool get isLoggedIn => userId != null;

  static void continueInDemoMode({
    required String userName,
    required String userEmail,
  }) {
    userId = 0;
    name = userName.trim().isEmpty ? 'RoadWise User' : userName.trim();
    email = userEmail.trim().isEmpty ? 'demo@roadwise.com' : userEmail.trim();
  }

  static Future<AuthResult> loginOrRegister({
    required String userName,
    required String userEmail,
    required String password,
  }) async {
    try {
      final loginResponse = await http
          .post(
            Uri.parse('$roadwiseApiBaseUrl/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': userEmail, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      if (loginResponse.statusCode == 200) {
        return _saveUser(loginResponse.body, userName, userEmail);
      }

      if (loginResponse.statusCode != 401) {
        return AuthResult.failure(_responseMessage(loginResponse));
      }

      final registerResponse = await http
          .post(
            Uri.parse('$roadwiseApiBaseUrl/auth/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': userName,
              'email': userEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (registerResponse.statusCode == 200 ||
          registerResponse.statusCode == 201) {
        return _saveUser(registerResponse.body, userName, userEmail);
      }

      return AuthResult.failure(_responseMessage(registerResponse));
    } catch (_) {
      return AuthResult.failure(
        'Could not connect to the backend at $roadwiseApiBaseUrl. '
        'Start the server or continue in demo mode.',
      );
    }
  }

  static AuthResult _saveUser(
    String responseBody,
    String fallbackName,
    String fallbackEmail,
  ) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final rawUserId = data['userId'];
    final parsedUserId = rawUserId is num
        ? rawUserId.toInt()
        : int.tryParse(rawUserId?.toString() ?? '');
    if (parsedUserId == null) {
      return const AuthResult.failure(
        'The backend returned an invalid login response.',
      );
    }

    userId = parsedUserId;
    name = data['name']?.toString() ?? fallbackName;
    email = data['email']?.toString() ?? fallbackEmail;
    return const AuthResult.success();
  }

  static String _responseMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is List) return message.join('\n');
        if (message != null) return message.toString();
      }
    } on FormatException {
      // Fall through to the status-based message.
    }
    return 'The backend returned status ${response.statusCode}.';
  }

  static void logout() {
    userId = null;
    name = null;
    email = null;
  }
}
