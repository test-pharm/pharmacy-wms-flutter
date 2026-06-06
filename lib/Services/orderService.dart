import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Services/OfflineService.dart';
import 'package:pharmacy_wms/Services/ConnectivityService.dart';

class OrderService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Orders';
  static final List<OrderModel> _orders = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<void> init() async {
    if (!_loaded) await _fetchOrders();
  }

  static List<OrderModel> getAllOrders() {
    return List.unmodifiable(_orders);
  }

  static List<OrderModel> getPendingOrders() {
    return _orders
        .where((order) => order.status == OrderStatus.pending)
        .toList(growable: false);
  }

  static Future<void> addOrder(OrderModel order) async {
    if (!ConnectivityService().isOnline.value) {
      await OfflineService.queueOperation(
        method: 'POST',
        endpoint: '/Orders',
        body: order.toJson(),
      );
      final cached = await OfflineService.getCachedOrders();
      cached.insert(0, order);
      await OfflineService.cacheOrders(cached);

      _orders.insert(0, order);
      changes.value++;
      return;
    }
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: AuthService.authHeaders,
            body: jsonEncode(order.toJson()),
          )
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _orders.insert(0, order);
        changes.value++;
      }
    } catch (e) {
      debugPrint('[OrderService] Failed to add order: $e');
      _orders.insert(0, order);
      changes.value++;
    }
  }

  static Future<Map<String, dynamic>?> dispatchFefo(Map<String, dynamic> body) async {
    if (!ConnectivityService().isOnline.value) {
      await OfflineService.queueOperation(
        method: 'POST',
        endpoint: '/Orders/export',
        body: body,
      );

      final productId = body['productId']?.toString();
      final qty = body['quantity'] as int? ?? 0;
      if (productId != null && qty > 0) {
        final cached = await OfflineService.getCachedProducts();
        final idx = cached.indexWhere((m) => m.id == productId);
        if (idx != -1) {
          final updatedQty = (cached[idx].quantity - qty).clamp(0, double.infinity).toInt();
          cached[idx] = cached[idx].copyWith(quantity: updatedQty);
          await OfflineService.cacheProducts(cached);
        }
      }

      // Optimistically add an order to local list
      final localOrder = OrderModel(
        productName: body['productName']?.toString() ?? 'Material',
        productSku: body['productSku']?.toString() ?? '',
        quantity: qty,
        unit: body['unit']?.toString() ?? 'units',
        logNumber: 'OFFLINE-${DateTime.now().millisecondsSinceEpoch}',
        categoryId: body['categoryId'] is int ? body['categoryId'] as int : 0,
        type: OrderType.export,
        status: OrderStatus.completed,
        recipient: body['recipient']?.toString() ?? '',
        createdBy: AuthService.currentUser?.fullName ?? 'Storekeeper',
      );
      _orders.insert(0, localOrder);
      changes.value++;

      return {'success': true, 'message': 'Offline dispatch queued'};
    }
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/export'),
            headers: AuthService.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded is Map<String, dynamic> ? decoded : null;
      }
      final msg = decoded is Map ? (decoded['message'] ?? 'Dispatch failed ($response.statusCode)').toString() : 'Dispatch failed';
      throw Exception(msg);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateOrderStatus(String id, OrderStatus status) async {
    if (!ConnectivityService().isOnline.value) {
      throw Exception('Cannot update order status while offline');
    }
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/$id/status'),
          headers: AuthService.authHeaders,
          body: jsonEncode({'status': status.name}),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode == 200) {
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(status: status);
        changes.value++;
      }
    } else {
      throw Exception('Failed to update order status (${response.statusCode})');
    }
  }

  static Future<bool> checkInvoiceExists(String invoiceNumber) async {
    if (!ConnectivityService().isOnline.value) {
      return false; // Can't verify invoice existence while offline
    }
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/invoices/exists/$invoiceNumber'), headers: AuthService.authHeaders)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['exists'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearOrders() async {
    _orders.clear();
    _loaded = false;
    changes.value++;
  }

  static Future<void> _fetchOrders() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl), headers: AuthService.authHeaders)
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded is List ? decoded : [];
        _orders.clear();
        for (final item in items) {
          _orders.add(OrderModel.fromJson(item as Map<String, dynamic>));
        }
        await OfflineService.cacheOrders(_orders);
        _loaded = true;
      }
    } catch (e) {
      debugPrint('[OrderService] Failed to fetch orders: $e');
      final cached = await OfflineService.getCachedOrders();
      if (cached.isNotEmpty) {
        _orders.clear();
        _orders.addAll(cached);
        _loaded = true;
      }
    }
  }
}
