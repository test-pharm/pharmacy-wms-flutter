import 'package:pharmacy_wms/Models/alertModel.dart';

import 'package:pharmacy_wms/Models/materialModel.dart';

import 'package:pharmacy_wms/Services/thresholdService.dart';


class AlertService {
  static final List<AlertModel> _alerts = [];

  static int _lowStockThreshold = 100;
  static int _expiringSoonDays = 30;

  static Future<void> reloadThresholds() async {
    _lowStockThreshold = await ThresholdService.getLowStockThreshold();
    _expiringSoonDays = await ThresholdService.getExpiringSoonDays();
  }

  static void initializeAlertsFromModels(List<MaterialModel> materials) {
    _alerts.clear();
    for (final material in materials) {
      _checkAndCreateAlerts(material);
    }
  }

  static void _checkAndCreateAlerts(MaterialModel material) {
    if (_isExpired(material.expiryDate)) {
      _alerts.add(AlertModel(
        id: 'alert_expired_${material.id}',
        alertType: 'expired',
        message:
            '${material.name} has expired on ${material.expiryDate}. Remove from inventory immediately.',
        material: material,
        createdAt: DateTime.now(),
      ));
    }
 else if (_isExpiringSoon(material.expiryDate)) {
      final daysLeft = _daysUntilExpiry(material.expiryDate);
      _alerts.add(AlertModel(
        id: 'alert_expiring_${material.id}',
        alertType: 'expiring_soon',
        message:
            '${material.name} will expire in $daysLeft days on ${material.expiryDate}.',
        material: material,
        createdAt: DateTime.now(),
      ));
    }

    final threshold = material.minStockLevel > 0 ? material.minStockLevel : _lowStockThreshold;
    if (material.quantity < threshold) {
      _alerts.add(AlertModel(
        id: 'alert_lowstock_${material.id}',
        alertType: 'low_stock',
        message:
            '${material.name} is running low. Current stock: ${material.quantity} units.',
        material: material,
        createdAt: DateTime.now(),
      ));
    }
  }

  static bool _isExpired(String expiryDate) {
    try {
      return DateTime.parse(expiryDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  static bool _isExpiringSoon(String expiryDate) {
    try {
      final diff = DateTime.parse(expiryDate).difference(DateTime.now()).inDays;
      return diff > 0 && diff <= _expiringSoonDays;
    } catch (_) {
      return false;
    }
  }

  static int _daysUntilExpiry(String expiryDate) {
    try {
      return DateTime.parse(expiryDate).difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  static List<AlertModel> getAllAlerts() => List.unmodifiable(_alerts);
  static List<AlertModel> getAlertsByType(String type) =>
      _alerts.where((a) => a.alertType == type).toList();
  static List<AlertModel> getCriticalAlerts() => _alerts
      .where((a) => a.alertType == 'expired' || a.alertType == 'expiring_soon')
      .toList();

  static int getExpiredMaterialsCount() =>
      _alerts.where((a) => a.alertType == 'expired').length;
  static int getExpiringSoonCount() =>
      _alerts.where((a) => a.alertType == 'expiring_soon').length;
  static int getLowStockCount() =>
      _alerts.where((a) => a.alertType == 'low_stock').length;

  static void addAlert(AlertModel alert) => _alerts.add(alert);
  static void removeAlert(String id) =>
      _alerts.removeWhere((a) => a.id == id);
  static void clearAllAlerts() => _alerts.clear();
  static void refreshAlerts() => initializeAlertsFromModels([]);
}
