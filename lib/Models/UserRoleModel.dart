import 'dart:convert';


import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmacy_wms/Services/api_config.dart';


enum UserRole { warehouseManager, supervisor }



class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String token;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = _extractRoleText(json);
    return UserModel(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? json['userName'] ?? '')
          .toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      role: _roleFromString(rawRole),
      token: (json['token'] ?? json['accessToken'] ?? '').toString(),
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role == UserRole.warehouseManager ? 'Admin' : 'User',
      'token': token,
    };
  }


  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      token: token ?? this.token,
    );
  }



  static String _extractRoleText(Map<String, dynamic> json) {
    final roleCandidate =
        json['role'] ??
        json['userRole'] ??
        json['roles'] ??
        json['user']?['role'] ??
        json['user']?['roles'];

    if (roleCandidate is List && roleCandidate.isNotEmpty) {
      return roleCandidate.first.toString();
    }

    return (roleCandidate ?? '').toString();
  }
}



class AuthResponseModel {
  final String token;
  final String? refreshToken;
  final UserModel user;

  const AuthResponseModel({
    required this.token,
    required this.user,
    this.refreshToken,
  });

  factory AuthResponseModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackEmail = '',
  }) {
    final token = _extractToken(json);
    final userMap = _extractUserMap(json);
    final user = UserModel.fromJson({
      ...userMap,
      'email': userMap['email'] ?? fallbackEmail,
      'token': token,
      'role':
          userMap['role'] ??
          userMap['userRole'] ??
          _extractRoleFromToken(token) ??
          'User',
    });

    return AuthResponseModel(
      token: token,
      refreshToken: (json['refreshToken'] ?? '').toString(),
      user: user,
    );
  }



  static String _extractToken(Map<String, dynamic> json) {
    final nestedData = json['data'];
    final nestedUser = json['user'];
    return (json['token'] ??
            json['accessToken'] ??
            (nestedData is Map<String, dynamic>
                ? nestedData['token'] ?? nestedData['accessToken']
                : null) ??
            (nestedUser is Map<String, dynamic>
                ? nestedUser['token'] ?? nestedUser['accessToken']
                : null) ??
            '')
        .toString();
  }




  static Map<String, dynamic> _extractUserMap(Map<String, dynamic> json) {
    final user = json['user'];
    final data = json['data'];

    if (user is Map<String, dynamic>) {
      return user;
    }

    if (data is Map<String, dynamic>) {
      final nestedUser = data['user'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }
      return data;
    }

    return json;
  }
}



class AuthService {
  static String get _baseUrl => ApiConfig.baseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  static UserModel? _currentUser;
  static final ValueNotifier<int> sessionChanges = ValueNotifier<int>(0);

  static UserModel? get currentUser => _currentUser;
  static bool get isAuthenticated => token.isNotEmpty;
  static bool get isWarehouseManager =>
      _currentUser?.role == UserRole.warehouseManager;
  static bool get isSupervisor => _currentUser?.role == UserRole.supervisor;
  static String get token => _currentUser?.token ?? '';

  static Map<String, String> get authHeaders {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }




  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString(_userKey);
    final storedToken = prefs.getString(_tokenKey);

    if (storedUser == null || storedToken == null || storedToken.isEmpty) {
      _currentUser = null;
      return;
    }

    try {
      final decoded = jsonDecode(storedUser);
      if (decoded is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson({...decoded, 'token': storedToken});
      }
    } catch (_) {
      _currentUser = null;
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }




  static Future<String?> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/Auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 60));

      final decoded = _decodeBody(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded is! Map<String, dynamic>) {
          return 'Unexpected login response from the server.';
        }



        final auth = AuthResponseModel.fromJson(
          decoded,
          fallbackEmail: email.trim(),
        );

        if (auth.token.isEmpty) {
          return 'Login succeeded but no access token was returned.';
        }


        await _saveSession(auth.user.copyWith(token: auth.token));
        return null;
      }


      return _extractErrorMessage(response.statusCode, decoded);
    } catch (e) {
      return 'Unable to sign in right now. Please check your connection and try again.';
    }
  }




  static Future<String?> registerAdmin({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) {
    return _register(
      path: '/Auth/register/admin',
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }




  static Future<String?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) {
    return _register(
      path: '/Auth/register/user',
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }




  static Future<String?> _register({
    required String path,
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'fullName': fullName.trim(),
              'phoneNumber': phoneNumber.trim(),
            }),
          )
          .timeout(const Duration(seconds: 60));

      final decoded = _decodeBody(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }


      return _extractErrorMessage(response.statusCode, decoded);
    } catch (_) {
      return 'Unable to complete registration right now. Please try again.';
    }
  }




  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    sessionChanges.value++;
  }




  static Future<void> updateCurrentUser(UserModel updated) async {
    final tokenValue = updated.token.isNotEmpty ? updated.token : token;
    await _saveSession(updated.copyWith(token: tokenValue));
  }




  static Future<void> expireSession() async {
    await logout();
  }




  static Future<void> _saveSession(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    sessionChanges.value++;
  }



  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }



  static String _extractErrorMessage(int statusCode, dynamic body) {
    final fallback = switch (statusCode) {
      400 => 'Please review the entered data and try again.',
      401 => 'Invalid credentials or unauthorized request.',
      404 => 'The requested authentication endpoint was not found.',
      500 => 'The server encountered an error. Please try again later.',
      _ => 'Request failed ($statusCode).',
    };

    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList();
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      return (body['message'] ?? body['error'] ?? body['title'] ?? fallback)
          .toString();
    }

    if (body is String && body.trim().isNotEmpty) {
      return body;
    }

    return fallback;
  }
}


UserRole _roleFromString(String rawRole) {
  final normalized = rawRole.toLowerCase();
  if (normalized.contains('admin') || normalized.contains('manager')) {
    return UserRole.warehouseManager;
  }
  return UserRole.supervisor;
}


String? _extractRoleFromToken(String token) {
  if (token.isEmpty || !token.contains('.')) {
    return null;
  }

  try {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }



    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }



    final role =
        decoded['role'] ??
        decoded['roles'] ??
        decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

    if (role is List && role.isNotEmpty) {
      return role.first.toString();
    }

    return role?.toString();
  } catch (_) {
    return null;
  }
}
