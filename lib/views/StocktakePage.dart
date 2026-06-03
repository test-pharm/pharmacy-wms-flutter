import 'package:flutter/material.dart';

import 'package:pharmacy_wms/Models/ProductProvider.dart';

import 'package:pharmacy_wms/Models/materialModel.dart';

import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:printing/printing.dart';

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

class StocktakePage extends StatefulWidget {
  const StocktakePage({
super.key
});
  @override  State<StocktakePage> createState() => _StocktakePageState();

}
class _StocktakePageState extends State<StocktakePage> {
  @override  Widget build(BuildContext context) {
    final provider = ProductProvider.of(context);
    final products = provider.products.toList();
      final grouped = _groupByCategory(products);
    return Padding(      padding: const EdgeInsets.all(18),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Text(            context.tr.stocktake,            style: Theme.of(context).textTheme.headlineSmall?.copyWith(                  fontWeight: FontWeight.bold,                ),          ),          const SizedBox(height: 6),          Text(            context.tr.stocktakeDesc,            style: TextStyle(              color: Theme.of(context).brightness == Brightness.dark                  ? Colors.white60                  : Colors.black54,              fontSize: 14,            ),          ),          const SizedBox(height: 24),          Expanded(            child: _buildContent(context, products, grouped),          ),        ],      ),    );
  
}
  Widget _buildContent(    BuildContext context,    List<MaterialModel> products,    Map<String, List<MaterialModel>> grouped,  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(      children: [        Container(          width: double.infinity,          padding: const EdgeInsets.all(20),          decoration: BoxDecoration(            color: isDark ? const Color(0xFF1A2F35) : Colors.white,            borderRadius: BorderRadius.circular(12),          ),          child: Row(            children: [              Container(                padding: const EdgeInsets.all(12),                decoration: BoxDecoration(                  color: Colors.blue.withOpacity(0.12),                  borderRadius: BorderRadius.circular(12),                ),                child: const Icon(Icons.inventory, color: Colors.blue, size: 32),              ),              const SizedBox(width: 16),              Expanded(                child: Column(                  crossAxisAlignment: CrossAxisAlignment.start,                  children: [                    Text('${
products.length
} ${
context.tr.totalItems
}',                        style: const TextStyle(                            fontSize: 18, fontWeight: FontWeight.bold)),                    const SizedBox(height: 4),                    Text('${
grouped.length
} ${context.tr.categoriesLabel}',                        style: TextStyle(                            color: isDark ? Colors.white60 : Colors.black54)),                  ],                ),              ),              ElevatedButton.icon(                onPressed: () => _generateStocktakePdf(context, products),                icon: const Icon(Icons.picture_as_pdf),                label: Text(context.tr.generateStocktake),                style: ElevatedButton.styleFrom(                  backgroundColor: const Color(0xFF0A6B6E),                  foregroundColor: Colors.white,                  padding:                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),                ),              ),            ],          ),        ),        const SizedBox(height: 20),        Expanded(          child: ListView(            children: grouped.entries.map((entry) {
              return LocationGroupWidget(location: entry.key, items: entry.value, isDark: isDark, isCategory: true);
            
}).toList(),          ),        ),      ],    );
  
}
  // Replaced by LocationGroupWidget


  Future<void> _generateStocktakePdf(
    BuildContext context,
    List<MaterialModel> products,
  ) async {
    final tr = context.tr;
    try {
      final pdf = pw.Document();
      final isArabic = tr.isArabic;
      final now = DateTime.now();

      final totalUniqueItems = products.length;
      final totalStockVolume = products.fold<int>(0, (sum, p) => sum + p.quantity);
      final expiredCount = products.where((p) => p.batches.any((b) => b.isExpired)).length;
      final lowStockCount = products.where((p) => p.quantity < 20).length;

    final grouped = _groupByCategory(products);
      final sortedLocations = grouped.keys.toList()..sort();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          footer: (pw.Context ctx) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Pharmacy WMS \u2014 Confidential Inventory Ledger',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            );
          },
          build: (pw.Context ctx) {
            return [
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
                decoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0A6B6E), width: 2.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isArabic ? '\u062A\u0642\u0631\u064A\u0631 \u0627\u0644\u062C\u0631\u062F \u0627\u0644\u0634\u0627\u0645\u0644 \u0644\u0644\u0645\u0633\u062A\u0648\u062F\u0639' : 'Master Warehouse Inventory Ledger',
                          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Executive Overview & Granular Stock Report',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Generated: ${now.toString().substring(0, 16)}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'User: ${AuthService.currentUser?.fullName ?? "Supervisor"}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfKpiCard('Total Unique Items', totalUniqueItems.toString(), PdfColors.blue700),
                  _pdfKpiCard('Total Stock Volume', totalStockVolume.toString(), PdfColors.teal700),
                  _pdfKpiCard('Expired Items Alert', expiredCount.toString(), PdfColors.red700),
                  _pdfKpiCard('Low Stock Alerts', lowStockCount.toString(), PdfColors.orange700),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'Detailed Location & Batch Breakdown',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
              ),
              pw.SizedBox(height: 10),

              ...sortedLocations.expand((location) {
                final items = grouped[location]!;
                final label = location.isEmpty ? tr.unspecified : location;

                final List<List<String>> tableData = [];
                int serialNumber = 1;

                for (final product in items) {
                  if (product.batches.isEmpty) {
                    tableData.add([
                      serialNumber.toString(),
                      product.sku,
                      product.name,
                      '- (No Batch)',
                      product.quantity.toString(),
                      product.unit.isEmpty ? '-' : product.unit,
                      _formatExpiry(product.expiryDate),
                      product.createdAt.toString().substring(0, 10),
                    ]);
                    serialNumber++;
                  } else {
                    for (final batch in product.batches) {
                      tableData.add([
                        serialNumber.toString(),
                        product.sku,
                        '${product.name} (Batch)',
                        batch.id.toString(),
                        batch.quantity.toString(),
                        product.unit.isEmpty ? '-' : product.unit,
                        _formatExpiry(batch.expiryDate),
                        batch.receivedDate.toString().substring(0, 10),
                      ]);
                      serialNumber++;
                    }
                  }
                }
                return [
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border(left: pw.BorderSide(color: PdfColor.fromInt(0xFF0A6B6E), width: 3)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Storage Zone: $label',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '${tableData.length} Active Batches Listed',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.Table.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B6E)),
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(25),
                      1: const pw.FixedColumnWidth(80),
                      2: const pw.FixedColumnWidth(170),
                      3: const pw.FixedColumnWidth(55),
                      4: const pw.FixedColumnWidth(50),
                      5: const pw.FixedColumnWidth(40),
                      6: const pw.FixedColumnWidth(70),
                      7: const pw.FixedColumnWidth(75),
                    },
                    headers: [
                      'S/N',
                      tr.sku,
                      'Material Component Name',
                      'Batch ID',
                      'Batch Qty',
                      tr.unit,
                      tr.expiryDate,
                      'Received Date',
                    ],
                    data: tableData,
                  ),
                  pw.SizedBox(height: 10),
                ];
              }),
            ];
          },
        ),
      );

      if (!context.mounted) return;
      _showPrintOptions(context, pdf);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr.errorGeneratingPdf}: $e')),
        );
      }
    }
  }

  static pw.Widget _pdfKpiCard(String label, String value, PdfColor accentColor) {
    return pw.Container(
      width: 160,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: accentColor),
          ),
        ],
      ),
    );
  }

  void _showPrintOptions(BuildContext context, pw.Document pdf) {
    showDialog(      context: context,      builder: (ctx) => AlertDialog(        title: Text(context.tr.stocktakeSheet),        content: Text(context.tr.chooseExportMethod),        actions: [          TextButton.icon(            onPressed: () {
              Navigator.pop(ctx);
              Printing.layoutPdf(                  onLayout: (fmt) async => pdf.save());
            
},            icon: const Icon(Icons.print),            label: Text(context.tr.print),          ),          TextButton.icon(            onPressed: () async {
              Navigator.pop(ctx);
              final bytes = await pdf.save();
              Printing.sharePdf(                bytes: bytes,                filename:                    'stocktake_${
DateTime.now().millisecondsSinceEpoch
}.pdf',              );
            
},            icon: const Icon(Icons.share),            label: Text(context.tr.saveOrShare),          ),          TextButton(            onPressed: () => Navigator.pop(ctx),            child: Text(context.tr.cancel),          ),        ],      ),    );
  
}
  Map<String, List<MaterialModel>> _groupByCategory(      List<MaterialModel> products) {
    final map = <String, List<MaterialModel>>{

};
    for (final p in products) {
      final cat = p.category.isEmpty ? context.tr.uncategorized : p.category;
      map.putIfAbsent(cat, () => []);
      map[cat]!.add(p);
    
}    for (final list in map.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    
}    return map;
  
}

  String _formatExpiry(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${
d.year
}-${
d.month.toString().padLeft(2, '0')
}-${
d.day.toString().padLeft(2, '0')
}';
    
} catch (_) {
      return raw.isEmpty ? '-' : raw;
    
}  
}
}

