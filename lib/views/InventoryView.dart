import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/stockBatchModel.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/orderService.dart';
import 'package:pharmacy_wms/Services/MaterialService.dart';
import 'package:pharmacy_wms/widgets/AddMaterialWizard.dart';
import 'package:pharmacy_wms/widgets/DispatchMaterialWizard.dart';
import 'package:pharmacy_wms/widgets/ProductEditDialog.dart';
import 'package:pharmacy_wms/widgets/ExpiryEditDialog.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/widgets/skeletons.dart';
import 'package:pharmacy_wms/widgets/BatchDetailDialog.dart';
import 'package:pharmacy_wms/widgets/empty_state.dart';
import 'package:pharmacy_wms/widgets/toast.dart';

class InventoryPage extends StatefulWidget {
  final String? initialAvailabilityFilter;
  const InventoryPage({super.key, this.initialAvailabilityFilter});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late String _availabilityFilter;

  @override
  void initState() {
    super.initState();
    _availabilityFilter = widget.initialAvailabilityFilter ?? 'All';
  }
  String _categoryFilter = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _currentPage = 0;
  Timer? _debounce;
  static const int _itemsPerPage = 20;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ProductProvider.of(context);
    final filtered = provider.products.where(_matchesFilters).toList();
    if (_sortColumnIndex != null) {
      filtered.sort((a, b) {
        final aVal = _sortValue(a);
        final bVal = _sortValue(b);
        final result = Comparable.compare(aVal, bVal);
        return _sortAscending ? result : -result;
      });
    }

