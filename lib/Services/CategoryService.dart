import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class CategoryService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Categories';

  static Future<List<Map<String, dynamic>>> getCategories() async {
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

  static Future<Map<String, dynamic>> createCategory(String name) async {
    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: AuthService.authHeaders,
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<Map<String, dynamic>> updateCategory(int id, String name) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/$id'),
          headers: AuthService.authHeaders,
          body: jsonEncode({'name': name}),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> deleteCategory(int id) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/$id'),
          headers: AuthService.authHeaders,
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 204) return;

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
