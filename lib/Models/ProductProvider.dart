import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:pharmacy_wms/Models/app_localizations.dart';

import 'package:pharmacy_wms/Models/materialModel.dart';

import 'package:pharmacy_wms/Services/MaterialService.dart';

import 'package:pharmacy_wms/Services/ProductService.dart';

import 'package:pharmacy_wms/Services/TransliterationService.dart';

import 'package:pharmacy_wms/Services/alertService.dart';

import 'package:pharmacy_wms/Services/thresholdService.dart';

class ProductProvider extends ChangeNotifier {
  List<MaterialModel> _products = [];
  bool _loading = false;
  String? _error;
  int _lowStockThreshold = 100;
  int _expiringSoonDays = 30;
  Future<void> loadThresholds() async {
    // Fetch both thresholds in parallel instead of sequentially
    final results = await Future.wait([
      ThresholdService.getLowStockThreshold(),
      ThresholdService.getExpiringSoonDays(),
    ]);
    _lowStockThreshold = results[0];
    _expiringSoonDays = results[1];
  }


 final Map<String, Map<String, dynamic>> _pendingOverrides = {

};
  List<MaterialModel> get products => UnmodifiableListView(_products);
  bool get loading => _loading;
  String? get error => _error;
  int get totalProducts => _products.length;
  int get expiredCount => _products.where((product) {
    final expiry = product.expiryDateValue;
    return expiry != null && expiry.isBefore(DateTime.now());
  
}).length;
  int get expiringSoonCount => _products.where((product) {
    final expiry = product.expiryDateValue;
    if (expiry == null) {
      return false;
    
}

    final days = expiry.difference(DateTime.now()).inDays;
    return days > 0 && days <= _expiringSoonDays;
  
}).length;
  int getCriticalAlertsCount() => expiredCount + expiringSoonCount;
  int get lowStockCount =>      _products.where((product) => product.quantity < _lowStockThreshold).length;
  Future<void> loadProducts() async {
    if (!AuthService.isAuthenticated) {
      clear(notify: true);
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Load thresholds and products in parallel — reduces startup time significantly
      await Future.wait([
        loadThresholds().catchError((_) {}),
        _replaceProductsFromApi(),
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }


  Future<String?> addProduct(Map<String, dynamic> body) async {
    try {
      await ProductService.addProduct(body);
      await _refreshProductsAfterMutation();
      return null;
    
} catch (e) {
      return _handleMutationError(e);
    
}  
}


  Future<String?> updateProduct(String id, Map<String, dynamic> body) async {
    try {
      await ProductService.updateProduct(id, body);
      final expectedQty = body['quantity'] as int?;
      final expectedAvail = body['isAvailable'] as bool?;
      if (expectedQty != null || expectedAvail != null) {
        _pendingOverrides[id] = {
          if (expectedQty != null) 'quantity': expectedQty,          if (expectedAvail != null) 'isAvailable': expectedAvail,        
};
      
}
      await _replaceProductsFromApi();
      notifyListeners();
      return null;
    
} catch (e) {
      return _handleMutationError(e);
    
}  
}


  Future<String?> deleteProduct(String id) async {
    try {
      final error = await ProductService.deleteProduct(id);
      if (error != null) {
        return error;
      
}
      await _refreshProductsAfterMutation();
      return null;
    
} catch (e) {
      return _handleMutationError(e);
    
}  
}  MaterialModel? findBySku(String sku) {
    try {
      return _products.firstWhere(        (product) => product.sku.toLowerCase() == sku.toLowerCase(),      );
    
} catch (_) {
      return null;
    
}  
}  MaterialModel? findById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    
} catch (_) {
      return null;
    
}  
}  MaterialModel? findByNameOrSku(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;
    try {
      return _products.firstWhere(        (product) =>            product.sku.toLowerCase() == query ||            product.name.toLowerCase() == query,      );
    
} catch (_) {
      return null;
    
}  
}

  void clear({
bool notify = false
}) {
    _products = [];
    _loading = false;
    _error = null;
    _pendingOverrides.clear();
    _syncDerivedState();
    if (notify) {
      notifyListeners();
    
}  
}

  void _syncDerivedState() {
    MaterialService.updateCache(_products);
    AlertService.initializeAlertsFromModels(_products);
  
}

  Future<List<MaterialModel>> _fetchProductsFromApi() {
    return ProductService.getAllProducts();
  
}


  Future<void> _replaceProductsFromApi() async {
    // Fire all three network calls simultaneously instead of sequentially
    final results = await Future.wait([
      _fetchProductsFromApi(),
      AlertService.reloadThresholds(),
      MaterialService.reloadThresholds(),
    ]);
    _products = results[0] as List<MaterialModel>;
    _applyPendingOverrides();
    _syncDerivedState();
  }


  Future<void> _translateProductNames() async {
    if (languageNotifier.value != AppLanguage.ar) return;
    if (_products.isEmpty) return;
    final allStrings = <String>{

};
    for (final p in _products) {
      if (p.name.isNotEmpty) allStrings.add(p.name);
      if (p.category.isNotEmpty && p.category != 'Uncategorized') {
        allStrings.add(p.category);
      
}    
}

    final map = TransliterationService.transliterateAll(allStrings.toList());
    _products = _products.map((p) {
      return p.copyWith(        name: map[p.name] ?? p.name,        category: map[p.category] ?? p.category,      );
    
}).toList();
  
}

  void _applyPendingOverrides() {
    if (_pendingOverrides.isEmpty) return;
    for (int i = 0;
 i < _products.length;
 i++) {
      final overrides = _pendingOverrides[_products[i].id];
      if (overrides == null) continue;
      final expectedQty = overrides['quantity'] as int?;
      final expectedAvail = overrides['isAvailable'] as bool?;
      final serverMatchesWrite =          (expectedQty == null || _products[i].quantity == expectedQty) &&          (expectedAvail == null || _products[i].isAvailable == expectedAvail);
      if (serverMatchesWrite) {
        _pendingOverrides.remove(_products[i].id);
      } else {
        _products[i] = _products[i].copyWith(
          quantity: expectedQty ?? _products[i].quantity,
          isAvailable: expectedAvail ?? _products[i].isAvailable,
        );
      }
    }
  }



  Future<void> _refreshProductsAfterMutation() async {
    _error = null;
    await _replaceProductsFromApi();
    notifyListeners();
  
}

  String _handleMutationError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    _error = message;
    notifyListeners();
    return message;
  
}