    final totalItems = filtered.length;
    final totalPages = totalItems > 0 ? (totalItems / _itemsPerPage).ceil() : 1;
    if (_currentPage >= totalPages) _currentPage = (totalPages - 1).clamp(0, 999999);
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, totalItems);
    final products = totalItems > 0 ? filtered.sublist(start, end) : filtered;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final ctrl = HardwareKeyboard.instance.isControlPressed;
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyF) {
          _searchFocus.requestFocus();
          return KeyEventResult.handled;
        }
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyN) {
          _openProductDialog(context, provider);
          return KeyEventResult.handled;
        }
        if (ctrl && event.logicalKey == LogicalKeyboardKey.keyE) {
          _openExportDialog(context, provider);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.f5) {
          provider.loadProducts();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildToolbar(context, provider),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: provider.loading
                    ? const InventorySkeleton(key: ValueKey('inventory_loading_state'))
                    : provider.error != null
                        ? _buildErrorState(context, provider)
                        : _buildContent(
                            context,
                            provider,
                            products,
                            totalPages: totalPages,
                            totalItems: totalItems,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ProductProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (mounted) setState(() => _currentPage = 0);
              });
            },
            decoration: InputDecoration(
              hintText: '${context.tr.searchByNameOrSku}  (Ctrl+F)',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availabilityFilter,
              items: [
                DropdownMenuItem(value: 'All', child: Text(context.tr.all)),
                DropdownMenuItem(value: 'Available', child: Text(context.tr.available)),
                DropdownMenuItem(
                  value: 'Unavailable',
                  child: Text(context.tr.unavailable),
                ),
                DropdownMenuItem(
                  value: 'Low Stock',
                  child: Text(context.tr.statusLowStock),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _availabilityFilter = value;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _categoryFilter,
              hint: Text('Category',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : Colors.black54)),
              items: [
                DropdownMenuItem(value: '', child: Text(context.tr.all)),
                ...provider.products
                    .map((p) => p.category)
                    .toSet()
                    .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 13)))),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _categoryFilter = value;
                    _currentPage = 0;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: context.tr.refreshTooltip,
          onPressed: provider.loadProducts,
          icon: const Icon(Icons.refresh),
        ),
        if (AuthService.isWarehouseManager) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openProductDialog(context, provider),
            icon: const Icon(Icons.add),
            label: Text(context.tr.addProduct),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _openExportDialog(context, provider),
            icon: const Icon(Icons.upload_outlined),
            label: Text(context.tr.exportProductBtn),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 52),
          const SizedBox(height: 12),
          Text(
            provider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: provider.loadProducts,
            child: Text(context.tr.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductProvider provider,
    List<MaterialModel> products, {
    required int totalPages,
    required int totalItems,
  }) {
    if (products.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: context.tr.noProductsFiltered,
          subtitle: 'Adjust your filters or add a new product.',
          actionLabel: AuthService.isWarehouseManager ? context.tr.addProduct : null,
          onAction: AuthService.isWarehouseManager
              ? () => _openProductDialog(context, ProductProvider.of(context))
              : null,
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 54,
                        dataRowMinHeight: 62,
                        dataRowMaxHeight: 62,
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          DataColumn(
                            label: Text(context.tr.materialName),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.quantity),
                            numeric: true,
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.unit),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.availabilityColumn),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(
                            label: Text(context.tr.expiryDate),
                            onSort: (colIndex, asc) => setState(() {
                              _sortColumnIndex = colIndex;
                              _sortAscending = asc;
                            }),
                          ),
                          DataColumn(label: Text(context.tr.actions)),
                        ],
                        rows: products.map((product) {
                          final isFullyExpired = product.isFullyExpired;
                          final hasExpired = product.batches.any((b) => b.isExpired);
                          final hasExpiring = product.batches.any((b) => b.isExpiringSoon);
                          final isLowStock = MaterialService.isLowStock(product);
                          final hasWarning = hasExpiring || isLowStock;
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((states) {
                              if (isFullyExpired) {
                                return isDark ? Colors.grey.withOpacity(0.12) : Colors.grey.withOpacity(0.12);
                              }
                              if (states.contains(WidgetState.hovered)) {
                                return isDark
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.blueAccent.withOpacity(0.08);
                              }
                              final idx = products.indexOf(product);
                              if (idx.isOdd) {
                                return isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.grey.withOpacity(0.05);
                              }
                              return null;
                            }),
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isFullyExpired || hasExpired
                                            ? Colors.red
                                            : (hasExpiring || isLowStock ? Colors.orange : Colors.transparent),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (isFullyExpired)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          context.tr.expiredStatus.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else if (hasExpired)
                                      const Tooltip(
                                        message: 'Material has expired batches!',
                                        child: Icon(Icons.dangerous, color: Colors.red, size: 18),
                                      )
                                    else if (isLowStock)
                                      const Tooltip(
                                        message: 'Stock is below low threshold!',
                                        child: Icon(Icons.warning, color: Colors.orange, size: 18),
                                      ),
                                    if (isFullyExpired || hasExpired || isLowStock) const SizedBox(width: 8),
                                    Expanded(child: _productSummary(context, product)),
                                  ],
                                ),
                              ),
                              DataCell(Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_databaseQuantityText(product)),
                                ],
                              )),
                              DataCell(Text(product.unit.isEmpty ? '-' : product.unit)),
                              DataCell(_availabilityChip(context, product.isAvailable)),
                              DataCell((isFullyExpired || hasExpired) && hasWarning
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text(_formatDate(product.expiryDate), style: const TextStyle(color: Colors.red)),
                                    ])
                                  : Text(_formatDate(product.expiryDate))),
                              DataCell(_buildActions(context, provider, product)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _buildPagination(context, totalPages, totalItems),
      ],
    );
  }

  Widget _productSummary(BuildContext context, MaterialModel product) {
    final textColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.black54;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showBatches(context, product),
          child: Text(product.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.blue,
                  color: Colors.blue)),
        ),
        const SizedBox(height: 4),
        Text(
          '${context.tr.skuPrefix}${product.sku}',
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ],
    );
  }

  Widget _availabilityChip(BuildContext context, bool isAvailable) {
    final color = isAvailable ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        isAvailable ? context.tr.available : context.tr.unavailable,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) {
    if (!AuthService.isWarehouseManager) {
      return IconButton(
        tooltip: context.tr.viewDetailsTooltip,
        onPressed: () => _showDetails(context, product),
        icon: const Icon(Icons.visibility_outlined),
      );
    }
    final hasExpired = product.batches.any((b) => b.isExpired);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasExpired)
          IconButton(
            tooltip: 'Dispose Expired Units',
            onPressed: () => _confirmDisposeExpired(context, provider, product),
            icon: const Icon(Icons.delete_sweep_outlined),
            color: Colors.red,
          ),
        IconButton(
          tooltip: context.tr.editProduct,
          onPressed: () => _openProductDialog(context, provider, existingProduct: product),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
    );
  }

  Future<void> _confirmDisposeExpired(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final tr = context.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dispose Expired Units'),
        content: Text('Are you sure you want to remove all expired units for ${product.name}? This action only removes expired batches and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Dispose', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    
    final error = await provider.disposeExpired(product.id);
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Expired units disposed successfully.'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _openProductDialog(
    BuildContext context,
    ProductProvider provider, {
    MaterialModel? existingProduct,
  }) async {
    if (existingProduct != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => ProductEditDialog(product: existingProduct, provider: provider),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => AddMaterialWizard(provider: provider),
    );
  }

  Future<void> _openExportDialog(
    BuildContext context,
    ProductProvider provider,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DispatchMaterialWizard(provider: provider),
    );
  }

  Future<void> _openDisposalDialog(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final tr = context.tr;
    final qtyCtrl = TextEditingController(text: product.quantity.toString());
    final notesCtrl = TextEditingController();
    String selectedMethod = 'Destroyed';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : Colors.black87;
          return AlertDialog(
            title: Text(tr.recordDisposalTitle),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${product.name} (${product.sku})',
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: tr.quantity,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMethod,
                    dropdownColor: isDark ? const Color(0xFF2A3441) : Colors.white,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: tr.disposalMethod,
                      border: const OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Destroyed', child: Text('Destroyed')),
                      DropdownMenuItem(value: 'Returned', child: Text('Returned to Supplier')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedMethod = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                      labelText: tr.notes,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text(tr.cancel),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                        if (qty <= 0 || qty > product.quantity) {
                          showToast(context, tr.exceedsStock, type: ToastType.warning);
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          final createdBy = AuthService.currentUser?.fullName ?? tr.unknownUser;
                          final order = OrderModel(
                            productId: product.id,
                            productName: product.name,
                            productSku: product.sku,
                            quantity: qty,
                            unit: product.unit,
                            logNumber: product.lot,
                            categoryId: product.categoryId,
                            type: OrderType.disposal,
                            status: OrderStatus.completed,
                            supplier: product.supplier,
                            createdBy: createdBy,
                            notes: 'Method: $selectedMethod. Notes: ${notesCtrl.text.trim()}',
                          );
                          await OrderService.addOrder(order);
                          await provider.loadProducts();
                          if (context.mounted) {
                            showToast(context, tr.stockUpdated, type: ToastType.success);
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          showToast(context, e.toString().replaceFirst('Exception: ', ''), type: ToastType.error);
                        } finally {
                          setDialogState(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(tr.recordDisposal, style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExpiryEditDialog(
    BuildContext context,
    MaterialModel product,
  ) async {
    final newExpiry = await showDialog<String>(
      context: context,
      builder: (_) => ExpiryEditDialog(product: product),
    );
    if (newExpiry == null) return;
    final createdBy = AuthService.currentUser?.fullName ?? context.tr.unknownUser;
    OrderService.addOrder(
      OrderModel(
        productId: product.id,
        productName: product.name,
        productSku: product.sku,
        quantity: product.quantity,
        unit: product.unit,
        logNumber: product.lot,
        categoryId: product.categoryId,
        type: OrderType.edit,
        status: OrderStatus.pending,
        createdBy: createdBy,
        notes: newExpiry,
      ),
    );
    NotificationService.addNotification(
      AppNotification(
        title: context.tr.editRequests,
        body: '$createdBy requested expiry change for ${product.name} (${product.sku})',
        materialName: product.name,
        productSku: product.sku,
        proposedExpiry: newExpiry,
        managerName: createdBy,
      ),
    );
    NotificationService.sendEditRequestEmail(
      productName: product.name,
      productSku: product.sku,
      managerName: createdBy,
      newExpiry: _formatDate(newExpiry),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.tr.editRequestSubmitted}\n${context.tr.awaitingApproval}'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductProvider provider,
    MaterialModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr.deleteTitle),
        content: Text(context.tr.deleteConfirmNamed(product.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final productName = product.name;
    final productId = product.id;
    final completer = Completer<bool>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: 0.0),
                duration: const Duration(seconds: 4),
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    backgroundColor: Colors.white24,
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Deleting $productName...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: context.tr.undo.toUpperCase(),
          textColor: Colors.greenAccent,
          onPressed: () {
            completer.complete(true);
          },
        ),
      ),
    );
    final undone = await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 4), () => false),
    ]);
    if (undone || !context.mounted) return;
    final error = await provider.deleteProduct(productId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? context.tr.productDeleted(productName)),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  void _showDetails(BuildContext context, MaterialModel product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white60 : Colors.black54;
    final isArabic = context.tr.isArabic;
    final sortedBatches = List<StockBatch>.from(product.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F7FA),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (product.isAvailable ? Colors.green : Colors.orange).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: product.isAvailable ? Colors.green : Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                          const SizedBox(height: 2),
                          Text('${context.tr.skuPrefix}${product.sku}',
                              style: TextStyle(fontSize: 13, color: mutedColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 280,
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.blue,
                        unselectedLabelColor: mutedColor,
                        indicatorColor: Colors.blue,
                        tabs: [
                          Tab(text: isArabic ? 'تفاصيل' : 'Details'),
                          Tab(text: isArabic ? 'صلاحية' : 'Expiry'),
                          Tab(text: isArabic ? 'الدفعات' : 'Batches'),
                          Tab(text: isArabic ? 'سجل' : 'History'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _detailRow(Icons.category_outlined, context.tr.category,
                                      product.category.isNotEmpty ? product.category : product.categoryId.toString()),
                                  const Divider(height: 20),
                                  _detailRow(Icons.inventory_outlined, context.tr.quantity, '${product.quantity} ${product.unit}'),
                                  const Divider(height: 20),
                                  _detailRow(Icons.qr_code_outlined, context.tr.logNumber, product.lot.isEmpty ? '-' : product.lot),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _detailRow(Icons.business, context.tr.supplier, product.supplier.isEmpty ? '-' : product.supplier),
                                  const Divider(height: 20),
                                  _detailRow(Icons.calendar_today_outlined, context.tr.expiryDate, _formatDate(product.expiryDate)),
                                  const Divider(height: 20),
                                  _detailRow(
                                    Icons.check_circle_outline,
                                    context.tr.status,
                                    product.isAvailable ? context.tr.available : context.tr.unavailable,
                                    valueColor: product.isAvailable ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                            sortedBatches.isEmpty
                                ? Center(child: Text(context.tr.noStockBatches))
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: sortedBatches.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final batch = sortedBatches[index];
                                      final color = batch.isExpired
                                          ? Colors.red
                                          : (batch.isExpiringSoon ? Colors.orange : Colors.green);
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(Icons.circle, color: color, size: 12),
                                        title: Text('${context.tr.batchId}: ${batch.id}'),
                                        subtitle: Text(
                                            '${context.tr.quantity}: ${batch.quantity} | Rec: ${_formatDate(batch.receivedDate)}'),
                                        trailing: Text(
                                          _formatDate(batch.expiryDate),
                                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    },
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history, size: 40, color: mutedColor),
                                    const SizedBox(height: 8),
                                    Text(isArabic ? 'سجل الطلبات قيد التطوير' : 'Order history coming soon',
                                        style: TextStyle(color: mutedColor)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(context.tr.close, style: TextStyle(color: mutedColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBatches(BuildContext context, MaterialModel product) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BatchDetailDialog(product: product),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    final muted = Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54;
    return Row(
      children: [
        Icon(icon, size: 18, color: muted),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text('$label:', style: TextStyle(fontSize: 13, color: muted)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor),
          ),
        ),
      ],
    );
  }

  String _databaseQuantityText(MaterialModel product) {
    return product.quantity.toString();
  }

  bool _matchesFilters(MaterialModel product) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final matchesSearch =
        query.isEmpty || product.name.toLowerCase().contains(query) || product.sku.toLowerCase().contains(query);
    final matchesAvailability = switch (_availabilityFilter) {
      'Available' => product.isAvailable,
      'Unavailable' => !product.isAvailable,
      'Low Stock' => product.quantity < (product.minStockLevel > 0 ? product.minStockLevel : 20),
      _ => true,
    };
    final matchesCategory = _categoryFilter.isEmpty || product.category == _categoryFilter;
    return matchesSearch && matchesAvailability && matchesCategory;
  }

  Widget _buildPagination(BuildContext context, int totalPages, int totalItems) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black54;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            context.tr.noOfItems(totalItems),
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: () => _showShortcutsDialog(context),
            icon: Icon(Icons.keyboard_outlined, size: 16, color: textColor),
            label: Text('Shortcuts', style: TextStyle(fontSize: 12, color: textColor)),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            context.tr.pageOf(_currentPage + 1, totalPages),
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    } catch (_) {
      return raw.isEmpty ? '-' : raw;
    }
  }

  Comparable _sortValue(MaterialModel p) {
    switch (_sortColumnIndex) {
      case 0:
        return p.name.toLowerCase();
      case 1:
        return p.quantity;
      case 2:
        return p.unit.toLowerCase();
      case 3:
        return p.isAvailable ? 1 : 0;
      case 4:
        final dt = DateTime.tryParse(p.expiryDate);
        return dt ?? DateTime(9999);
      default:
        return 0;
    }
  }

  void _showShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.keyboard, color: Colors.blue),
            SizedBox(width: 10),
            Text('Keyboard Command Center'),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ShortcutRow(keys: ['Ctrl', 'F'], action: 'Focus Search Bar'),
              _ShortcutRow(keys: ['Ctrl', 'N'], action: 'Add New Material Wizard'),
              _ShortcutRow(keys: ['Ctrl', 'E'], action: 'Open Dispatch (Export) Wizard'),
              _ShortcutRow(keys: ['F5'], action: 'Refresh Inventory Database'),
              _ShortcutRow(keys: ['Esc'], action: 'Close Dialogs & Popups'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final List<String> keys;
  final String action;

  const _ShortcutRow({required this.keys, required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
          Row(
            children: keys
                .map((key) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1),
                      ),
                      child: Text(key,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
                    ))
                .toList(),
          )
        ],
      ),
    );
  }
}