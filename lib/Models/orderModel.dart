enum OrderType { add, export, edit }

enum OrderStatus { completed, pending, canceled }

class OrderModel {  final String id;  final String? productId;  final String productName;  final String productSku;  final int quantity;  final String unit;  final String logNumber;  final int categoryId;  final OrderType type;  final OrderStatus status;    final String supplier;
  final String recipient;
  final String createdBy;
  final DateTime createdAt;
  final String? notes;
  final String? invoiceNumber;
  final String? expiryDate;
    OrderModel({
    String? id,
    this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.unit,
    required this.logNumber,
    required this.categoryId,
    required this.type,
    required this.status,
    this.supplier = '',
    this.recipient = '',
    required this.createdBy,
    DateTime? createdAt,
    this.notes,
    this.invoiceNumber,
    this.expiryDate,
  }) : id = id ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
       createdAt = createdAt ?? DateTime.now();  factory OrderModel.fromJson(Map<String, dynamic> json) {    return OrderModel(      id: (json['id'] ?? '').toString(),      productId: json['productId']?.toString(),      productName: (json['productName'] ?? '').toString(),      productSku: (json['productSku'] ?? '').toString(),      quantity: _toInt(json['quantity']),      unit: (json['unit'] ?? '').toString(),      logNumber: (json['logNumber'] ?? '').toString(),      categoryId: _toInt(json['categoryId']),      type: _typeFromString((json['type'] ?? '').toString()),      status: _statusFromString((json['status'] ?? '').toString()),      supplier: (json['supplier'] ?? '').toString(),
      recipient: (json['recipient'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),      createdAt:          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??          DateTime.now(),      notes: json['notes']?.toString(),      invoiceNumber: _extractInvoiceNumber(json),      expiryDate: json['expiryDate']?.toString(),    );  }

  Map<String, dynamic> toJson() {    final pid = productId;    return {      'id': id,      if (pid != null) 'productId': int.tryParse(pid),      'productName': productName,      'productSku': productSku,      'quantity': quantity,      'unit': unit,      'logNumber': logNumber,      'categoryId': categoryId,      'type': type.name,      'status': status.name,      'supplier': supplier,      'recipient': recipient,      'createdBy': createdBy,      'createdAt': createdAt.toIso8601String(),      if (notes != null) 'notes': notes,      if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,      if (expiryDate != null) 'expiryDate': expiryDate,    };  }
  OrderModel copyWith({    String? id,    String? productId,    String? productName,    String? productSku,    int? quantity,    String? unit,    String? logNumber,    int? categoryId,    OrderType? type,    OrderStatus? status,    String? supplier,    String? recipient,    String? createdBy,    DateTime? createdAt,    String? notes,    String? invoiceNumber,    String? expiryDate,  }) {    return OrderModel(      id: id ?? this.id,      productId: productId ?? this.productId,      productName: productName ?? this.productName,      productSku: productSku ?? this.productSku,      quantity: quantity ?? this.quantity,      unit: unit ?? this.unit,      logNumber: logNumber ?? this.logNumber,      categoryId: categoryId ?? this.categoryId,      type: type ?? this.type,      status: status ?? this.status,      supplier: supplier ?? this.supplier,      recipient: recipient ?? this.recipient,      createdBy: createdBy ?? this.createdBy,      createdAt: createdAt ?? this.createdAt,      notes: notes ?? this.notes,      invoiceNumber: invoiceNumber ?? this.invoiceNumber,      expiryDate: expiryDate ?? this.expiryDate,    );  }

  static int _toInt(dynamic value) {    if (value is int) return value;    return int.tryParse(value?.toString() ?? '') ?? 0;  }

  static OrderType _typeFromString(String value) {    return OrderType.values.firstWhere(      (type) => type.name == value,      orElse: () => OrderType.add,    );  }

  static OrderStatus _statusFromString(String value) {    return OrderStatus.values.firstWhere(      (status) => status.name == value,      orElse: () => OrderStatus.pending,    );  }

  static String? _extractInvoiceNumber(Map<String, dynamic> json) {
    final inv = json['invoiceNumber']?.toString();
    if (inv != null && inv.isNotEmpty) return inv;
    final notes = json['notes']?.toString();
    if (notes != null && notes.startsWith('Invoice: ')) {
      return notes.substring(9);
    }
    return null;
  }}