class LocationGroupWidget extends StatefulWidget {
  final String location;
  final List<MaterialModel> items;
  final bool isDark;
  final bool isCategory;

  const LocationGroupWidget({
    super.key,
    required this.location,
    required this.items,
    required this.isDark,
    this.isCategory = false,
  });

  @override
  State<LocationGroupWidget> createState() => _LocationGroupWidgetState();
}

class _LocationGroupWidgetState extends State<LocationGroupWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final label = widget.location.isEmpty ? tr.unspecified : widget.location;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: widget.isDark ? const Color(0xFF1A2F35) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: (widget.isDark ? Colors.white10 : Colors.black).withOpacity(0.04),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(_expanded ? 0 : 12),
                  bottomRight: Radius.circular(_expanded ? 0 : 12),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.isCategory ? Icons.category_outlined : Icons.location_on_outlined, size: 18, color: widget.isDark ? Colors.white54 : Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.items.length} ${tr.itemsLabel}',
                    style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: widget.isDark ? Colors.white54 : Colors.black54,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: widget.items
                        .map((item) => ListTile(
                              dense: true,
                              title: Text(item.name, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87)),
                              subtitle: Text('${tr.skuPrefix}${item.sku}',
                                  style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black54)),
                              trailing: Text('${tr.qtyPrefix}${item.quantity}',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white70 : Colors.black87)),
                            ))
                        .toList(),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}