import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/orderService.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pharmacy_wms/widgets/empty_state.dart';
class OrdersPage extends StatefulWidget {  final VoidCallback? onGoToOrders;  const OrdersPage({super.key, this.onGoToOrders});  @override  State<OrdersPage> createState() => _OrdersPageState();}
class _OrdersPageState extends State<OrdersPage> {  final TextEditingController _searchCtrl = TextEditingController();  String _selectedDateFilter = 'Filter by Date';  String _selectedStatusFilter = 'Filter by Status';  List<OrderModel> _orders = [];  Timer? _debounce;  bool _loadingOrders = true;  @override  void initState() {    super.initState();    _loadOrders();    OrderService.changes.addListener(_loadOrders);    NotificationService.changes.addListener(_handleNotificationChange);  }
  @override  void dispose() {    OrderService.changes.removeListener(_loadOrders);    NotificationService.changes.removeListener(_handleNotificationChange);    _searchCtrl.dispose();    _debounce?.cancel();    super.dispose();  }

  void _loadOrders() {    if (!mounted) return;    setState(() {      _orders = OrderService.getAllOrders();      _loadingOrders = false;    });  }

  void _handleNotificationChange() {    if (mounted) setState(() {});  }
  @override  Widget build(BuildContext context) {    final isDark = Theme.of(context).brightness == Brightness.dark;    final filteredOrders = _filteredOrders();    return Scaffold(      backgroundColor: isDark          ? const Color(0xFF0E1621)          : const Color(0xFFF5F5F5),      body: Padding(        padding: const EdgeInsets.all(28),        child: Column(          crossAxisAlignment: CrossAxisAlignment.start,          children: [            Row(              children: [                Container(                  padding: const EdgeInsets.all(8),                  decoration: BoxDecoration(                    color: const Color(0xFF1E90FF).withOpacity(0.15),                    borderRadius: BorderRadius.circular(12),                  ),                  child: const Icon(                    Icons.history,                    color: Color(0xFF1E90FF),                    size: 24,                  ),                ),                const SizedBox(width: 12),                _loadingOrders                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))                    : Text(context.tr.ordersHistory, style: TextStyle(                    fontSize: 24,                    fontWeight: FontWeight.bold,                    color: isDark ? Colors.white : Colors.black,                  ),),                const Spacer(),                if (AuthService.isSupervisor) ...[                  _notificationBell(),                  const SizedBox(width: 10),                ],                ElevatedButton.icon(                  onPressed: _printOrders,                  icon: const Icon(Icons.print, size: 18),                  label: Text(context.tr.export),                  style: ElevatedButton.styleFrom(                    backgroundColor: const Color(0xFF0D6EFD),                    foregroundColor: Colors.white,                  ),                ),              ],            ),            const SizedBox(height: 28),            Row(              children: [                Expanded(flex: 3, child: _searchBox(isDark)),                const SizedBox(width: 12),                _dropdown(                  isDark,                  _selectedDateFilter,                  ['Filter by Date', 'Today', 'This Week', 'This Month', 'This Year'],                  (value) => setState(() => _selectedDateFilter = value!),                  _dateFilterDisplay,                ),                const SizedBox(width: 12),                _dropdown(                  isDark,                  _selectedStatusFilter,                  ['Filter by Status', 'Completed', 'Pending', 'Canceled'],                  (value) => setState(() => _selectedStatusFilter = value!),                  _statusFilterDisplay,                ),              ],            ),            const SizedBox(height: 16),            _buildSummaryStats(filteredOrders, isDark),            const SizedBox(height: 4),            Expanded(              child: filteredOrders.isEmpty                                    ? const EmptyState(                      icon: Icons.list_alt_outlined,                      title: 'No Orders Yet',                      subtitle: 'Orders will appear here once created.',                    )                  : ListView.builder(                      itemCount: filteredOrders.length,                      itemBuilder: (context, index) {                        return Padding(                          padding: const EdgeInsets.only(bottom: 12),                          child: _orderCard(filteredOrders[index], isDark),                        );                      },                    ),            ),          ],        ),      ),    );  }

  String _dateFilterDisplay(String value) {    return switch (value) {      'Filter by Date' => context.tr.filterByDate,      _ => value,    };  }

  String _statusFilterDisplay(String value) {    return switch (value) {      'Filter by Status' => context.tr.filterByStatus,      'Completed' => context.tr.orderStatusCompleted,      'Pending' => context.tr.orderStatusPending,      'Canceled' => context.tr.orderStatusCanceled,      _ => value,    };  }
  Widget _notificationBell() {    final unreadCount = NotificationService.getUnread().length;    return Stack(      clipBehavior: Clip.none,      children: [        IconButton(          tooltip: context.tr.editRequests,          onPressed: _showOrderNotifications,          icon: const Icon(Icons.notifications_none),        ),        if (unreadCount > 0)          PositionedDirectional(            end: 4,            top: 4,            child: Container(              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),              decoration: BoxDecoration(                color: Colors.red,                borderRadius: BorderRadius.circular(10),              ),              child: Text(                unreadCount.toString(),                style: const TextStyle(                  color: Colors.white,                  fontSize: 10,                  fontWeight: FontWeight.bold,                ),              ),            ),          ),      ],    );  }

  void _showOrderNotifications() {    showDialog(      context: context,      builder: (ctx) => StatefulBuilder(        builder: (context, setDialogState) {          final notifications = NotificationService.getAll();          return AlertDialog(            title: Text(              '${context.tr.editRequests} (${NotificationService.getUnread().length})',            ),            content: SizedBox(              width: 520,              child: notifications.isEmpty                  ? Text(context.tr.noEditRequests)                  : ListView.separated(                      shrinkWrap: true,                      itemCount: notifications.length,                      separatorBuilder: (context, index) => const Divider(),                      itemBuilder: (context, index) {                        final item = notifications[index];                        return ListTile(                          leading: Icon(                            item.isRead                                ? Icons.mark_email_read_outlined                                : Icons.mark_email_unread_outlined,                            color: item.isRead ? Colors.grey : Colors.green,                          ),                          title: Text(item.materialName ?? item.title),                          subtitle: Text(                            '${context.tr.sku}: ${item.productSku ?? '-'}\n'                            'Proposed expiry: ${_formatRawDate(item.proposedExpiry ?? '')}\n'                            'Manager: ${item.managerName ?? '-'}',                          ),                          isThreeLine: true,                          trailing: TextButton(                            onPressed: () {                              NotificationService.markRead(item.id);                              setState(() {});                              setDialogState(() {});                              Navigator.pop(ctx);                              widget.onGoToOrders?.call();                            },                            child: Text(context.tr.goToOrders),                          ),                        );                      },                    ),            ),            actions: [              TextButton(                onPressed: () {                  NotificationService.markAllRead();                  setState(() {});                  Navigator.pop(ctx);                },                child: Text(context.tr.markAllRead),              ),              TextButton(                onPressed: () => Navigator.pop(ctx),                child: Text(context.tr.close),              ),            ],          );        },      ),    );  }
  Widget _searchBox(bool isDark) {    return Container(      decoration: BoxDecoration(        color: isDark ? const Color(0xFF1A2332) : Colors.white,        borderRadius: BorderRadius.circular(12),        border: Border.all(          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,        ),      ),      child: TextField(        controller: _searchCtrl,        onChanged: (_) {          _debounce?.cancel();          _debounce = Timer(const Duration(milliseconds: 300), () {            if (mounted) setState(() {});          });        },        style: TextStyle(color: isDark ? Colors.white : Colors.black),        decoration: InputDecoration(          hintText: context.tr.searchOrdersHint,          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),          prefixIcon: Icon(            Icons.search,            color: isDark ? Colors.white54 : Colors.black54,          ),          border: InputBorder.none,          contentPadding: const EdgeInsets.symmetric(            horizontal: 16,            vertical: 14,          ),        ),      ),    );  }
  Widget _dropdown(    bool isDark,    String value,    List<String> items,    void Function(String?) onChanged,    String Function(String) label,  ) {    return Container(      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),      decoration: BoxDecoration(        color: isDark ? const Color(0xFF1A2332) : Colors.white,        borderRadius: BorderRadius.circular(12),        border: Border.all(          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,        ),      ),      child: DropdownButtonHideUnderline(        child: DropdownButton<String>(          value: value,          dropdownColor: isDark ? const Color(0xFF1A2332) : Colors.white,          style: TextStyle(color: isDark ? Colors.white : Colors.black),          items: items              .map((item) => DropdownMenuItem(value: item, child: Text(label(item))))              .toList(),          onChanged: onChanged,        ),      ),    );  }
    Widget _buildSummaryStats(List<OrderModel> orders, bool isDark) {
    final completed = orders.where((o) => o.status == OrderStatus.completed).length;
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final canceled = orders.where((o) => o.status == OrderStatus.canceled).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _statTile('Total Orders', orders.length.toString(), Colors.blueAccent, isDark),
          const SizedBox(width: 12),
          _statTile('Completed', completed.toString(), Colors.green, isDark),
          const SizedBox(width: 12),
          _statTile('Pending', pending.toString(), Colors.orange, isDark),
          const SizedBox(width: 12),
          _statTile('Canceled', canceled.toString(), Colors.red, isDark),
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

  Widget _orderCard(OrderModel order, bool isDark) {
    return OrderCardWidget(
      order: order,
      isDark: isDark,
      onViewDetails: () => _viewOrderDetails(order, isDark),
      onApprove: AuthService.isSupervisor && order.type == OrderType.edit && order.status == OrderStatus.pending
          ? () => _acceptEdit(order)
          : null,
      onReject: AuthService.isSupervisor && order.type == OrderType.edit && order.status == OrderStatus.pending
          ? () => _rejectEdit(order)
          : null,
    );
  }
  Widget _typeBadge(OrderType type) {    final (label, color) = switch (type) {      OrderType.add => (context.tr.orderTypeAdd, Colors.green),      OrderType.export => (context.tr.orderTypeExport, Colors.blue),      OrderType.edit => (context.tr.orderTypeEdit, Colors.orange),    };    return _badge(label, color);  }
  Widget _statusBadge(OrderStatus status) {    final (label, color) = switch (status) {      OrderStatus.completed => (context.tr.orderStatusCompleted, const Color(0xFF28A745)),      OrderStatus.pending => (context.tr.orderStatusPending, const Color(0xFFFFA500)),      OrderStatus.canceled => (context.tr.orderStatusCanceled, const Color(0xFFDC3545)),    };    return _badge(label, color);  }
  Widget _badge(String label, Color color) {    return Container(      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),      decoration: BoxDecoration(        color: color.withOpacity(0.15),        borderRadius: BorderRadius.circular(6),      ),      child: Text(        label,        style: TextStyle(          color: color,          fontWeight: FontWeight.w600,          fontSize: 12,        ),      ),    );  }

  List<OrderModel> _filteredOrders() {    final query = _searchCtrl.text.trim().toLowerCase();    return _orders.where((order) {      final matchesSearch =          query.isEmpty ||          order.id.toLowerCase().contains(query) ||          order.productName.toLowerCase().contains(query) ||          order.productSku.toLowerCase().contains(query) ||          order.createdBy.toLowerCase().contains(query);      final matchesStatus = switch (_selectedStatusFilter) {        'Completed' => order.status == OrderStatus.completed,        'Pending' => order.status == OrderStatus.pending,        'Canceled' => order.status == OrderStatus.canceled,        _ => true,      };      final now = DateTime.now();      final matchesDate = switch (_selectedDateFilter) {        'Today' =>          order.createdAt.year == now.year &&              order.createdAt.month == now.month &&              order.createdAt.day == now.day,        'This Week' => now.difference(order.createdAt).inDays <= 7,        'This Month' =>          order.createdAt.year == now.year &&              order.createdAt.month == now.month,        'This Year' => order.createdAt.year == now.year,        _ => true,      };      return matchesSearch && matchesStatus && matchesDate && order.type != OrderType.edit;    }).toList();  }


  Future<void> _acceptEdit(OrderModel order) async {    if (order.productId == null) return;    final proposedExpiry = order.expiryDate ?? order.notes;    if (proposedExpiry == null || proposedExpiry.startsWith('Invoice: ')) return;    final provider = ProductProvider.of(context, listen: false);    final matches = provider.products.where(      (item) => item.id == order.productId,    );    final product = matches.isEmpty ? null : matches.first;    if (product == null) {      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(          content: Text(context.tr.productNotInInventory),          backgroundColor: Colors.red,        ),      );      return;    }

    final body = product.toApiBody();    body['expiryDate'] = proposedExpiry;    final error = await provider.updateProduct(order.productId!, body);    if (!mounted) return;    if (error != null) {      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(content: Text(error), backgroundColor: Colors.red),      );      return;    }    try {      await OrderService.updateOrderStatus(order.id, OrderStatus.completed);    } catch (e) {      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(content: Text('$e'), backgroundColor: Colors.red),      );      return;    }    if (!mounted) return;    ScaffoldMessenger.of(context).showSnackBar(      SnackBar(content: Text(context.tr.editApproved)),    );  }


  Future<void> _rejectEdit(OrderModel order) async {    final reasonController = TextEditingController();    final rejected = await showDialog<bool>(      context: context,      builder: (ctx) => AlertDialog(        title: Text('${context.tr.reject} ${context.tr.editRequests}'),        content: TextField(          controller: reasonController,          decoration: InputDecoration(            labelText: context.tr.rejectReasonHint,            border: OutlineInputBorder(),          ),          maxLines: 3,        ),        actions: [          TextButton(            onPressed: () => Navigator.pop(ctx, false),            child: Text(context.tr.cancel),          ),          ElevatedButton(            onPressed: () => Navigator.pop(ctx, true),            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),            child: Text(context.tr.reject),          ),        ],      ),    );    reasonController.dispose();    if (rejected != true) return;    try {      await OrderService.updateOrderStatus(order.id, OrderStatus.canceled);    } catch (e) {      if (!mounted) return;      ScaffoldMessenger.of(context).showSnackBar(        SnackBar(content: Text('$e'), backgroundColor: Colors.red),      );      return;    }    if (!mounted) return;    ScaffoldMessenger.of(context).showSnackBar(      SnackBar(content: Text(context.tr.editRejected)),    );  }

  void _viewOrderDetails(OrderModel order, bool isDark) {    final expiry = order.expiryDate ?? (order.notes != null && !order.notes!.startsWith('Invoice: ') ? order.notes : null);    final invNum = order.invoiceNumber ?? (order.notes?.startsWith('Invoice: ') == true ? order.notes!.substring(9) : null);    showDialog(      context: context,      builder: (ctx) => AlertDialog(        title: Text(context.tr.ordersTitle),        content: SizedBox(          width: 520,          child: Column(            mainAxisSize: MainAxisSize.min,            children: [                            _detailRow(context.tr.orderId, order.id),
              if (invNum != null) _detailRow(context.tr.invoiceHash, invNum),              _detailRow(context.tr.product, order.productName),              _detailRow(context.tr.sku, order.productSku),              _detailRow(context.tr.quantity, '${order.quantity} ${order.unit}'),              _detailRow(context.tr.logNumber, order.logNumber),              _detailRow(context.tr.categoryId, order.categoryId.toString()),              _detailRow(context.tr.orderType, _typeLabel(order.type)),              _detailRow(context.tr.orderStatus, _statusLabel(order.status)),              if (order.supplier.isNotEmpty) _detailRow(context.tr.supplier, order.supplier),              if (order.recipient.isNotEmpty) _detailRow(context.tr.recipient, order.recipient),              _detailRow(context.tr.createdBy, order.createdBy),              _detailRow(context.tr.date, _formatDateTime(order.createdAt)),              if (expiry != null)                _detailRow(context.tr.expiryDate, _formatRawDate(expiry)),            ],          ),        ),        actions: [          TextButton(            onPressed: () => Navigator.pop(ctx),            child: Text(context.tr.close),          ),        ],      ),    );  }

  Widget _detailCard(String header, List<Widget> children, bool isDark) {    return Container(      padding: const EdgeInsets.all(16),      decoration: BoxDecoration(        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,        borderRadius: BorderRadius.circular(10),        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),      ),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Text(header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),          const SizedBox(height: 10),          ...children,        ],      ),    );  }

  Widget _detailRow2(String label, String value) {    return Padding(      padding: const EdgeInsets.symmetric(vertical: 5),      child: Row(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 13))),        ],      ),    );  }
  Widget _detailRow(String label, String value) {    return Padding(      padding: const EdgeInsets.symmetric(vertical: 7),      child: Row(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          SizedBox(            width: 130,            child: Text(              '$label:',              style: const TextStyle(fontWeight: FontWeight.w600),            ),          ),          Expanded(child: Text(value.isEmpty ? '-' : value)),        ],      ),    );  }


  Future<void> _printOrders() async {    final pdf = pw.Document();    final orders = OrderService.getAllOrders();    final completed = orders        .where((order) => order.status == OrderStatus.completed)        .length;    final pending = orders        .where((order) => order.status == OrderStatus.pending)        .length;    pdf.addPage(      pw.MultiPage(        pageFormat: PdfPageFormat.a4,        build: (_) => [          pw.Text(            context.tr.ordersTitle,            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),          ),          pw.SizedBox(height: 8),          pw.Text('${context.tr.generatedPrefix}${_formatDateTime(DateTime.now())}'),          pw.SizedBox(height: 18),          pw.Text(            '${context.tr.orders}: ${orders.length} | ${context.tr.orderStatusCompleted}: $completed | ${context.tr.orderStatusPending}: $pending',          ),          pw.SizedBox(height: 18),                    pw.Table.fromTextArray(
            headers: [
              context.tr.orderId,
              context.tr.product,
              context.tr.sku,
              context.tr.quantity,
              context.tr.orderType,
              context.tr.orderStatus,
              context.tr.createdBy,
              context.tr.date,
            ],            data: orders                .map(                  (order) => [                    order.id,                    order.productName,                    order.productSku,                    '${order.quantity} ${order.unit}',                    _typeLabel(order.type),                    _statusLabel(order.status),                    order.createdBy,                    _formatDateTime(order.createdAt),                  ],                )                .toList(),            headerStyle: pw.TextStyle(              fontWeight: pw.FontWeight.bold,              fontSize: 9,            ),            cellStyle: const pw.TextStyle(fontSize: 8),            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),          ),        ],      ),    );    if (mounted) _showPrintOptionsDialog(pdf);  }

  void _showPrintOptionsDialog(pw.Document pdf) {    showDialog(      context: context,      builder: (context) => AlertDialog(        title: Text(context.tr.printOrders),        content: Text(context.tr.chooseExportMethod),        actions: [          TextButton.icon(            onPressed: () async {              Navigator.pop(context);              await Printing.layoutPdf(                onLayout: (PdfPageFormat format) async => pdf.save(),              );            },            icon: const Icon(Icons.print),            label: Text(context.tr.print),          ),          TextButton.icon(            onPressed: () async {              Navigator.pop(context);              await Printing.sharePdf(                bytes: await pdf.save(),                filename:                    'orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf',              );            },            icon: const Icon(Icons.share),            label: Text(context.tr.saveOrShare),          ),          TextButton(            onPressed: () => Navigator.pop(context),            child: Text(context.tr.cancel),          ),        ],      ),    );  }

  String _typeLabel(OrderType type) => switch (type) {    OrderType.add => context.tr.orderTypeAdd,    OrderType.export => context.tr.orderTypeExport,    OrderType.edit => context.tr.orderTypeEdit,  };  String _statusLabel(OrderStatus status) => switch (status) {    OrderStatus.completed => context.tr.orderStatusCompleted,    OrderStatus.pending => context.tr.orderStatusPending,    OrderStatus.canceled => context.tr.orderStatusCanceled,  };  String _formatDateTime(DateTime value) {    final local = value.toLocal();    final month = local.month.toString().padLeft(2, '0');    final day = local.day.toString().padLeft(2, '0');    final hour = local.hour.toString().padLeft(2, '0');    final minute = local.minute.toString().padLeft(2, '0');    return '${local.year}-$month-$day $hour:$minute';  }

  String _formatRawDate(String raw) {    final parsed = DateTime.tryParse(raw);    if (parsed == null) return raw;    final month = parsed.month.toString().padLeft(2, '0');    final day = parsed.day.toString().padLeft(2, '0');    return '${parsed.year}-$month-$day';  }}

