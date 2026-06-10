import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/alertModel.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/alertService.dart';
import 'package:pharmacy_wms/Services/ApprovalService.dart';
import 'package:pharmacy_wms/widgets/AddMaterialWizard.dart';
import 'package:pharmacy_wms/widgets/DispatchMaterialWizard.dart';
import 'package:pharmacy_wms/views/UserInfo.dart';
import 'package:pharmacy_wms/widgets/skeletons.dart';
import 'package:pharmacy_wms/widgets/animated_counter.dart';

class DashboardPage extends StatefulWidget {
  final Function(int index, {String? availabilityFilter, int? reportsTab, String? operationFilter})? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _refreshTimer;
  Timer? _clockTimer;
  bool _alertsCollapsed = false;
  DateTime _lastSyncedTime = DateTime.now();
  DateTime _currentTime = DateTime.now();
  List<Map<String, dynamic>> _pendingApprovals = [];

  String _getTimeOfDayGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getTimeOfDayIcon() {
    final hour = _currentTime.hour;
    if (hour < 12) return Icons.light_mode;
    if (hour < 17) return Icons.wb_twilight;
    return Icons.dark_mode;
  }

  String _formatTimeOnly(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatFullDateTime(DateTime time) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[time.weekday % 7]}, ${months[time.month - 1]} ${time.day} ${time.year}';
  }

  @override
  void initState() {
    super.initState();
    NotificationService.changes.addListener(_handleNotificationChange);
    _fetchDashboardData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchDashboardData();
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _fetchDashboardData() async {
    final provider = ProductProvider.of(context, listen: false);
    await provider.loadProducts();
    
    if (AuthService.isWarehouseManager) {
      try {
        final approvals = await ApprovalService.fetchPendingApprovals();
        if (mounted) setState(() => _pendingApprovals = approvals);
      } catch (e) {
        debugPrint('[Dashboard] Failed to fetch approvals: $e');
      }
    }
    
    if (mounted) setState(() => _lastSyncedTime = DateTime.now());
  }

  @override
  void dispose() {
    NotificationService.changes.removeListener(_handleNotificationChange);
    _refreshTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final provider = ProductProvider.of(context);
    final expiringSoonCount = provider.expiringSoonCount;
    final lowStockCount = provider.lowStockCount;
    final criticalAlertsCount = provider.getCriticalAlertsCount();
    
    final bellCount = AuthService.isWarehouseManager
        ? _pendingApprovals.length
        : criticalAlertsCount;
    final roleColor = AuthService.isWarehouseManager ? Colors.blue : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: provider.loading
          ? const DashboardSkeleton()
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: _showNotifications,
                                  icon: const Icon(Icons.notifications_none),
                                ),
                                if (bellCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        bellCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showProfilePopup,
                              child: CircleAvatar(
                                backgroundColor: roleColor.withValues(alpha: 0.16),
                                child: Text(
                                  _profileInitial(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(_getTimeOfDayIcon(), color: Colors.amber, size: 26),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_getTimeOfDayGreeting()}, ${AuthService.currentUser?.fullName.split(' ').first ?? "Guest"}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatFullDateTime(_currentTime),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _fetchDashboardData();
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: Text(tr.refresh),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).cardColor,
                                    foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Theme.of(context).dividerColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Last synced: ${_formatTimeOnly(_lastSyncedTime)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildStockHealth(context, provider),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            InkWell(
                              onTap: () => widget.onNavigate?.call(AuthService.isSupervisor ? 4 : 1),
                              child: _kpiCard(
                                context,
                                tr.totalMaterials,
                                provider.totalProducts.toString(),
                                icon: Icons.grid_view,
                                color: Colors.blue,
                              ),
                            ),
                            InkWell(
                              onTap: () => widget.onNavigate?.call(AuthService.isSupervisor ? 2 : 3, reportsTab: 2),
                              child: _kpiCard(
                                context,
                                tr.nearingExpiry,
                                expiringSoonCount.toString(),
                                icon: Icons.hourglass_bottom,
                                color: Colors.orange,
                              ),
                            ),
                            InkWell(
                              onTap: () => widget.onNavigate?.call(AuthService.isSupervisor ? 4 : 1, availabilityFilter: 'Low Stock'),
                              child: _kpiCard(
                                context,
                                tr.lowStockItemsTitle,
                                lowStockCount.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: Colors.amber[700],
                              ),
                            ),
                            InkWell(
                              onTap: _showNotifications,
                              child: _kpiCard(
                                context,
                                tr.criticalAlertsTitle,
                                criticalAlertsCount.toString(),
                                icon: Icons.notifications_active,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (AuthService.isWarehouseManager) ...[
                              Expanded(
                                flex: 2,
                                child: _buildPendingApprovals(context),
                              ),
                              const SizedBox(width: 24),
                            ],
                            Expanded(
                              flex: 3,
                              child: _buildCriticalShortages(context, provider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSystemFeed(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context) {
    final tr = context.tr;
    final pendingCount = _pendingApprovals.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_ind, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                tr.pendingApprovalsTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (pendingCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(tr.noPendingApprovals, style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            Column(
              children: [
                ..._pendingApprovals.take(3).map((req) {
                  final batch = req['batch'] as Map<String, dynamic>?;
                  final product = batch?['product'] as Map<String, dynamic>?;
                  final productName = (product?['materialName'] ?? req['productName'] ?? 'Unknown').toString();
                  final date = DateTime.tryParse(req['requestedAt']?.toString() ?? '') ?? DateTime.now();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Requested: ${_formatTimeOnly(date)}'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        widget.onNavigate?.call(
                          AuthService.isSupervisor ? 1 : 4,
                          operationFilter: 'Edit',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: Text(tr.viewDetailsTooltip),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => widget.onNavigate?.call(
                    AuthService.isSupervisor ? 1 : 4,
                    operationFilter: 'Edit',
                  ),
                  child: Text(tr.viewAllApprovals),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCriticalShortages(BuildContext context, ProductProvider provider) {
    final tr = context.tr;
    final criticalItems = provider.products.where((p) {
      final isExpired = p.batches.any((b) => b.isExpired);
      final isSeverelyLow = p.quantity < (p.minStockLevel > 0 ? p.minStockLevel / 2 : 5);
      return isExpired || isSeverelyLow;
    }).take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.report_problem, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                tr.criticalShortages,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr.urgentActionDesc,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (criticalItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(tr.noData, style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: IntrinsicColumnWidth(),
                2: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    Text(tr.materialName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(tr.issue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    const SizedBox.shrink(), // Action column
                  ],
                ),
                for (final item in criticalItems)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
                        child: Text(
                          item.batches.any((b) => b.isExpired) ? tr.statusExpired : tr.lowStock,
                          style: TextStyle(
                            color: item.batches.any((b) => b.isExpired) ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: item.batches.any((b) => b.isExpired)
                              ? TextButton(
                                  onPressed: () => widget.onNavigate?.call(AuthService.isSupervisor ? 4 : 1),
                                  child: Text(tr.disposeAction),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSystemFeed(BuildContext context) {
    final tr = context.tr;
    final alerts = AlertService.getCriticalAlerts().take(3).toList();
    final notifs = NotificationService.getAll().take(2).toList();
    final combined = [...alerts, ...notifs];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                tr.systemFeed,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (combined.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(tr.noData, style: TextStyle(color: Colors.grey[500])),
              ),
            )
          else
            ...combined.map((item) {
              IconData icon;
              Color iconColor;
              String title;
              String timeStr;

              if (item is AlertModel) {
                icon = Icons.warning_amber_rounded;
                iconColor = Colors.orange;
                title = 'Alert: ${item.message}';
                timeStr = _formatTimeOnly(DateTime.now().subtract(const Duration(minutes: 15)));
              } else if (item is AppNotification) {
                icon = Icons.info_outline;
                iconColor = Colors.blue;
                title = 'System: ${item.title}';
                timeStr = _formatTimeOnly(item.createdAt);
              } else {
                return const SizedBox.shrink();
              }

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.1),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.quickActions,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (!AuthService.isSupervisor)
              ActionChip(
                avatar: const Icon(Icons.add_box, size: 18),
                label: Text(tr.receiveStock),
                onPressed: () => widget.onNavigate?.call(4),
              ),
            if (!AuthService.isSupervisor)
              ActionChip(
                avatar: const Icon(Icons.local_shipping, size: 18),
                label: Text(tr.dispatch),
                onPressed: () => widget.onNavigate?.call(4),
              ),
            ActionChip(
              avatar: const Icon(Icons.search, size: 18),
              label: Text(tr.quickSearch),
              onPressed: () => widget.onNavigate?.call(AuthService.isSupervisor ? 4 : 1),
            ),
            if (!AuthService.isSupervisor)
              ActionChip(
                avatar: const Icon(Icons.assignment_turned_in, size: 18),
                label: Text(tr.performStocktake),
                onPressed: () => widget.onNavigate?.call(2),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockHealth(BuildContext context, ProductProvider provider) {
    final tr = context.tr;
    final total = provider.totalProducts;
    if (total == 0) return const SizedBox.shrink();

    final lowStock = provider.lowStockCount;
    final expired = provider.expiredCount;
    final healthy = total - lowStock - expired;

    final double healthyPct = (healthy / total).clamp(0.0, 1.0);
    final double lowPct = (lowStock / total).clamp(0.0, 1.0);
    final double expiredPct = (expired / total).clamp(0.0, 1.0);

    String healthStatus;
    Color healthColor;
    IconData healthIcon;

    if (healthyPct > 0.8) {
      healthStatus = tr.stockHealthHealthy;
      healthColor = Colors.green;
      healthIcon = Icons.check_circle_outline;
    } else if (lowPct > 0.3) {
      healthStatus = tr.stockHealthWarning;
      healthColor = Colors.orange;
      healthIcon = Icons.warning_amber_rounded;
    } else {
      healthStatus = tr.stockHealthCritical;
      healthColor = Colors.red;
      healthIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr.stockHealth,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Icon(healthIcon, color: healthColor, size: 20),
              const SizedBox(width: 6),
              Text(
                healthStatus,
                style: TextStyle(color: healthColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (healthyPct > 0)
                  Expanded(
                    flex: (healthyPct * 100).toInt(),
                    child: Tooltip(
                      message: '${tr.healthy} (${(healthyPct * 100).toStringAsFixed(0)}%)',
                      child: Container(
                        height: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
                if (lowPct > 0)
                  Expanded(
                    flex: (lowPct * 100).toInt(),
                    child: Tooltip(
                      message: '${tr.lowStock} (${(lowPct * 100).toStringAsFixed(0)}%)',
                      child: Container(
                        height: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                if (expiredPct > 0)
                  Expanded(
                    flex: (expiredPct * 100).toInt(),
                    child: Tooltip(
                      message: '${tr.outOfStockStatus} (${(expiredPct * 100).toStringAsFixed(0)}%)',
                      child: Container(
                        height: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context,
    String title,
    String value, {
    required IconData icon,
    Color? color,
  }) {
    final c = color;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: c != null
            ? LinearGradient(
                colors: [c.withValues(alpha: 0.12), c.withValues(alpha: 0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: c == null ? Theme.of(context).cardColor : null,
        border: c != null ? Border.all(color: c.withValues(alpha: 0.25)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedCounter(
            value: int.tryParse(value) ?? 0,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _profileInitial() {
    final name = AuthService.currentUser?.fullName.trim() ?? '';
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  void _showNotifications() {
    final tr = context.tr;
    if (AuthService.isSupervisor) {
      final notifications = NotificationService.getAll();
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  '${tr.notifications} (${NotificationService.getUnread().length})',
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: notifications.isEmpty
                  ? Text(tr.noNotifications)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return ListTile(
                          leading: Icon(
                            item.isRead
                                ? Icons.mark_email_read_outlined
                                : Icons.mark_email_unread_outlined,
                            color: item.isRead ? Colors.grey : Colors.green,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.body}\n${item.createdAt.toLocal().toString().substring(0, 16)}',
                          ),
                          isThreeLine: true,
                          trailing: item.isRead
                              ? null
                              : TextButton(
                                  onPressed: () {
                                    NotificationService.markRead(item.id);
                                    setState(() {});
                                    setDialogState(() {});
                                  },
                                  child: Text(tr.markRead),
                                ),
                        );
                      },
                    ),
            ),
            actions: [
              if (notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: () {
                    NotificationService.markAllRead();
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text(tr.markAllRead),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr.close),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final alerts = AlertService.getCriticalAlerts();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.red),
            const SizedBox(width: 12),
            Text('${tr.notifications} (${alerts.length})'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: alerts.isEmpty
              ? Text(tr.noActiveNotifications)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return ListTile(
                      leading: Icon(
                        alert.alertType == 'expired'
                            ? Icons.error
                            : Icons.warning_amber_rounded,
                        color: alert.alertType == 'expired'
                            ? Colors.red
                            : alert.alertType == 'expiring_soon'
                                ? Colors.orange
                                : Colors.blue,
                      ),
                      title: Text(alert.material?.name ?? 'Alert'),
                      subtitle: Text(alert.message),
                    );
                  },
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

  void _showProfilePopup() {
    final tr = context.tr;
    final user = AuthService.currentUser;
    final isManager = AuthService.isWarehouseManager;
    final roleColor = isManager ? Colors.blue : Colors.green;
    final roleText = isManager ? tr.warehouseManager : tr.supervisor;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        alignment: AlignmentDirectional.topEnd,
        insetPadding: const EdgeInsets.only(top: 72, right: 36),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: roleColor.withValues(alpha: 0.12),
                  child: Text(
                    _profileInitial(),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? tr.unknownUser,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserInfoPage(showBackButton: true),
                        ),
                      );
                    },
                    child: Text(tr.more),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
