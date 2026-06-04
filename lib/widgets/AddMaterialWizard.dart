import 'package:flutter/material.dart';

import 'package:pharmacy_wms/Models/ProductProvider.dart';

import 'package:pharmacy_wms/Models/materialModel.dart';

import 'package:pharmacy_wms/Models/orderModel.dart';

import 'package:pharmacy_wms/Models/app_localizations.dart';

import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:pharmacy_wms/Services/orderService.dart';

import 'package:pharmacy_wms/widgets/toast.dart';

class AddMaterialWizard extends StatefulWidget {
  final ProductProvider provider;
  const AddMaterialWizard({
super.key, required this.provider
});
  @override  State<AddMaterialWizard> createState() => _AddMaterialWizardState();

}

class _SessionMaterial {
  final String mode;
  final String? productId;
  final String name;
  final String sku;
  final int quantity;
  final String unit;
  final String logNumber;
  final int categoryId;
  final String expiryDate;
  final Map<String, dynamic> body;
  const _SessionMaterial({
    required this.mode,    this.productId,    required this.name,    required this.sku,    required this.quantity,    required this.unit,    required this.logNumber,    required this.categoryId,    required this.expiryDate,    required this.body,  
});

}
class _AddMaterialWizardState extends State<AddMaterialWizard> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  int? _selectionMode;
  final _invoiceController = TextEditingController();
  final _existingSearchController = TextEditingController();
  final _existingQuantityController = TextEditingController();
  MaterialModel? _selectedExistingProduct;
  String _existingQuery = '';
  DateTime? _existingExpiryDate;
  final _newNameController = TextEditingController();
  final _newSkuController = TextEditingController();
  final _newQuantityController = TextEditingController();
  final _newUnitController = TextEditingController();
  final _supplierController = TextEditingController();
  final _newCategoryController = TextEditingController();
  DateTime? _newExpiryDate;
  final _nameFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _supplierFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final List<_SessionMaterial> _sessionMaterials = [];
  bool _submitted = false;
  bool _saving = false;
  bool _popIntercepted = false;
  bool get _hasSessionItems => _sessionMaterials.isNotEmpty;
  bool get _hasUnsavedChanges {
    if (_sessionMaterials.isNotEmpty) return true;
    if (_invoiceController.text.trim().isNotEmpty) return true;
    if (_supplierController.text.trim().isNotEmpty) return true;
    if (_step == 2 && _selectionMode == 0) {
      if (_existingQuantityController.text.trim().isNotEmpty) return true;
      if (_existingExpiryDate != null) return true;
    
}    if (_step == 2 && _selectionMode == 1) {
      if (_newNameController.text.trim().isNotEmpty) return true;
      if (_newSkuController.text.trim().isNotEmpty) return true;
      if (_newQuantityController.text.trim().isNotEmpty) return true;
      if (_newExpiryDate != null) return true;
    
}    return false;
  
}
  @override  void dispose() {
    _invoiceController.dispose();
    _existingSearchController.dispose();
    _existingQuantityController.dispose();
    _newNameController.dispose();
    _newSkuController.dispose();
    _newQuantityController.dispose();
    _newUnitController.dispose();
    _supplierController.dispose();
    _newCategoryController.dispose();
    _nameFocus.dispose();
    _skuFocus.dispose();
    _unitFocus.dispose();
    _categoryFocus.dispose();
    _supplierFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }


  Future<bool> _maybeDiscard() async {
    if (!_hasUnsavedChanges || _popIntercepted) return true;
    _popIntercepted = true;
    final result = await showDialog<bool>(      context: context,      builder: (ctx) => AlertDialog(        title: Text(context.tr.discardChanges),        content: Text(context.tr.discardChangesMsg),        actions: [          TextButton(            onPressed: () => Navigator.pop(ctx, false),            child: Text(context.tr.cancel),          ),          ElevatedButton(            onPressed: () => Navigator.pop(ctx, true),            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),            child: Text(context.tr.discard, style: const TextStyle(color: Colors.white)),          ),        ],      ),    );
    return result ?? false;
  
}

  void _goToStep(int step) {
    setState(() {
      _submitted = false;
      _step = step;
    
});
  
}

  void _selectMode(int mode) {
    setState(() {
      _selectionMode = mode;
    
});
  
}

  bool _canProceedFromSelection() {
    return _selectionMode != null;
  
}

  void _onNextFromSelection() {
    if (!_canProceedFromSelection()) return;
    _goToStep(2);
  
}

  void _onAddToSession() {
    setState(() {
      _submitted = true;
    
});
    bool ok;
    if (_selectionMode == 0) {
      ok = _addExistingToSession();
    
} else {
      ok = _addNewToSession();
    
}    if (!ok) {
      setState(() => _submitted = false);
    
}  
}

  bool _addExistingToSession() {
    final tr = context.tr;
    final selected = _selectedExistingProduct;
    if (selected == null) {
      _toast(tr.productNotFound, type: ToastType.warning);
      return false;
    
}    if (!_formKey.currentState!.validate()) return false;
    final addedQty = int.tryParse(_existingQuantityController.text.trim()) ?? 0;
    if (addedQty <= 0) return false;
    final product = widget.provider.findById(selected.id) ?? selected;
    final body = product.toApiBody();
    body['quantity'] = product.quantity + addedQty;
    body['supplier'] = _supplierController.text.trim();
    if (_existingExpiryDate != null) {
      body['expiryDate'] = _existingExpiryDate!.toUtc().toIso8601String();
    
}
    setState(() {
      _sessionMaterials.add(_SessionMaterial(        mode: 'existing',        productId: product.id,        name: product.name,        sku: product.sku,        quantity: addedQty,        unit: product.unit,        logNumber: product.lot,        categoryId: product.categoryId,        expiryDate: _existingExpiryDate?.toUtc().toIso8601String() ?? product.expiryDate,        body: body,      ));
      _clearExistingForm();
      _goToStep(1);
    
});
    return true;
  
}

  bool _addNewToSession() {
    final tr = context.tr;
    if (!_formKey.currentState!.validate()) return false;
    final name = _newNameController.text.trim();
    final sku = _newSkuController.text.trim();
    final qty = int.tryParse(_newQuantityController.text.trim()) ?? 0;
    if (qty <= 0 || name.isEmpty || sku.isEmpty) return false;
    if (_newExpiryDate == null) return false;
    final unit = _newUnitController.text.trim();
    final supplier = _supplierController.text.trim();
    final category = _newCategoryController.text.trim();
    final body = <String, dynamic>{
      'materialName': name,      'materialSKU': sku,      'quantity': qty,      'unit': unit,      'logNumber': '',      'expiryDate': _newExpiryDate!.toUtc().toIso8601String(),      'supplier': supplier,      'isAvailable': true,      'categoryId': 0,      'categoryName': category,    
};
    setState(() {
      _sessionMaterials.add(_SessionMaterial(        mode: 'new',        productId: null,        name: name,        sku: sku,        quantity: qty,        unit: unit,        logNumber: '',        categoryId: 0,        expiryDate: _newExpiryDate!.toUtc().toIso8601String(),        body: body,      ));
      _clearNewForm();
      _goToStep(1);
    
});
    return true;
  
}

  void _removeSessionMaterial(int index) {
    setState(() {
      _sessionMaterials.removeAt(index);
    
});
  
}


  Future<void> _finishAndSave() async {
    final tr = context.tr;
    if (_sessionMaterials.isEmpty) return;
    setState(() => _saving = true);
    final invoiceNum = _invoiceController.text.trim();
    String? error;
    for (final sessionItem in _sessionMaterials) {
      if (sessionItem.mode == 'existing') {
        final err = await widget.provider.updateProduct(          sessionItem.productId!,          sessionItem.body,        );
        if (err != null && error == null) error = err;
      
} else {
        final err = await widget.provider.addProduct(sessionItem.body);
        if (err != null && error == null) error = err;
      
}

      final supplier = _supplierController.text.trim();      final order = OrderModel(        productId: sessionItem.productId,        productName: sessionItem.name,        productSku: sessionItem.sku,        quantity: sessionItem.quantity,        unit: sessionItem.unit,        logNumber: sessionItem.logNumber,        categoryId: sessionItem.categoryId,        type: OrderType.add,        status: OrderStatus.completed,        supplier: supplier,        createdBy: AuthService.currentUser?.fullName ?? '',        invoiceNumber: invoiceNum.isNotEmpty ? invoiceNum : null,        expiryDate: sessionItem.expiryDate.isNotEmpty ? sessionItem.expiryDate : null,      );
      OrderService.addOrder(order);
    
}
    setState(() => _saving = false);
    if (error != null) {
      _toast(error, type: ToastType.error);
    
} else {
      _toast(tr.stockUpdated, type: ToastType.success);
    
}    if (mounted) Navigator.of(context).pop(true);
  
}

  void _toast(String message, {ToastType type = ToastType.info}) {
    showToast(context, message, type: type);
  }


  Future<void> _pickDate(bool forExisting) async {
    final initial = forExisting ? _existingExpiryDate : _newExpiryDate;
    final picked = await showDatePicker(      context: context,      initialDate: initial ?? DateTime.now(),      firstDate: DateTime(2020),      lastDate: DateTime(2100),    );
    if (picked != null) {
      setState(() {
        if (forExisting) {
          _existingExpiryDate = picked;
        
} else {
          _newExpiryDate = picked;
        
}      
});
    
}  
}

  void _clearExistingForm() {
    _existingSearchController.clear();
    _existingQuantityController.clear();
    _selectedExistingProduct = null;
    _existingQuery = '';
    _existingExpiryDate = null;
  
}

  void _clearNewForm() {
    _newNameController.clear();
    _newSkuController.clear();
    _newQuantityController.clear();
    _newUnitController.clear();
    _newCategoryController.clear();
    _newExpiryDate = null;
  }

  void _clearExistingSelection() {
    setState(() {
      _selectedExistingProduct = null;
      _existingQuery = '';
      _existingExpiryDate = null;
      _existingSearchController.clear();
      _existingQuantityController.clear();
    
});
  
}

  List<MaterialModel> _matchingExisting() {
    final query = _existingQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return widget.provider.products        .where((p) =>            p.name.toLowerCase().contains(query) ||            p.sku.toLowerCase().contains(query))        .take(6)        .toList();
  
}

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${
date.year
}-$m-$d';
  
}
  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return context.tr.required;
    return null;
  
}
  String? _validatePositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return context.tr.required;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return context.tr.positiveNumber;
    return null;
  
}
  @override  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(      insetPadding: const EdgeInsets.all(24),      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),      child: PopScope(        canPop: false,        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _maybeDiscard();
          if (shouldPop && context.mounted) Navigator.of(context).pop();
        
},        child: Container(          width: 680,          padding: const EdgeInsets.all(24),          child: Form(            key: _formKey,            child: SingleChildScrollView(              child: Column(                mainAxisSize: MainAxisSize.min,                crossAxisAlignment: CrossAxisAlignment.start,                children: [                  _buildHeader(tr, isDark),                  const SizedBox(height: 20),                  _buildStepContent(tr, isDark),                  const SizedBox(height: 20),                  if (_hasSessionItems) ...[                    _buildSessionList(tr, isDark),                    const SizedBox(height: 16),                    _buildFinishButton(tr, isDark),                    const SizedBox(height: 12),                  ],                  _buildActionRow(tr, isDark),                ],              ),            ),          ),        ),      ),    );
  
}
  Widget _buildHeader(AppLocalizations tr, bool isDark) {
    final title = _step == 0        ? tr.invoiceNumber        : _step == 1            ? tr.selectMaterial            : _selectionMode == 0                ? tr.existingStock                : tr.newMaterial;
    final subtitle = _step == 0        ? tr.invoiceInfo        : _step == 1            ? ''            : '';
    return Row(      children: [        Expanded(          child: Column(            crossAxisAlignment: CrossAxisAlignment.start,            children: [              Text(                title,                style: TextStyle(                  fontSize: 22,                  fontWeight: FontWeight.bold,                  color: isDark ? Colors.white : Colors.black,                ),              ),              if (subtitle.isNotEmpty) ...[                const SizedBox(height: 6),                Text(                  subtitle,                  style: TextStyle(                    fontSize: 13,                    color: isDark ? Colors.white60 : Colors.black54,                  ),                ),              ],            ],          ),        ),        IconButton(          onPressed: _saving ? null : () async {
            final shouldPop = await _maybeDiscard();
            if (shouldPop && context.mounted) Navigator.pop(context);
          
},          icon: Icon(Icons.close,              color: isDark ? Colors.white70 : Colors.black54),        ),      ],    );
  
}
  Widget _buildStepContent(AppLocalizations tr, bool isDark) {
    switch (_step) {
      case 0:        return _buildInvoiceStep(tr, isDark);
      case 1:        return _buildSelectionStep(tr, isDark);
      case 2:        if (_selectionMode == 0) {
          return _buildExistingFormStep(tr, isDark);
        
}
        return _buildNewFormStep(tr, isDark);
      default:        return const SizedBox.shrink();
    
}  
}
  Widget _buildInvoiceStep(AppLocalizations tr, bool isDark) {
    return SizedBox(      width: 400,      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Text(            tr.invoiceNumber,            style: TextStyle(              fontSize: 13,              fontWeight: FontWeight.w600,              color: isDark ? Colors.white : Colors.black,            ),          ),          const SizedBox(height: 8),          TextFormField(            controller: _invoiceController,            style: TextStyle(color: isDark ? Colors.white : Colors.black87),            decoration: InputDecoration(              hintText: tr.invoiceNumber,              prefixIcon: const Icon(Icons.description_outlined),              filled: true,              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],              border: OutlineInputBorder(                borderRadius: BorderRadius.circular(12),                borderSide: BorderSide.none,              ),            ),          ),          const SizedBox(height: 20),          _buildFocusField(
            controller: _supplierController,
            focusNode: _supplierFocus,
            label: tr.supplier,
            hintText: tr.hintSupplierExample,
            icon: Icons.business_outlined,
            isDark: isDark,
            textInputAction: TextInputAction.done,
          ),
        ],      ),
    );
  
}
  Widget _buildSelectionStep(AppLocalizations tr, bool isDark) {
    return Column(      crossAxisAlignment: CrossAxisAlignment.start,      children: [        Row(          children: [            Expanded(              child: _buildSelectionCard(                icon: Icons.checklist,                label: tr.existingStock,                description: tr.addToExistingDesc,                color: const Color(0xFF3B82F6),                isDark: isDark,                selected: _selectionMode == 0,                onTap: () => _selectMode(0),              ),            ),            const SizedBox(width: 16),            Expanded(              child: _buildSelectionCard(                icon: Icons.add_box_outlined,                label: tr.newMaterial,                description: tr.addNewDesc,                color: const Color(0xFF22C55E),                isDark: isDark,                selected: _selectionMode == 1,                onTap: () => _selectMode(1),              ),            ),          ],        ),      ],    );
  
}
  Widget _buildSelectionCard({
    required IconData icon,    required String label,    required String description,    required Color color,    required bool isDark,    required bool selected,    required VoidCallback onTap,  
}) {
    return GestureDetector(      onTap: onTap,      child: AnimatedContainer(        duration: const Duration(milliseconds: 200),        padding: const EdgeInsets.all(20),        decoration: BoxDecoration(          color: selected              ? color.withOpacity(0.15)              : isDark                  ? const Color(0xFF2A3441)                  : Colors.grey[100],          borderRadius: BorderRadius.circular(12),          border: Border.all(            color: selected ? color : Colors.transparent,            width: 2,          ),        ),        child: Column(          children: [            Container(              width: 56,              height: 56,              decoration: BoxDecoration(                shape: BoxShape.circle,                color: color.withOpacity(0.2),              ),              child: Icon(icon, color: color, size: 28),            ),            const SizedBox(height: 14),            Text(              label,              style: TextStyle(                fontSize: 15,                fontWeight: FontWeight.bold,                color: isDark ? Colors.white : Colors.black87,              ),              textAlign: TextAlign.center,            ),            const SizedBox(height: 6),            Text(              description,              style: TextStyle(                fontSize: 12,                color: isDark ? Colors.white60 : Colors.black54,              ),              textAlign: TextAlign.center,            ),          ],        ),      ),    );
  
}
  Widget _buildExistingFormStep(AppLocalizations tr, bool isDark) {
    final selected = _selectedExistingProduct != null;
    final results = _matchingExisting();
    return Column(      crossAxisAlignment: CrossAxisAlignment.start,      children: [        Text(          tr.searchByNameOrSku,          style: TextStyle(            fontSize: 13,            fontWeight: FontWeight.w600,            color: isDark ? Colors.white : Colors.black,          ),        ),        const SizedBox(height: 8),        TextFormField(          controller: _existingSearchController,          readOnly: selected,          onChanged: (v) => setState(() => _existingQuery = v),          style: TextStyle(color: isDark ? Colors.white : Colors.black87),          decoration: InputDecoration(            hintText: tr.typeHintSearch,            prefixIcon: const Icon(Icons.search),            suffixIcon: selected ? const Icon(Icons.lock_outline) : null,            filled: true,            fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],            border: OutlineInputBorder(              borderRadius: BorderRadius.circular(12),              borderSide: BorderSide.none,            ),          ),        ),        if (!selected && results.isNotEmpty) ...[          const SizedBox(height: 4),          _existingResultsList(results, isDark),        ],        if (selected) ...[          const SizedBox(height: 8),          Align(            alignment: AlignmentDirectional.centerEnd,            child: TextButton.icon(              onPressed: _clearExistingSelection,              icon: const Icon(Icons.clear, size: 18),              label: Text(tr.clear),            ),          ),        ],        if (selected) ...[          const SizedBox(height: 12),          _buildExistingInfoBox(tr, isDark),        ],        const SizedBox(height: 20),        Wrap(          spacing: 16,          runSpacing: 16,          children: [            _buildField(              controller: _existingQuantityController,              label: tr.quantityToAdd,              hintText: '1',              icon: Icons.inventory_2_outlined,              isDark: isDark,              keyboardType: TextInputType.number,              validator: _validatePositiveInt,              width: 280,            ),            _buildExpiryPicker(              label: tr.expiryDate,              isDark: isDark,              date: _existingExpiryDate,              onTap: () => _pickDate(true),              width: 280,            ),          ],        ),      ],    );
  
}
  Widget _existingResultsList(List<MaterialModel> results, bool isDark) {
    return Container(      width: double.infinity,      constraints: const BoxConstraints(maxHeight: 190),      margin: const EdgeInsets.only(top: 6),      decoration: BoxDecoration(        color: isDark ? const Color(0xFF2A3441) : Colors.grey[100],        borderRadius: BorderRadius.circular(12),      ),      child: ListView.separated(        shrinkWrap: true,        itemCount: results.length,        separatorBuilder: (_, __) => const Divider(height: 1),        itemBuilder: (context, index) {
          final p = results[index];
          return ListTile(            dense: true,            title: Text(p.name),            subtitle: Text(              '${
context.tr.skuPrefix
}${
p.sku
} | Stock: ${
p.quantity
}',            ),            onTap: () => setState(() {
              _selectedExistingProduct = p;
              _existingSearchController.text = '${
p.name
} (${
p.sku
})';
              _existingQuery = '';
            
}),          );
        
},      ),    );
  
}
  Widget _buildExistingInfoBox(AppLocalizations tr, bool isDark) {
    final p = _selectedExistingProduct!;
    return Container(      width: double.infinity,      padding: const EdgeInsets.all(14),      decoration: BoxDecoration(        color: const Color(0xFF3B82F6).withOpacity(0.12),        borderRadius: BorderRadius.circular(12),        border: Border.all(          color: const Color(0xFF3B82F6).withOpacity(0.3),        ),      ),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Text(            tr.currentInfo,            style: const TextStyle(              fontSize: 13,              fontWeight: FontWeight.bold,              color: Color(0xFF3B82F6),            ),          ),          const SizedBox(height: 8),          _infoRow(context.tr.materialName, p.name),          _infoRow(context.tr.sku, p.sku),          _infoRow(context.tr.quantity, p.quantity.toString()),          _infoRow(context.tr.unit, p.unit),          _infoRow(context.tr.supplier, p.supplier),          if (p.expiryDate.isNotEmpty)            _infoRow(context.tr.expiryDate, p.expiryDate),        ],      ),    );
  
}
  Widget _infoRow(String label, String value) {
    return Padding(      padding: const EdgeInsets.only(bottom: 4),      child: Row(        children: [          SizedBox(            width: 68,            child: Text(              '$label:',              style: const TextStyle(                fontSize: 12,                fontWeight: FontWeight.w600,                color: Color(0xFF3B82F6),              ),            ),          ),          Expanded(            child: Text(              value,              style: const TextStyle(                fontSize: 12,                color: Color(0xFF3B82F6),              ),            ),          ),        ],      ),    );
  
}
  Widget _buildNewFormStep(AppLocalizations tr, bool isDark) {
    return Wrap(      spacing: 16,      runSpacing: 16,      children: [
        _buildFocusField(
          controller: _newNameController,
          focusNode: _nameFocus,
          nextFocusNode: _skuFocus,
          label: tr.materialName,
          hintText: tr.hintMaterialName,
          icon: Icons.medication_outlined,
          isDark: isDark,
          textInputAction: TextInputAction.next,
        ),
        _buildFocusField(
          controller: _newSkuController,
          focusNode: _skuFocus,
          nextFocusNode: _unitFocus,
          label: tr.materialSku,
          hintText: tr.skuHint,
          icon: Icons.qr_code_2_outlined,
          isDark: isDark,
          textInputAction: TextInputAction.next,
        ),
        _buildFocusField(
          controller: _newUnitController,
          focusNode: _unitFocus,
          nextFocusNode: _newCategoryController.text.isEmpty ? _categoryFocus : _quantityFocus,
          label: tr.unit,
          hintText: tr.hintUnitExamples,
          icon: Icons.scale_outlined,
          isDark: isDark,
          textInputAction: TextInputAction.next,
        ),
        _buildFocusField(
          controller: _newCategoryController,
          focusNode: _categoryFocus,
          nextFocusNode: _quantityFocus,
          label: tr.category,
          hintText: tr.hintCategoryExample,
          icon: Icons.category_outlined,
          isDark: isDark,
          textInputAction: TextInputAction.next,
        ),
        _buildFocusField(
          controller: _newQuantityController,
          focusNode: _quantityFocus,
          label: tr.quantity,
          hintText: tr.quantityHint,
          icon: Icons.inventory_2_outlined,
          isDark: isDark,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onAddToSession(),
        ),
        _buildExpiryPicker(
          label: tr.expiryDate,
          isDark: isDark,
          date: _newExpiryDate,
          onTap: () => _pickDate(false),
          width: 280,
        ),
      ],
    );
  }
  Widget _buildField({
    required TextEditingController controller,    required String label,    required String hintText,    required IconData icon,    required bool isDark,    double width = 280,    bool readOnly = false,    TextInputType? keyboardType,    String? Function(String?)? validator,    ValueChanged<String>? onChanged,  
}) {
    return SizedBox(      width: width,      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Text(            label,            style: TextStyle(              fontSize: 13,              fontWeight: FontWeight.w600,              color: isDark ? Colors.white : Colors.black,            ),          ),          const SizedBox(height: 8),          TextFormField(            controller: controller,            keyboardType: keyboardType,            readOnly: readOnly,            onChanged: onChanged,            validator: readOnly ? (_) => null : validator ?? _required,            style: TextStyle(color: isDark ? Colors.white : Colors.black87),            decoration: InputDecoration(              hintText: hintText,              prefixIcon: Icon(icon),              suffixIcon: readOnly ? const Icon(Icons.lock_outline) : null,              filled: true,              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],              border: OutlineInputBorder(                borderRadius: BorderRadius.circular(12),                borderSide: BorderSide.none,              ),            ),          ),        ],      ),    );
  }

  Widget _buildFocusField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isDark,
    TextInputAction? textInputAction,
    TextInputType? keyboardType,
    void Function(String)? onFieldSubmitted,
  }) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted ?? (_) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              }
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(icon),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildExpiryPicker({
    required String label,    required bool isDark,    required DateTime? date,    required VoidCallback onTap,    double width = 280,  
}) {
    return SizedBox(      width: width,      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Text(            label,            style: TextStyle(              fontSize: 13,              fontWeight: FontWeight.w600,              color: isDark ? Colors.white : Colors.black,            ),          ),          const SizedBox(height: 8),          InkWell(            onTap: onTap,            borderRadius: BorderRadius.circular(12),            child: InputDecorator(              decoration: InputDecoration(                prefixIcon: const Icon(Icons.calendar_today_outlined),                filled: true,                fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],                border: OutlineInputBorder(                  borderRadius: BorderRadius.circular(12),                  borderSide: BorderSide.none,                ),                                errorText: _submitted && date == null
                    ? context.tr.pleaseSelectDate
                    : null,              ),              child: Text(                date == null                    ? context.tr.selectDate                    : _formatDate(date),                style:                    TextStyle(color: isDark ? Colors.white : Colors.black87),              ),            ),          ),        ],      ),    );
  
}
  Widget _buildSessionList(AppLocalizations tr, bool isDark) {
    return Container(      width: double.infinity,      decoration: BoxDecoration(        color: isDark            ? const Color(0xFF2A3441)            : Colors.grey[50],        borderRadius: BorderRadius.circular(12),        border: Border.all(          color: isDark              ? Colors.white12              : Colors.black12,        ),      ),      child: Column(        crossAxisAlignment: CrossAxisAlignment.start,        children: [          Padding(            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),            child: Row(              children: [                Text(                  tr.materialsAdded,                  style: TextStyle(                    fontSize: 14,                    fontWeight: FontWeight.bold,                    color: isDark ? Colors.white : Colors.black87,                  ),                ),                const SizedBox(width: 8),                Container(                  padding:                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),                  decoration: BoxDecoration(                    color: const Color(0xFF1CA0A5),                    borderRadius: BorderRadius.circular(10),                  ),                  child: Text(                    '${
_sessionMaterials.length
}',                    style: const TextStyle(                      fontSize: 12,                      fontWeight: FontWeight.bold,                      color: Colors.white,                    ),                  ),                ),              ],            ),          ),          const Divider(height: 1),          ListView.separated(            shrinkWrap: true,            physics: const NeverScrollableScrollPhysics(),            itemCount: _sessionMaterials.length,            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),            itemBuilder: (context, index) {
              final item = _sessionMaterials[index];
              final isExisting = item.mode == 'existing';
              return ListTile(                dense: true,                leading: Container(                  width: 36,                  height: 36,                  decoration: BoxDecoration(                    shape: BoxShape.circle,                    color: isExisting                        ? const Color(0xFF3B82F6).withOpacity(0.15)                        : const Color(0xFF22C55E).withOpacity(0.15),                  ),                  child: Icon(                    isExisting ? Icons.checklist : Icons.add_box_outlined,                    size: 18,                    color: isExisting                        ? const Color(0xFF3B82F6)                        : const Color(0xFF22C55E),                  ),                ),                title: Text(                  item.name,                  style: TextStyle(                    fontSize: 14,                    fontWeight: FontWeight.w600,                    color: isDark ? Colors.white : Colors.black87,                  ),                ),                subtitle: Text(                  '${
item.sku
}  \u2022  +${
item.quantity
} ${
item.unit
}',                  style: TextStyle(                    fontSize: 12,                    color: isDark ? Colors.white60 : Colors.black54,                  ),                ),                trailing: IconButton(                  onPressed: () => _removeSessionMaterial(index),                  icon: Icon(                    Icons.remove_circle_outline,                    size: 20,                    color: isDark ? Colors.white54 : Colors.black45,                  ),                ),              );
            
},          ),        ],      ),    );
  
}
  Widget _buildFinishButton(AppLocalizations tr, bool isDark) {
    return SizedBox(      width: double.infinity,      height: 48,      child: ElevatedButton.icon(        onPressed: _saving ? null : _finishAndSave,        icon: _saving            ? const SizedBox(                width: 18,                height: 18,                child: CircularProgressIndicator(                  strokeWidth: 2,                  color: Colors.white,                ),              )            : const Icon(Icons.check_circle_outline),        label: Text(tr.finishSaveAll),        style: ElevatedButton.styleFrom(          backgroundColor: const Color(0xFF22C55E),          foregroundColor: Colors.white,          disabledBackgroundColor: const Color(0xFF22C55E).withOpacity(0.5),          shape: RoundedRectangleBorder(            borderRadius: BorderRadius.circular(12),          ),          textStyle: const TextStyle(            fontSize: 15,            fontWeight: FontWeight.bold,          ),        ),      ),    );
  
}
  Widget _buildActionRow(AppLocalizations tr, bool isDark) {
    final isLastStep = _step == 2;
    return Row(      children: [        if (_step > 0)          TextButton.icon(            onPressed: () => _goToStep(_step - 1),            icon: Icon(context.backIcon, size: 18),            label: Text(tr.back),          )        else          const SizedBox(width: 1),        const Spacer(),        TextButton(          onPressed: () async {
            final shouldPop = await _maybeDiscard();
            if (shouldPop && context.mounted) Navigator.pop(context);
          
},          child: Text(tr.cancel),        ),        const SizedBox(width: 12),        if (isLastStep)          ElevatedButton.icon(            onPressed: _submitted ? null : _onAddToSession,            icon: const Icon(Icons.add, size: 18),            label: Text(tr.add),            style: ElevatedButton.styleFrom(              backgroundColor: const Color(0xFF1CA0A5),              foregroundColor: Colors.white,              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),              shape: RoundedRectangleBorder(                borderRadius: BorderRadius.circular(12),              ),            ),          )        else          ElevatedButton.icon(            onPressed: _step == 1 && !_canProceedFromSelection()                ? null                : () {
                    if (_step == 1) {
                      _onNextFromSelection();
                    
} else {
                      _goToStep(_step + 1);
                    
}                  
},            icon: Icon(context.forwardIcon, size: 18),            label: Text(tr.save),            style: ElevatedButton.styleFrom(              backgroundColor: const Color(0xFF1CA0A5),              foregroundColor: Colors.white,              disabledBackgroundColor: const Color(0xFF1CA0A5).withOpacity(0.4),              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),              shape: RoundedRectangleBorder(                borderRadius: BorderRadius.circular(12),              ),            ),          ),      ],    );
  
}
}