  static ProductProvider of(BuildContext context, {
bool listen = true
}) {
    if (listen) {
      final inherited = context          .dependOnInheritedWidgetOfExactType<_ProductProviderInherited>();
      assert(        inherited != null,        'ProductProviderScope is missing above this widget.',      );
      return inherited!.provider;
    
}

    final element = context        .getElementForInheritedWidgetOfExactType<_ProductProviderInherited>();
    final widget = element?.widget;
    assert(      widget != null,      'ProductProviderScope is missing above this widget.',    );
    return (widget as _ProductProviderInherited).provider;
  
}
}
class ProductProviderScope extends StatefulWidget {
  final Widget child;
  const ProductProviderScope({
super.key, required this.child
});
  @override  State<ProductProviderScope> createState() => _ProductProviderScopeState();

}
class _ProductProviderScopeState extends State<ProductProviderScope> {
  final ProductProvider _provider = ProductProvider();
  @override  void initState() {
    super.initState();
    AuthService.sessionChanges.addListener(_handleSessionChange);
    languageNotifier.addListener(_handleLanguageChange);
    _handleSessionChange();
  
}
  @override  void dispose() {
    AuthService.sessionChanges.removeListener(_handleSessionChange);
    languageNotifier.removeListener(_handleLanguageChange);
    _provider.dispose();
    super.dispose();
  
}

  void _handleSessionChange() {
    if (AuthService.isAuthenticated) {
      _provider.loadProducts();
    
} else {
      _provider.clear(notify: true);
    
}  
}
  void _handleLanguageChange() {
    if (AuthService.isAuthenticated) {
      TransliterationService.clearCache();
      _provider.loadProducts();
    
}  
}
  @override  Widget build(BuildContext context) {
    return AnimatedBuilder(      animation: _provider,      builder: (context, _) {
        return _ProductProviderInherited(          provider: _provider,          child: widget.child,        );
      
},    );
  
}
}
class _ProductProviderInherited extends InheritedWidget {
  final ProductProvider provider;
  const _ProductProviderInherited({
    required this.provider,    required super.child,  
});
  @override  bool updateShouldNotify(_ProductProviderInherited oldWidget) => true;

}