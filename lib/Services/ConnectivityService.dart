import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:pharmacy_wms/Services/OfflineService.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;

  void init() {
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _checkStatus();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkStatus();
    });
    _checkStatus();
  }

  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
  }

  Future<void> _checkStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        if (isOnline.value) {
          isOnline.value = false;
        }
        return;
      }
      
      final response = await http
          .get(Uri.parse(ApiConfig.baseUrl))
          .timeout(const Duration(seconds: 5));
      
      final online = response.statusCode != 0;
      if (isOnline.value != online) {
        isOnline.value = online;
        if (online) {
          OfflineService.syncPendingOperations();
        }
      }
    } catch (_) {
      if (isOnline.value) {
        isOnline.value = false;
      }
    }
  }
}
