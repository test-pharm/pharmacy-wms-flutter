import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static late Box _productsBox;
  static late Box _ordersBox;
  static late Box _pendingBox;
  static bool _initialized = false;
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> syncCompletedEvents = ValueNotifier<int>(0);

  static Future<void> init() async {
    if (_initialized) return;
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    _productsBox = await Hive.openBox('productsBox');
    _ordersBox = await Hive.openBox('ordersBox');
    _pendingBox = await Hive.openBox('pendingBox');
    pendingCount.value = _pendingBox.length;
    _initialized = true;
  }

  static Future<void> cacheProducts(List<MaterialModel> products) async {
    await init();
    final list = products.map((p) => p.toJson()).toList();
    await _productsBox.put('list', list);
  }

  static Future<List<MaterialModel>> getCachedProducts() async {
    await init();
    final raw = _productsBox.get('list');
    if (raw is List) {
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MaterialModel.fromJson(map);
      }).toList();
    }
    return [];
  }

  static Future<void> cacheOrders(List<OrderModel> orders) async {
    await init();
    final list = orders.map((o) => o.toJson()).toList();
    await _ordersBox.put('list', list);
  }

  static Future<List<OrderModel>> getCachedOrders() async {
    await init();
    final raw = _ordersBox.get('list');
    if (raw is List) {
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return OrderModel.fromJson(map);
      }).toList();
    }
    return [];
  }

  static Future<void> queueOperation({
    required String method,
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    await init();
    final opId = 'OP-${DateTime.now().millisecondsSinceEpoch}';
    final opData = {
      'id': opId,
      'method': method,
      'endpoint': endpoint,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _pendingBox.put(opId, opData);
    pendingCount.value = _pendingBox.length;
  }

  static Future<void> syncPendingOperations() async {
    await init();
    if (_pendingBox.isEmpty) return;

    final keys = List.from(_pendingBox.keys);
    keys.sort((a, b) {
      final aMap = _pendingBox.get(a) as Map;
      final bMap = _pendingBox.get(b) as Map;
      return (aMap['timestamp'] as String).compareTo(bMap['timestamp'] as String);
    });

    bool syncedAny = false;
    for (final key in keys) {
      final op = Map<String, dynamic>.from(_pendingBox.get(key) as Map);
      final success = await _replayOperation(op);
      if (success) {
        await _pendingBox.delete(key);
        syncedAny = true;
      }
    }
    pendingCount.value = _pendingBox.length;

    if (syncedAny) {
      syncCompletedEvents.value++;
    }
  }

  static Future<bool> _replayOperation(Map<String, dynamic> op) async {
    final method = op['method'] as String;
    final endpoint = op['endpoint'] as String;
    final body = op['body'] as Map<String, dynamic>;
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      http.Response response;
      final headers = AuthService.authHeaders;

      if (method == 'POST') {
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') {
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'PATCH') {
        response = await http.patch(uri, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else {
        return false;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint('[OfflineService] Replay failed with status: ${response.statusCode}');
      if (response.statusCode >= 400 && response.statusCode < 500) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[OfflineService] Replay error: $e');
      return false;
    }
  }
}
