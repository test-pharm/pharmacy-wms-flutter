import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class Contact {
  final int id;
  final String name;
  final String type; // Supplier or Recipient
  final String? phone;
  final String? notes;

  Contact({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.notes,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as int,
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'Supplier').toString(),
      phone: json['phone']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'notes': notes,
    };
  }
}

class ContactService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Contacts';

  static Future<List<Contact>> getContacts({String? type}) async {
    var url = _baseUrl;
    if (type != null && type.isNotEmpty) {
      url += '?type=$type';
    }

    final response = await http
        .get(Uri.parse(url), headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) {
      if (decoded is List) {
        return decoded
            .map((item) => Contact.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return const [];
    }

    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<Contact> createContact({
    required String name,
    required String type,
    String? phone,
    String? notes,
  }) async {
    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: AuthService.authHeaders,
          body: jsonEncode({
            'name': name,
            'type': type,
            'phone': phone,
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Contact.fromJson(Map<String, dynamic>.from(decoded));
    }

    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<Contact> updateContact(
    int id, {
    required String name,
    required String type,
    String? phone,
    String? notes,
  }) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/$id'),
          headers: AuthService.authHeaders,
          body: jsonEncode({
            'name': name,
            'type': type,
            'phone': phone,
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return Contact.fromJson(Map<String, dynamic>.from(decoded));
    }

    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> deleteContact(int id) async {
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