class OrderCardWidget extends StatefulWidget {
  final OrderModel order;
  final bool isDark;
  final VoidCallback onViewDetails;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.isDark,
    required this.onViewDetails,
    this.onApprove,
    this.onReject,
  });

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(_isHovered ? -2.0 : 0.0, _isHovered ? -1.0 : 0.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? Colors.blueAccent.withOpacity(0.5)
                : (widget.isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.02),
              blurRadius: _isHovered ? 12 : 4,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr.orders} #${widget.order.id}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.order.productName} - ${context.tr.sku}: ${widget.order.productSku}',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.order.quantity} ${widget.order.unit} | ${widget.order.createdBy} | ${_formatDateTime2(widget.order.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            _typeBadge(widget.order.type, context.tr),
            const SizedBox(width: 10),
            _statusBadge(widget.order.status, context.tr),
            if (widget.onApprove != null) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: widget.onApprove,
                icon: const Icon(Icons.check_circle, color: Colors.green),
                tooltip: context.tr.approve,
              ),
              IconButton(
                onPressed: widget.onReject,
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: context.tr.reject,
              ),
            ],
            IconButton(
              onPressed: widget.onViewDetails,
              icon: Icon(
                Icons.visibility,
                color: widget.isDark ? Colors.white70 : Colors.black54,
              ),
              tooltip: context.tr.viewDetailsTooltip,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(OrderType type, AppLocalizations tr) {
    final (label, color) = switch (type) {
      OrderType.add => (tr.orderTypeAdd, Colors.green),
      OrderType.export => (tr.orderTypeExport, Colors.blue),
      OrderType.edit => (tr.orderTypeEdit, Colors.orange),
    };
    return _badge(label, color);
  }

  Widget _statusBadge(OrderStatus status, AppLocalizations tr) {
    final (label, color) = switch (status) {
      OrderStatus.completed => (tr.orderStatusCompleted, const Color(0xFF28A745)),
      OrderStatus.pending => (tr.orderStatusPending, const Color(0xFFFFA500)),
      OrderStatus.canceled => (tr.orderStatusCanceled, const Color(0xFFDC3545)),
    };
    return _badge(label, color);
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDateTime2(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}