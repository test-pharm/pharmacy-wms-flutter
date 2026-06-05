import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/alertService.dart';
import 'package:pharmacy_wms/Services/DashboardService.dart';
import 'package:pharmacy_wms/Services/ApprovalService.dart';
import 'package:pharmacy_wms/Services/orderService.dart';
import 'package:pharmacy_wms/views/UserInfo.dart';
import 'package:pharmacy_wms/widgets/skeletons.dart';
import 'package:pharmacy_wms/widgets/animated_counter.dart';

class DashboardPage extends StatefulWidget {
  final Function(int index, {String? availabilityFilter, int? reportsTab})? onNavigate;
  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _refreshTimer;
  bool _alertsCollapsed = false;
  DateTime _lastSyncedTime = DateTime.now();

  bool _loadingStats = true;
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _stockMovement = [];
  List<Map<String, dynamic>> _topConsumed = [];
  int _pendingApprovalsCount = 0;
  int _dispatchedThisMonthCount = 0;

  String _getTimeOfDayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _getTimeOfDayIcon() {
    final hour = DateTime.now().hour;
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

  @override
  void initState() {
    super.initState();
    NotificationService.changes.addListener(_handleNotificationChange);
    _loadStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final provider = ProductProvider.of(context, listen: false);
      provider.loadProducts();
      _loadStats();
      if (mounted) setState(() => _lastSyncedTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    NotificationService.changes.removeListener(_handleNotificationChange);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleNotificationChange() {
    if (mounted) {
      setState(() {});
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        DashboardService.fetchActivity(limit: 10),
        DashboardService.fetchStockMovement(days: 30),
        DashboardService.fetchTopConsumed(month: now.month, year: now.year),
        if (AuthService.isSupervisor) ApprovalService.fetchPendingApprovals() else Future.value([]),
      ]);

      _recentActivity = results[0] as List<Map<String, dynamic>>;
      _stockMovement = results[1] as List<Map<String, dynamic>>;
      _topConsumed = results[2] as List<Map<String, dynamic>>;

      if (AuthService.isSupervisor) {
        final pendingApprovals = results[3] as List<Map<String, dynamic>>;
        _pendingApprovalsCount = pendingApprovals.length;

        final orders = OrderService.getAllOrders();
        _dispatchedThisMonthCount = orders.where((o) =>
          o.type == OrderType.export &&
          o.status == OrderStatus.completed &&
          o.createdAt.month == now.month &&
          o.createdAt.year == now.year
        ).fold(0, (sum, o) => sum + o.quantity);
      }
    } catch (e) {
      debugPrint("Error loading dashboard stats: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final provider = ProductProvider.of(context);
    final expiringSoonCount = provider.expiringSoonCount;
    final lowStockCount = provider.lowStockCount;
    final criticalAlertsCount = provider.getCriticalAlertsCount();
    final criticalAlerts = AlertService.getCriticalAlerts();
    final unreadNotifications = NotificationService.getUnread();

    final bellCount = unreadNotifications.length + criticalAlertsCount;
    final roleColor = AuthService.isWarehouseManager ? Colors.blue : Colors.green;

    final width = MediaQuery.of(context).size.width;
    final useColumnForCharts = width < 1100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: provider.loading || _loadingStats
          ? const DashboardSkeleton()
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
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
                                backgroundColor: roleColor.withOpacity(0.16),
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
                                      Icon(_getTimeOfDayIcon(), color: Colors.amber, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_getTimeOfDayGreeting()}, ${AuthService.currentUser?.fullName ?? "Guest"}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tr.warehouseOverview,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
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
                                    provider.loadProducts();
                                    _loadStats();
                                    setState(() => _lastSyncedTime = DateTime.now());
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: Text(tr.refresh),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last synced: ${_formatTimeOnly(_lastSyncedTime)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _kpiCard(
                                context,
                                tr.totalMaterials,
                                provider.totalProducts.toString(),
                                icon: Icons.grid_view,
                              ),
                              if (AuthService.isWarehouseManager) ...[
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => widget.onNavigate?.call(3, reportsTab: 2),
                                  child: _kpiCard(
                                    context,
                                    tr.nearingExpiry,
                                    expiringSoonCount.toString(),
                                    icon: Icons.hourglass_bottom,
                                    color: expiringSoonCount > 0 ? Colors.orange : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => widget.onNavigate?.call(1, availabilityFilter: 'Low Stock'),
                                  child: _kpiCard(
                                    context,
                                    tr.lowStockItemsTitle,
                                    lowStockCount.toString(),
                                    icon: Icons.warning_amber_rounded,
                                    color: lowStockCount > 0 ? Colors.yellow[700] : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: _showNotifications,
                                  child: _kpiCard(
                                    context,
                                    tr.criticalAlertsTitle,
                                    criticalAlertsCount.toString(),
                                    icon: Icons.notifications_active,
                                    color: criticalAlertsCount > 0 ? Colors.red : null,
                                  ),
                                ),
                              ] else if (AuthService.isSupervisor) ...[
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => widget.onNavigate?.call(1),
                                  child: _kpiCard(
                                    context,
                                    tr.isArabic ? "طلب موافقة معلق" : "Pending Approvals",
                                    _pendingApprovalsCount.toString(),
                                    icon: Icons.pending_actions,
                                    color: _pendingApprovalsCount > 0 ? Colors.orange : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => widget.onNavigate?.call(2),
                                  child: _kpiCard(
                                    context,
                                    tr.isArabic ? "إجمالي المنصرف" : "Dispatched This Month",
                                    _dispatchedThisMonthCount.toString(),
                                    icon: Icons.trending_up,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: _showNotifications,
                                  child: _kpiCard(
                                    context,
                                    tr.isArabic ? "إشعارات غير مقروءة" : "Unread Notifications",
                                    unreadNotifications.length.toString(),
                                    icon: Icons.mark_chat_unread_outlined,
                                    color: unreadNotifications.isNotEmpty ? Colors.green : null,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (useColumnForCharts) ...[
                          _buildChartContainer(_buildStockMovementChart(context)),
                          const SizedBox(height: 16),
                          _buildChartContainer(_buildTopConsumedChart(context)),
                          const SizedBox(height: 16),
                          _buildChartContainer(Row(
                            children: [
                              Expanded(child: _buildCategoryChart(context, provider.products)),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _chartLegend(context),
                              ),
                            ],
                          )),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: _buildChartContainer(_buildStockMovementChart(context))),
                              const SizedBox(width: 16),
                              Expanded(child: _buildChartContainer(_buildTopConsumedChart(context))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildChartContainer(Row(
                                  children: [
                                    Expanded(child: _buildCategoryChart(context, provider.products)),
                                    const SizedBox(width: 12),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _chartLegend(context),
                                    ),
                                  ],
                                )),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildChartContainer(_buildExpiryTimeline(context, provider.products)),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (useColumnForCharts) ...[
                          _buildChartContainer(_buildExpiryTimeline(context, provider.products)),
                          const SizedBox(height: 16),
                        ],
                        _buildChartContainer(_buildActivityFeed(context)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (AuthService.isWarehouseManager && provider.expiredCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr.isArabic ? "تنظيف المواد المنتهية" : "Expired Materials Cleanup",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tr.isArabic
                                      ? "يوجد ${provider.expiredCount} مواد منتهية الصلاحية تتطلب محضر إتلاف."
                                      : "There are ${provider.expiredCount} expired materials requiring disposal.",
                                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Switch to Inventory Page
                                      widget.onNavigate?.call(1);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    child: Text(tr.isArabic ? "سجل إتلاف الآن" : "Record Disposal Now"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        InkWell(
                          onTap: () => setState(() => _alertsCollapsed = !_alertsCollapsed),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  tr.criticalAlertsTitle,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                if (criticalAlertsCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      criticalAlertsCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: _alertsCollapsed ? -0.25 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: const Icon(Icons.expand_more, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: _alertsCollapsed
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  children: [
                                    if (criticalAlerts.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Theme.of(context).cardColor,
                                        ),
                                        child: Center(
                                          child: Text(tr.noCriticalAlerts),
                                        ),
                                      )
                                    else
                                      ...criticalAlerts.take(5).map((alert) {
                                        final isExpired = alert.alertType == 'expired';
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _alertCard(
                                            context,
                                            alert.material?.name ?? 'Alert',
                                            alert.message,
                                            isExpired ? Icons.error_outline : Icons.warning_amber_rounded,
                                            isExpired ? Colors.redAccent : Colors.orangeAccent,
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChartContainer(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _chartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStockMovementChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiptSpots = _getReceiptSpots();
    final dispatchSpots = _getDispatchSpots();

    double maxVal = 10;
    for (final s in receiptSpots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    for (final s in dispatchSpots) {
      if (s.y > maxVal) maxVal = s.y;
    }
    maxVal = ((maxVal / 10).ceil() * 10).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr.isArabic ? "حركة المخزون (آخر 30 يوم)" : "Stock Movement (Last 30 Days)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Row(
              children: [
                _chartLegendItem(context.tr.isArabic ? "الإضافات" : "Receipts", Colors.green),
                const SizedBox(width: 10),
                _chartLegendItem(context.tr.isArabic ? "الصادرات" : "Dispatches", Colors.blue),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: TextStyle(fontSize: 8, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                  left: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              minX: 0,
              maxX: 29,
              minY: 0,
              maxY: maxVal,
              lineBarsData: [
                LineChartBarData(
                  spots: receiptSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.08),
                  ),
                ),
                LineChartBarData(
                  spots: dispatchSpots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopConsumedChart(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_topConsumed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            context.tr.isArabic ? "لا توجد بيانات صادرات لهذا الشهر" : "No dispatches recorded this month",
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontSize: 12),
          ),
        ),
      );
    }

    final maxQ = _topConsumed.map((e) => (e['totalQuantity'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    final limitMax = (maxQ * 1.2).clamp(10.0, double.infinity).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.isArabic ? "المواد الأكثر استهلاكاً (هذا الشهر)" : "Top 5 Consumed Materials (This Month)",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: limitMax,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final name = _topConsumed[group.x]['productName'] as String;
                    return BarTooltipItem(
                      '$name\n${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    );
                  },
                ),
              ),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: TextStyle(fontSize: 8, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double val, TitleMeta meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < _topConsumed.length) {
                        final name = _topConsumed[idx]['productName'] as String;
                        final display = name.length > 8 ? '${name.substring(0, 7)}..' : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            display,
                            style: TextStyle(fontSize: 8, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(_topConsumed.length, (idx) {
                final qty = (_topConsumed[idx]['totalQuantity'] as num).toDouble();
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: qty,
                      color: Colors.blueAccent,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryTimeline(BuildContext context, List<MaterialModel> products) {
    final now = DateTime.now();
    int thisWeek = 0;
    int thisMonth = 0;
    int nextMonth = 0;

    for (final p in products) {
      for (final b in p.batches) {
        if (b.quantity <= 0) continue;
        final expDate = DateTime.tryParse(b.expiryDate);
        if (expDate == null) continue;

        final diff = expDate.difference(now).inDays;
        if (diff > 0) {
          if (diff <= 7) {
            thisWeek++;
          } else if (diff <= 30) {
            thisMonth++;
          } else if (diff <= 60) {
            nextMonth++;
          }
        }
      }
    }

    final isArabic = context.tr.isArabic;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? "الجدول الزمني لانتهاء الصلاحية" : "Expiry Mini-Timeline",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _expiryTimelineCol(isArabic ? "هذا الأسبوع" : "This Week", thisWeek, Colors.red, Colors.red[50]!),
            _expiryTimelineCol(isArabic ? "هذا الشهر" : "This Month", thisMonth, Colors.orange, Colors.orange[50]!),
            _expiryTimelineCol(isArabic ? "الشهر القادم" : "Next Month", nextMonth, Colors.amber, Colors.amber[50]!),
          ],
        ),
      ],
    );
  }

  Widget _expiryTimelineCol(String title, int count, Color color, Color bg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.12) : bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? color : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_recentActivity.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            context.tr.isArabic ? "لا توجد نشاطات مؤخراً" : "No recent activity found",
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black26, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.isArabic ? "آخر النشاطات" : "Recent Activity Feed",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentActivity.length,
          separatorBuilder: (_, __) => Divider(color: isDark ? Colors.white12 : Colors.black12),
          itemBuilder: (context, idx) {
            final log = _recentActivity[idx];
            final action = log['action'] as String;
            final details = log['details'] as String;
            final user = log['userName'] as String;
            final ts = log['timestamp'] as String;

            IconData icon = Icons.info_outline;
            Color iconColor = Colors.blue;

            if (action.contains('Create') || action.contains('Add')) {
              icon = Icons.add_circle_outline;
              iconColor = Colors.green;
            } else if (action.contains('Delete') || action.contains('Deactivate') || action.contains('Reject')) {
              icon = Icons.remove_circle_outline;
              iconColor = Colors.red;
            } else if (action.contains('Update') || action.contains('Edit')) {
              icon = Icons.edit_outlined;
              iconColor = Colors.orange;
            } else if (action.contains('Approve')) {
              icon = Icons.check_circle_outline;
              iconColor = Colors.teal;
            }

            final parsedTime = DateTime.tryParse(ts)?.toLocal();
            final formattedTime = parsedTime != null
                ? '${parsedTime.month}/${parsedTime.day} ${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}'
                : ts.substring(0, 16);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$user  |  $formattedTime',
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  List<FlSpot> _getReceiptSpots() {
    final Map<String, double> dailyQty = {};
    for (var i = 29; i >= 0; i--) {
      final dateStr = DateTime.now().subtract(Duration(days: i)).toString().substring(0, 10);
      dailyQty[dateStr] = 0;
    }
    for (final m in _stockMovement) {
      if (m['type'] == 'add') {
        final date = m['date'] as String;
        if (dailyQty.containsKey(date)) {
          dailyQty[date] = dailyQty[date]! + (m['totalQuantity'] as num).toDouble();
        }
      }
    }
    final sortedKeys = dailyQty.keys.toList()..sort();
    return List.generate(sortedKeys.length, (idx) {
      return FlSpot(idx.toDouble(), dailyQty[sortedKeys[idx]]!);
    });
  }

  List<FlSpot> _getDispatchSpots() {
    final Map<String, double> dailyQty = {};
    for (var i = 29; i >= 0; i--) {
      final dateStr = DateTime.now().subtract(Duration(days: i)).toString().substring(0, 10);
      dailyQty[dateStr] = 0;
    }
    for (final m in _stockMovement) {
      if (m['type'] == 'export') {
        final date = m['date'] as String;
        if (dailyQty.containsKey(date)) {
          dailyQty[date] = dailyQty[date]! + (m['totalQuantity'] as num).toDouble();
        }
      }
    }
    final sortedKeys = dailyQty.keys.toList()..sort();
    return List.generate(sortedKeys.length, (idx) {
      return FlSpot(idx.toDouble(), dailyQty[sortedKeys[idx]]!);
    });
  }

  List<MapEntry<String, int>> _categoryData(List<MaterialModel> all) {
    final cats = <String, int>{};
    for (final m in all) {
      final c = m.category.isEmpty ? context.tr.uncategorizedLabel : m.category;
      cats[c] = (cats[c] ?? 0) + 1;
    }
    final sorted = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).toList();
  }

  static const _chartColors = [
    Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFFF44336), Color(0xFF00BCD4),
    Color(0xFFFFEB3B), Color(0xFF795548),
  ];

  Widget _buildCategoryChart(BuildContext context, List<MaterialModel> all) {
    final data = _categoryData(all);
    if (data.isEmpty) {
      return Center(
        child: Text(
          context.tr.noData,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black38),
        ),
      );
    }
    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          final pct = data[i].value / all.length * 100;
          return PieChartSectionData(
            value: data[i].value.toDouble(),
            color: _chartColors[i % _chartColors.length],
            radius: 48,
            title: '${pct.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }),
        centerSpaceRadius: 28,
        sectionsSpace: 2,
      ),
    );
  }

  List<Widget> _chartLegend(BuildContext context) {
    final data = _categoryData(ProductProvider.of(context).products);
    return data.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _chartColors[data.indexOf(e) % _chartColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${e.key} (${e.value})',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        )).toList();
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
                colors: [c.withOpacity(0.12), c.withOpacity(0.04)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: c == null ? Theme.of(context).cardColor : null,
        border: c != null ? Border.all(color: c.withOpacity(0.25)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
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

  Widget _alertCard(
    BuildContext context,
    String title,
    String body,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    final notifications = NotificationService.getAll();
    final alerts = AlertService.getCriticalAlerts();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.green),
              const SizedBox(width: 12),
              Text(
                '${tr.notifications} (${NotificationService.getUnread().length + alerts.length})',
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (alerts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        tr.criticalAlertsTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            alert.alertType == 'expired' ? Icons.error : Icons.warning_amber_rounded,
                            color: alert.alertType == 'expired' ? Colors.red : Colors.orange,
                          ),
                          title: Text(alert.material?.name ?? 'Alert'),
                          subtitle: Text(alert.message),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      tr.notifications,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  notifications.isEmpty
                      ? Text(tr.noNotifications)
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                item.isRead ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
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
                ],
              ),
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
                  backgroundColor: roleColor.withOpacity(0.12),
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
                    color: roleColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.3)),
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