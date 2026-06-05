import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Services/ProductService.dart';
import 'package:pharmacy_wms/Services/CategoryService.dart';
import 'package:pharmacy_wms/Services/ContactService.dart';

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
  late TextEditingController _minStockCtrl;
  int? _selectedCategoryId;
  bool _saving = false;

  List<Map<String, dynamic>> _categories = [];
  List<Contact> _suppliers = [];

  final FocusNode _supplierFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _skuCtrl = TextEditingController(text: widget.product.sku);
    _unitCtrl = TextEditingController(text: widget.product.unit);
    _supplierCtrl = TextEditingController(text: widget.product.supplier);
    _minStockCtrl = TextEditingController(
      text: widget.product.minStockLevel > 0 ? widget.product.minStockLevel.toString() : '',
    );
    _selectedCategoryId = widget.product.categoryId > 0 ? widget.product.categoryId : null;
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _unitCtrl.dispose();
    _supplierCtrl.dispose();
    _minStockCtrl.dispose();
    _supplierFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final cats = await CategoryService.getCategories();
      final sups = await ContactService.getContacts(type: 'Supplier');
      setState(() {
        _categories = cats;
        _suppliers = sups;
      });
    } catch (_) {}
  }

  Future<void> _createNewCategoryInline() async {
    final tr = context.tr;
    final ctrl = TextEditingController();
    bool saving = false;
    final newCat = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr.createCategory),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: tr.categoryName,
              hintText: tr.categoryName,
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
                      final name = ctrl.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        final result = await CategoryService.createCategory(name);
                        if (context.mounted) Navigator.pop(ctx, result);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                        );
                      } finally {
                        setDialogState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1CA0A5)),
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tr.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (newCat != null) {
      await _loadInitialData();
      setState(() {
        _selectedCategoryId = newCat['id'] as int;
      });
    }
  }

  Future<void> _createNewSupplierInline(String prefilledName, Function(Contact) onCreated) async {
    final tr = context.tr;
    final nameCtrl = TextEditingController(text: prefilledName);
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool saving = false;
    final newContact = await showDialog<Contact>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tr.createContact),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: tr.contactName,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: tr.phoneNumber,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: tr.notes,
                ),
              ),
            ],
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
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        final result = await ContactService.createContact(
                          name: name,
                          type: 'Supplier',
                          phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );
                        if (context.mounted) Navigator.pop(ctx, result);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                        );
                      } finally {
                        setDialogState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1CA0A5)),
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(tr.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (newContact != null) {
      await _loadInitialData();
      onCreated(newContact);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.materialNameRequired)));
      return;
    }
    setState(() => _saving = true);
    final categoryId = _selectedCategoryId ?? 0;
    final minStock = int.tryParse(_minStockCtrl.text.trim()) ?? 0;
    final body = {
      'materialName': _nameCtrl.text.trim(),
      'materialSKU': _skuCtrl.text.trim(),
      'unit': _unitCtrl.text.trim(),
      'supplier': _supplierCtrl.text.trim(),
      'categoryId': categoryId,
      'minStockLevel': minStock,
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
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.editProduct,
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
                decoration: InputDecoration(labelText: tr.materialName, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _skuCtrl,
                decoration: InputDecoration(labelText: tr.sku, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _unitCtrl,
                decoration: InputDecoration(labelText: tr.unit, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<Contact>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.toLowerCase();
                      if (query.isEmpty) {
                        return _suppliers;
                      }
                      return _suppliers.where((c) => c.name.toLowerCase().contains(query));
                    },
                    displayStringForOption: (Contact option) => option.name,
                    fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                      if (_supplierCtrl.text != textController.text && _supplierCtrl.text.isNotEmpty && textController.text.isEmpty) {
                        textController.text = _supplierCtrl.text;
                      }
                      textController.addListener(() {
                        _supplierCtrl.text = textController.text;
                      });
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: tr.supplier,
                          border: const OutlineInputBorder(),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? const Color(0xFF2A3441) : Colors.white,
                          child: Container(
                            width: constraints.maxWidth,
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final Contact option = options.elementAt(index);
                                      return InkWell(
                                        onTap: () => onSelected(option),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Text(
                                            option.name,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const Divider(height: 1),
                                InkWell(
                                  onTap: () {
                                    _createNewSupplierInline(_supplierCtrl.text, (newContact) {
                                      onSelected(newContact);
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Text(
                                      tr.createNewContact,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                dropdownColor: isDark ? const Color(0xFF2A3441) : Colors.white,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: tr.category,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  ..._categories.map((c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['name'] as String),
                      )),
                  DropdownMenuItem<int>(
                    value: -1,
                    child: Text(
                      tr.createNewCategory,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == -1) {
                    _createNewCategoryInline();
                  } else {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minStockCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr.minStockLevelLabel,
                  hintText: tr.enterMinStockLevel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(tr.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
