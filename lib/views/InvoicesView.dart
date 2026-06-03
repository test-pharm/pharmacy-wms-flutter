import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/orderService.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoiceGroup {
  final String invoiceNumber;
  final List<OrderModel> orders;
  final int totalQuantity;
  final DateTime dateFrom;
  final DateTime dateTo;
  _InvoiceGroup({
    required this.invoiceNumber,
    required this.orders,
    required this.totalQuantity,
    required this.dateFrom,
    required this.dateTo,
  });
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedDateFilter = 'Filter by Date';
  List<OrderModel> _orders = [];
  Timer? _debounce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    OrderService.changes.addListener(_load);
  }

  @override
  void dispose() {
    OrderService.changes.removeListener(_load);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      _orders = OrderService.getAllOrders();
      _loading = false;
    });
  }

  List<_InvoiceGroup> _buildGroups() {
    final groups = <String, List<OrderModel>>{};
    for (final order in _orders) {
      final inv = order.invoiceNumber;
      if (inv == null || inv.isEmpty) continue;
      groups.putIfAbsent(inv, () => []).add(order);
    }
    final now = DateTime.now();
    return groups.entries
        .where((e) {
          final query = _searchCtrl.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty || e.key.toLowerCase().contains(query);
          if (!matchesSearch) return false;
          final dates = e.value.map((o) => o.createdAt);
          final from = dates.reduce((a, b) => a.isBefore(b) ? a : b);
          switch (_selectedDateFilter) {
            case 'Today':
              return from.year == now.year && from.month == now.month && from.day == now.day;
            case 'This Week':
              return now.difference(from).inDays <= 7;
            case 'This Month':
              return from.year == now.year && from.month == now.month;
            case 'This Year':
              return from.year == now.year;
            default:
              return true;
          }
        })
        .map((e) {
          final orders = e.value;
          final dates = orders.map((o) => o.createdAt);
          final totalQty = orders.fold(0, (sum, o) => sum + o.quantity);
          return _InvoiceGroup(
            invoiceNumber: e.key,
            orders: orders,
            totalQuantity: totalQty,
            dateFrom: dates.reduce((a, b) => a.isBefore(b) ? a : b),
            dateTo: dates.reduce((a, b) => a.isAfter(b) ? a : b),
          );
        })
        .toList()
      ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
  }

  void _viewInvoiceDetails(_InvoiceGroup group, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${context.tr.invoiceHash}${group.invoiceNumber}'),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(context.tr.materials, group.orders.length.toString()),
              _detailRow(context.tr.totalQuantity, group.totalQuantity.toString()),
              _detailRow(context.tr.dateRange,
                  '${_formatDate(group.dateFrom)} - ${_formatDate(group.dateTo)}'),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                '${context.tr.materials}:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...group.orders.map((o) => _materialCard(o, isDark, onRefresh: _load)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr.close),
          ),
        ],
      ),
    );
  }

  Widget _materialCard(OrderModel order, bool isDark, {VoidCallback? onRefresh}) {
    final expiry = order.expiryDate;
    final typeColor = switch (order.type) {
      OrderType.add => Colors.green,
      OrderType.export => Colors.blue,
      OrderType.edit => Colors.orange,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${context.tr.skuPrefix}${order.productSku}  |  ${context.tr.quantity}: ${order.quantity} ${order.unit}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
                if (expiry != null && expiry.isNotEmpty)
                  Text(
                    '${context.tr.expPrefix}${_formatExpiry(expiry)}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
              ],
            ),
          ),
          _badge(_localizedOrderType(order.type), typeColor),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _buildGroups();
    final tr = context.tr;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CA0A5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF1CA0A5), size: 24),
                ),
                const SizedBox(width: 12),
                _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        context.tr.invoicesTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: _searchBox(isDark),
                ),
                const SizedBox(width: 12),
                _dropdown(
                  isDark,
                  _selectedDateFilter,
                  ['Filter by Date', 'Today', 'This Week', 'This Month', 'This Year'],
                  (v) {
                    if (v != null) setState(() => _selectedDateFilter = v);
                  },
                  (v) => _dateFilterDisplay(v, tr),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        _loading ? '' : context.tr.noInvoicesFound,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _invoiceCard(groups[index], isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            if (mounted) setState(() {});
          });
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: context.tr.searchByInvoice,
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _dropdown(
    bool isDark,
    String value,
    List<String> items,
    void Function(String?) onChanged,
    String Function(String) label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF1A2332) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(label(item))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _invoiceCard(_InvoiceGroup group, bool isDark) {
    return InkWell(
      onTap: () => _viewInvoiceDetails(group, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, size: 18, color: const Color(0xFF1CA0A5)),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr.invoiceHash}${group.invoiceNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.tr.materialsCount(group.orders.length)}  |  ${context.tr.totalUnits(group.totalQuantity)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(group.dateFrom)} - ${_formatDate(group.dateTo)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1CA0A5).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(context.forwardIosIcon, size: 14, color: const Color(0xFF1CA0A5)),
            ),
          ],
        ),
      ),
    );
  }

  String _dateFilterDisplay(String value, AppLocalizations tr) {
    switch (value) {
      case 'Filter by Date': return tr.filterByDate;
      case 'Today': return tr.today;
      case 'This Week': return tr.thisWeek;
      case 'This Month': return tr.thisMonth;
      case 'This Year': return tr.thisYear;
      default: return value;
    }
  }

  String _localizedOrderType(OrderType type) {
    switch (type) {
      case OrderType.add: return context.tr.orderTypeAdd;
      case OrderType.export: return context.tr.orderTypeExport;
      case OrderType.edit: return context.tr.orderTypeEdit;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  String _formatExpiry(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$m-$d';
  }
}
