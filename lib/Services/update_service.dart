import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/app_version.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class UpdateService {
  static const String _fallbackUrl =
      'https://raw.githubusercontent.com/test-pharm/pharmacy-wms-flutter/main/version.json';

  static AppVersion? _cachedRemote;
  static Map<String, dynamic>? _bundledVersion;

  static Future<Map<String, dynamic>> get _versionJson async {
    if (_bundledVersion != null) return _bundledVersion!;
    final jsonStr = await rootBundle.loadString('assets/version.json');
    _bundledVersion = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _bundledVersion!;
  }

  static Future<String> get currentVersion async {
    final json = await _versionJson;
    return (json['latestVersion'] ?? '0.0.0').toString();
  }

  static Future<int> get currentBuildNumber async {
    final json = await _versionJson;
    return (json['latestBuildNumber'] ?? 0) as int;
  }

  static Future<AppVersion?> _fetchFrom(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return AppVersion.fromJson(decoded);
  }

  static Future<AppVersion?> fetchLatestVersion() async {
    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final remote = await _fetchFrom('$_fallbackUrl?t=$cacheBuster');
      if (remote != null) {
        _cachedRemote = remote;
        return remote;
      }
    } catch (e) {
      debugPrint('[UpdateService] GitHub check failed: $e');
    }

    try {
      final backendUrl = '${ApiConfig.baseUrl}/Update';
      final remote = await _fetchFrom(backendUrl);
      if (remote != null) {
        _cachedRemote = remote;
        return remote;
      }
    } catch (e) {
      debugPrint('[UpdateService] Backend fallback failed: $e');
    }

    return _cachedRemote;
  }

  static Future<bool> isUpdateAvailable() async {
    try {
      final remote = await fetchLatestVersion();
      if (remote == null) return false;

      final localVersion = await currentVersion;
      final localBuild = await currentBuildNumber;

      return remote.isNewerThan(localVersion, localBuild);
    } catch (_) {
      return false;
    }
  }
}
