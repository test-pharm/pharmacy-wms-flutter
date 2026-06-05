import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class UserService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Users';

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await http
        .get(Uri.parse(_baseUrl), headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) {
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(
          decoded.map((item) => Map<String, dynamic>.from(item)),
        );
      }
      return const [];
    }

    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> changeRole(String id, String role) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/$id/role'),
          headers: AuthService.authHeaders,
          body: jsonEncode({'role': role}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) return;
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<bool> toggleStatus(String id) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/$id/status'),
          headers: AuthService.authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('isActive')) {
        return decoded['isActive'] as bool;
      }
      return true;
    }
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> deleteUser(String id) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/$id'),
          headers: AuthService.authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) return;
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> resetPassword(String id, String newPassword) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$id/reset-password'),
          headers: AuthService.authHeaders,
          body: jsonEncode({'newPassword': newPassword}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) return;
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String _extractError(int statusCode, dynamic body) {
    if (body is Map<String, dynamic> && body.containsKey('message')) {
      return body['message'].toString();
    }
    return 'Request failed ($statusCode).';
  }
}
