import 'stockBatchModel.dart';

class MaterialModel {  final String id;  final String name;  final String sku;  final int quantity;  final String unit;  final String lot;  final String expiryDate;  final String supplier;  final bool isAvailable;  final int categoryId;  final String category;  final DateTime createdAt;  final List<StockBatch> batches;  const MaterialModel({    required this.id,    required this.name,    required this.sku,    required this.quantity,    required this.unit,    required this.lot,    required this.expiryDate,    required this.supplier,    required this.isAvailable,    required this.categoryId,    required this.category,    required this.createdAt,    this.batches = const [],  });  String get materialName => name;  String get materialSKU => sku;  String get logNumber => lot;  String get storageLocation => supplier;  DateTime? get expiryDateValue => _tryParseDate(expiryDate);  factory MaterialModel.fromJson(Map<String, dynamic> json) {    final quantity = _toInt(      json['quantity'] ?? json['qty'] ?? json['stock'] ?? 0,    );    final categoryId = _toInt(json['categoryId'] ?? json['categoryID'] ?? 0);    final rawCategory =        (json['categoryName'] ?? json['category'] ?? json['cat'] ?? '')            .toString()            .trim();
    final rawBatches = json['batches'];
    final batches = (rawBatches is List)
        ? rawBatches
            .map((b) => b is Map<String, dynamic> ? StockBatch.fromJson(b) : null)
            .whereType<StockBatch>()
            .toList()
        : <StockBatch>[];
    return MaterialModel(      id: (json['id'] ?? json['productId'] ?? '').toString(),      name: (json['materialName'] ?? json['name'] ?? json['productName'] ?? '')          .toString(),      sku:          (json['materialSKU'] ??
                  json['material_SKU'] ??
                  json['materialSku'] ??                  json['sku'] ??                  json['SKU'] ??                  '')              .toString(),      quantity: quantity,      unit: (json['unit'] ?? '').toString(),      lot: (json['logNumber'] ?? json['lotNumber'] ?? json['lot'] ?? '')          .toString(),      expiryDate: _normalizeDateString(        json['expiryDate'] ?? json['expiry'] ?? json['expirationDate'],      ),      supplier:          (json['supplier'] ?? json['supplierName'] ?? '').toString(),      isAvailable: _toBool(
        json['isAvailable'] ?? json['available'] ?? (quantity > 0),
      ) && quantity > 0,      categoryId: categoryId,      category: rawCategory.isNotEmpty          ? rawCategory          : categoryId > 0          ? 'Category #$categoryId'          : 'Uncategorized',      createdAt:          _tryParseDateTime(json['createdAt'] ?? json['created_at']) ??          DateTime.fromMillisecondsSinceEpoch(0),      batches: batches,    );  }

  Map<String, dynamic> toJson() {    return {      if (id.isNotEmpty) 'id': _jsonFriendlyId(id),      'materialName': name,      'materialSKU': sku,      'quantity': quantity,      'unit': unit,      'logNumber': lot,      'expiryDate': expiryDate,      'supplier': supplier,      'isAvailable': isAvailable,      'categoryId': categoryId,      if (category.isNotEmpty) 'categoryName': category,    };  }

  Map<String, dynamic> toApiBody() {    return {      'materialName': name,      'materialSKU': sku,      'quantity': quantity,      'unit': unit,      'logNumber': lot,      'expiryDate': expiryDate,      'supplier': supplier,      'isAvailable': quantity > 0 && isAvailable,      'categoryId': categoryId,    };  }
  MaterialModel copyWith({    String? id,    String? name,    String? sku,    int? quantity,    String? unit,    String? lot,    String? expiryDate,    String? supplier,    bool? isAvailable,    int? categoryId,    String? category,    DateTime? createdAt,    List<StockBatch>? batches,  }) {    return MaterialModel(      id: id ?? this.id,      name: name ?? this.name,      sku: sku ?? this.sku,      quantity: quantity ?? this.quantity,      unit: unit ?? this.unit,      lot: lot ?? this.lot,      expiryDate: expiryDate ?? this.expiryDate,      supplier: supplier ?? this.supplier,      isAvailable: isAvailable ?? this.isAvailable,      categoryId: categoryId ?? this.categoryId,      category: category ?? this.category,      createdAt: createdAt ?? this.createdAt,      batches: batches ?? this.batches,    );  }

  static int _toInt(dynamic value) {    if (value is int) {      return value;    }    if (value is double) {      return value.toInt();    }

    final str = value?.toString() ?? '';    return int.tryParse(str) ?? double.tryParse(str)?.toInt() ?? 0;  }

  static bool _toBool(dynamic value) {    if (value is bool) {      return value;    }

    final normalized = value?.toString().toLowerCase() ?? '';    return normalized == 'true' || normalized == '1';  }

  static DateTime? _tryParseDate(String value) {    try {      return DateTime.parse(value);    } catch (_) {      return null;    }  }

  static DateTime? _tryParseDateTime(dynamic value) {    if (value == null || value.toString().trim().isEmpty) {      return null;    }    try {      return DateTime.parse(value.toString());    } catch (_) {      return null;    }  }

  static String _normalizeDateString(dynamic value) {    if (value == null || value.toString().trim().isEmpty) {      return '';    }

    final raw = value.toString();    final parsed = _tryParseDateTime(raw);    return parsed?.toIso8601String() ?? raw;  }

  static dynamic _jsonFriendlyId(String value) {    return int.tryParse(value) ?? value;  }}
