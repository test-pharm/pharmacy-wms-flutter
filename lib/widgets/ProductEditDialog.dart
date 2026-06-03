import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Services/ProductService.dart';

class ProductEditDialog extends StatefulWidget {
  final MaterialModel product;
  final ProductProvider provider;
  const ProductEditDialog({super.key, required this.product, required this.provider});
  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _supplierCtrl;
  String _category = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _skuCtrl = TextEditingController(text: widget.product.sku);
    _unitCtrl = TextEditingController(text: widget.product.unit);
    _supplierCtrl = TextEditingController(text: widget.product.supplier);
    _category = widget.product.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _unitCtrl.dispose();
    _supplierCtrl.dispose();
    super.dispose();
  }

  List<String> _getCategories() {
    final cats = <String>{};
    for (final p in widget.provider.products) {
      if (p.category.isNotEmpty) cats.add(p.category);
    }
    final sorted = cats.toList()..sort();
    return sorted;
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.materialNameRequired)));
      return;
    }
    setState(() => _saving = true);
    final body = {
      'materialName': _nameCtrl.text.trim(),
      'materialSKU': _skuCtrl.text.trim(),
      'unit': _unitCtrl.text.trim(),
      'supplier': _supplierCtrl.text.trim(),
      'categoryName': _category,
    };
    try {
      await ProductService.updateProductDetails(widget.product.id, body);
      widget.provider.loadProducts();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final categories = _getCategories();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.editProduct,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: context.tr.materialName, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skuCtrl,
              decoration: InputDecoration(labelText: context.tr.sku, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitCtrl,
              decoration: InputDecoration(labelText: context.tr.unit, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _supplierCtrl,
              decoration: InputDecoration(labelText: context.tr.supplier, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categories.contains(_category) ? _category : null,
              decoration: InputDecoration(labelText: context.tr.category, border: const OutlineInputBorder()),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr.cancel),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
