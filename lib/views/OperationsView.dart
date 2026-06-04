import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Services/orderService.dart';
import 'package:pharmacy_wms/Services/ApprovalService.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';

enum OperationType { materialReceipt, materialDispatch, expiryEdit }

class OperationItem {
  final String materialName;
  final String materialSku;
  final int quantity;
  final String unit;
  final String? oldExpiry;
  final String? newExpiry;
  final String? logNumber;

  OperationItem({
    required this.materialName,
    required this.materialSku,
    required this.quantity,
    required this.unit,
    this.oldExpiry,
    this.newExpiry,
    this.logNumber,
  });
}

class WarehouseOperation {
  final String uniqueId;
  final OperationType type;
  final DateTime date;
  final String partyName;
  final String status;
  final List<OperationItem> items;
  final dynamic rawData;

  WarehouseOperation({
    required this.uniqueId,
    required this.type,
    required this.date,
    required this.partyName,
    required this.status,
    required this.items,
    required this.rawData,
  });
}

class OperationsPage extends StatefulWidget {
  final VoidCallback? onGoToOrders;
  const OperationsPage({super.key, this.onGoToOrders});
  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedDateFilter = 'Filter by Date';
  String _selectedStatusFilter = 'Filter by Status';
  OperationType? _selectedType;
  List<OrderModel> _orders = [];
  List<Map<String, dynamic>> _approvalRequests = [];
  List<WarehouseOperation> _allOperations = [];
  Timer? _debounce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    OrderService.changes.addListener(_load);
    NotificationService.changes.addListener(_handleNotificationChange);
  }

  @override
  void dispose() {
    OrderService.changes.removeListener(_load);
    NotificationService.changes.removeListener(_handleNotificationChange);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        Future.value(OrderService.getAllOrders()),
        ApprovalService.fetchAllRequests(),
      ]);
      if (!mounted) return;
      final orders = results[0] as List<OrderModel>;
      final requests = results[1] as List<Map<String, dynamic>>;
      _orders = orders;
      _approvalRequests = requests;
      _buildOperations();
    } catch (e) {
      if (!mounted) return;
      _orders = OrderService.getAllOrders();
      _approvalRequests = [];
      _buildOperations();
    }
  }

  void _buildOperations() {
    final List<WarehouseOperation> tempOps = [];

    final Map<String, List<OrderModel>> receiptGroups = {};
    final Map<String, List<OrderModel>> dispatchGroups = {};

    for (final order in _orders) {
      final inv = order.invoiceNumber;
      if (inv == null || inv.isEmpty) continue;
      if (order.type == OrderType.add) {
        receiptGroups.putIfAbsent(inv, () => []).add(order);
      } else if (order.type == OrderType.export) {
        dispatchGroups.putIfAbsent(inv, () => []).add(order);
      }
    }

    receiptGroups.forEach((inv, orders) {
      if (orders.isEmpty) return;
      final first = orders.first;
      tempOps.add(WarehouseOperation(
        uniqueId: inv,
        type: OperationType.materialReceipt,
        date: orders.map((o) => o.createdAt).reduce((a, b) => a.isBefore(b) ? a : b),
        partyName: first.supplier.isNotEmpty ? first.supplier : 'Unknown',
        status: 'Completed',
        items: orders.map((o) => OperationItem(
          materialName: o.productName,
          materialSku: o.productSku,
          quantity: o.quantity,
          unit: o.unit,
          logNumber: o.logNumber,
        )).toList(),
        rawData: orders,
      ));
    });

    dispatchGroups.forEach((inv, orders) {
      if (orders.isEmpty) return;
      final first = orders.first;
      tempOps.add(WarehouseOperation(
        uniqueId: inv,
        type: OperationType.materialDispatch,
        date: orders.map((o) => o.createdAt).reduce((a, b) => a.isBefore(b) ? a : b),
        partyName: first.recipient.isNotEmpty ? first.recipient : 'Unknown',
        status: 'Completed',
        items: orders.map((o) => OperationItem(
          materialName: o.productName,
          materialSku: o.productSku,
          quantity: o.quantity,
          unit: o.unit,
          logNumber: o.logNumber,
        )).toList(),
        rawData: orders,
      ));
    });

    for (final req in _approvalRequests) {
      final batch = req['batch'] as Map<String, dynamic>?;
      final product = batch?['product'] as Map<String, dynamic>?;
      final materialName = (product?['materialName'] ?? req['productName'] ?? '').toString();
      final materialSku = (product?['materialSku'] ?? req['productSku'] ?? '').toString();
      final status = (req['status'] ?? 'Pending').toString();
      if (status.toLowerCase() == 'approved') status;
      tempOps.add(WarehouseOperation(
        uniqueId: 'REQ-${req['id']}',
        type: OperationType.expiryEdit,
        date: DateTime.tryParse(req['requestedAt']?.toString() ?? '') ?? DateTime.now(),
        partyName: (req['requestedBy'] ?? 'Unknown').toString(),
        status: status,
        items: [
          OperationItem(
            materialName: materialName,
            materialSku: materialSku,
            quantity: int.tryParse(batch?['quantity']?.toString() ?? '') ?? 0,
            unit: (product?['unit'] ?? '').toString(),
            oldExpiry: req['oldExpiry']?.toString(),
            newExpiry: req['newExpiry']?.toString(),
          ),
        ],
        rawData: req,
      ));
    }

    tempOps.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _allOperations = tempOps;
        _loading = false;
      });
    }
  }

  List<WarehouseOperation> _getFilteredOperations() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final now = DateTime.now();
    return _allOperations.where((op) {
      if (_selectedType != null && op.type != _selectedType) return false;
      if (query.isNotEmpty) {
        final matchesSearch = op.uniqueId.toLowerCase().contains(query) ||
            op.partyName.toLowerCase().contains(query) ||
            op.items.any((item) =>
                item.materialName.toLowerCase().contains(query) ||
                item.materialSku.toLowerCase().contains(query));
        if (!matchesSearch) return false;
      }
      switch (_selectedStatusFilter) {
        case 'Completed':
          if (op.status != 'Completed') return false;
        case 'Pending':
          if (op.status != 'Pending') return false;
        case 'Rejected':
          if (op.status != 'Rejected') return false;
      }
      switch (_selectedDateFilter) {
        case 'Today':
          if (op.date.year != now.year || op.date.month != now.month || op.date.day != now.day) return false;
        case 'This Week':
          if (now.difference(op.date).inDays > 7) return false;
        case 'This Month':
          if (op.date.year != now.year || op.date.month != now.month) return false;
        case 'This Year':
          if (op.date.year != now.year) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _approveExpiryEdit(dynamic req) async {
    final id = req['id'] is int ? req['id'] : int.tryParse(req['id'].toString()) ?? 0;
    try {
      await ApprovalService.approveRequest(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.requestApproved)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception:', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _rejectExpiryEdit(dynamic req) async {
    final id = req['id'] is int ? req['id'] : int.tryParse(req['id'].toString()) ?? 0;
    final notesCtrl = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.rejectRequest),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr.rejectionNotes,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, notesCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr.reject, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    notesCtrl.dispose();
    if (notes == null || !mounted) return;
    try {
      await ApprovalService.rejectRequest(id, notes: notes.isEmpty ? null : notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.requestRejected)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception:', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _viewOperationDetails(WarehouseOperation op, bool isDark) {
    final tr = context.tr;
    final typeLabel = switch (op.type) {
      OperationType.materialReceipt => tr.orderTypeAdd,
      OperationType.materialDispatch => tr.orderTypeExport,
      OperationType.expiryEdit => tr.orderTypeEdit,
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_typeIcon(op.type), size: 20, color: _typeColor(op.type)),
            const SizedBox(width: 8),
            Expanded(child: Text('$typeLabel - ${op.uniqueId}')),
          ],
        ),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(tr.date, _formatDateTime(op.date)),
              if (op.type == OperationType.materialReceipt)
                _detailRow(tr.supplier, op.partyName),
              if (op.type == OperationType.materialDispatch)
                _detailRow(tr.recipient, op.partyName),
              if (op.type == OperationType.expiryEdit) ...[
                _detailRow(tr.requestedBy, op.partyName),
                _detailRow(tr.status, op.status),
              ],
              _detailRow(tr.materials, op.items.length.toString()),
              _detailRow(tr.totalQuantity, op.items.fold(0, (sum, i) => sum + i.quantity).toString()),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(tr.materials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ...op.items.map((item) => _materialCard(item, op.type, isDark)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.close),
          ),
        ],
      ),
    );
  }

  Widget _materialCard(OperationItem item, OperationType type, bool isDark) {
    final typeColor = _typeColor(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.materialName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              _badge(_typeLabel(type, context.tr), typeColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${context.tr.skuPrefix}${item.materialSku}  |  ${context.tr.quantity}: ${item.quantity} ${item.unit}',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
          ),
          if (item.logNumber != null && item.logNumber!.isNotEmpty)
            Text(
              '${context.tr.logNumber}: ${item.logNumber}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
            ),
          if (item.oldExpiry != null && item.newExpiry != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Text(
                    '${context.tr.oldExpiry}: ${_formatRawDate(item.oldExpiry!)}',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade400, decoration: TextDecoration.lineThrough),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${context.tr.newExpiryDate}: ${_formatRawDate(item.newExpiry!)}',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _notificationBell() {
    final unreadCount = NotificationService.getUnread().length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: context.tr.editRequests,
          onPressed: _showOrderNotifications,
          icon: const Icon(Icons.notifications_none),
        ),
        if (unreadCount > 0)
          PositionedDirectional(
            end: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  void _showOrderNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final notifications = NotificationService.getAll();
          return AlertDialog(
            title: Text('${context.tr.editRequests} (${NotificationService.getUnread().length})'),
            content: SizedBox(
              width: 520,
              child: notifications.isEmpty
                  ? Text(context.tr.noEditRequests)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
                            color: item.isRead ? Colors.grey : Colors.green,
                          ),
                          title: Text(item.materialName ?? item.title),
                          subtitle: Text(
                            '${context.tr.sku}: ${item.productSku ?? '-'}\n'
                            'Proposed expiry: ${_formatRawDate(item.proposedExpiry ?? '')}\n'
                            'Manager: ${item.managerName ?? '-'}',
                          ),
                          isThreeLine: true,
                          trailing: TextButton(
                            onPressed: () {
                              NotificationService.markRead(item.id);
                              setState(() {});
                              setDialogState(() {});
                              Navigator.pop(ctx);
                              widget.onGoToOrders?.call();
                            },
                            child: Text(context.tr.goToOrders),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  for (final n in NotificationService.getUnread()) {
                    NotificationService.markRead(n.id);
                  }
                  setState(() {});
                  setDialogState(() {});
                },
                child: Text(context.tr.markAllRead),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr.close),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = context.tr;
    final filteredOps = _getFilteredOperations();
    final receiptsCount = _allOperations.where((o) => o.type == OperationType.materialReceipt).length;
    final dispatchesCount = _allOperations.where((o) => o.type == OperationType.materialDispatch).length;
    final editsCount = _allOperations.where((o) => o.type == OperationType.expiryEdit).length;
    final pendingOps = _allOperations.where((o) => o.status == 'Pending').length;

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
                    color: const Color(0xFF1E90FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assessment_outlined, color: Color(0xFF1E90FF), size: 24),
                ),
                const SizedBox(width: 12),
                _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        tr.ordersHistory,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                const Spacer(),
                if (AuthService.isSupervisor) ...[
                  _notificationBell(),
                  const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(flex: 3, child: _searchBox(isDark)),
                const SizedBox(width: 12),
                _dropdown(
                  isDark,
                  _selectedDateFilter,
                  ['Filter by Date', 'Today', 'This Week', 'This Month', 'This Year'],
                  (v) {
                    if (v != null) setState(() => _selectedDateFilter = v);
                  },
                  (v) => _dateFilterDisplay(v),
                ),
                const SizedBox(width: 12),
                _dropdown(
                  isDark,
                  _selectedStatusFilter,
                  ['Filter by Status', 'Completed', 'Pending', 'Rejected'],
                  (v) {
                    if (v != null) setState(() => _selectedStatusFilter = v);
                  },
                  (v) => _statusFilterDisplay(v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip(tr.all, null, isDark),
                  const SizedBox(width: 8),
                  _filterChip('${tr.orderTypeAdd} ($receiptsCount)', OperationType.materialReceipt, isDark),
                  const SizedBox(width: 8),
                  _filterChip('${tr.orderTypeExport} ($dispatchesCount)', OperationType.materialDispatch, isDark),
                  const SizedBox(width: 8),
                  _filterChip('${tr.orderTypeEdit} ($editsCount)', OperationType.expiryEdit, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryStats(filteredOps, isDark, tr),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assessment_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black12),
                              const SizedBox(height: 16),
                              Text(
                                tr.noInvoicesFound,
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredOps.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _operationCard(filteredOps[index], isDark),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, OperationType? type, bool isDark) {
    final selected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedType = _selectedType == type ? null : type),
      selectedColor: _typeColor(type ?? OperationType.materialReceipt).withOpacity(0.2),
      checkmarkColor: _typeColor(type ?? OperationType.materialReceipt),
      labelStyle: TextStyle(
        color: selected
            ? _typeColor(type ?? OperationType.materialReceipt)
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: isDark ? const Color(0xFF1A2332) : Colors.white,
      side: BorderSide(
        color: selected
            ? _typeColor(type ?? OperationType.materialReceipt)
            : (isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSummaryStats(List<WarehouseOperation> ops, bool isDark, AppLocalizations tr) {
    final completed = ops.where((o) => o.status == 'Completed').length;
    final pending = ops.where((o) => o.status == 'Pending').length;
    final rejected = ops.where((o) => o.status == 'Rejected').length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _statTile(tr.materials, ops.length.toString(), Colors.blueAccent, isDark),
          const SizedBox(width: 12),
          _statTile(tr.orderStatusCompleted, completed.toString(), Colors.green, isDark),
          const SizedBox(width: 12),
          _statTile(tr.orderStatusPending, pending.toString(), Colors.orange, isDark),
          const SizedBox(width: 12),
          _statTile(tr.rejected, rejected.toString(), Colors.red, isDark),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _operationCard(WarehouseOperation op, bool isDark) {
    final tr = context.tr;
    final color = _typeColor(op.type);
    final icon = _typeIcon(op.type);
    final typeLabel = _typeLabel(op.type, tr);
    final isPending = op.status == 'Pending';
    final rawData = op.rawData;

    return InkWell(
      onTap: () => _viewOperationDetails(op, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPending
                ? Colors.orange.withOpacity(0.5)
                : (isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  op.uniqueId,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                if (isPending && op.type == OperationType.expiryEdit && AuthService.isSupervisor) ...[
                  SizedBox(
                    height: 30,
                    child: ElevatedButton.icon(
                      onPressed: () => _approveExpiryEdit(rawData),
                      icon: const Icon(Icons.check, size: 15),
                      label: Text(tr.approve, style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 30,
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectExpiryEdit(rawData),
                      icon: const Icon(Icons.close, size: 15),
                      label: Text(tr.reject, style: const TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (op.status != 'Completed')
                  _statusBadge(op.status, isDark, tr)
                else
                  Icon(Icons.visibility, size: 18, color: isDark ? Colors.white54 : Colors.black38),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${op.partyName}  |  ${_formatDate(op.date)}  |  ${op.items.length} ${tr.materials}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (op.type == OperationType.expiryEdit && op.items.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${op.items.first.materialName} - ${tr.skuPrefix}${op.items.first.materialSku}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, bool isDark, AppLocalizations tr) {
    final (label, color) = switch (status) {
      'Pending' => (tr.orderStatusPending, const Color(0xFFFFA500)),
      'Rejected' => (tr.rejected, const Color(0xFFDC3545)),
      _ => (status, Colors.grey),
    };
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

  Widget _searchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300),
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
          hintText: context.tr.searchOrdersHint,
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
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
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

  Color _typeColor(OperationType type) {
    return switch (type) {
      OperationType.materialReceipt => Colors.green,
      OperationType.materialDispatch => Colors.blue,
      OperationType.expiryEdit => Colors.orange,
    };
  }

  IconData _typeIcon(OperationType type) {
    return switch (type) {
      OperationType.materialReceipt => Icons.add_circle_outline,
      OperationType.materialDispatch => Icons.remove_circle_outline,
      OperationType.expiryEdit => Icons.edit_calendar_outlined,
    };
  }

  String _typeLabel(OperationType type, AppLocalizations tr) {
    return switch (type) {
      OperationType.materialReceipt => tr.orderTypeAdd,
      OperationType.materialDispatch => tr.orderTypeExport,
      OperationType.expiryEdit => tr.orderTypeEdit,
    };
  }

  String _dateFilterDisplay(String value) {
    return switch (value) {
      'Filter by Date' => context.tr.filterByDate,
      _ => value,
    };
  }

  String _statusFilterDisplay(String value) {
    return switch (value) {
      'Filter by Status' => context.tr.filterByStatus,
      'Completed' => context.tr.orderStatusCompleted,
      'Pending' => context.tr.orderStatusPending,
      'Rejected' => context.tr.rejected,
      _ => value,
    };
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$m-$d $h:$min';
  }

  String _formatRawDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$m-$d';
  }
}
