import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Services/ApprovalService.dart';
import 'package:pharmacy_wms/widgets/toast.dart';

class ExpiryChangeDialog extends StatefulWidget {
  final int batchId;
  final String currentExpiry;
  final String productName;
  const ExpiryChangeDialog({
    super.key,
    required this.batchId,
    required this.currentExpiry,
    required this.productName,
  });
  @override
  State<ExpiryChangeDialog> createState() => _ExpiryChangeDialogState();
}

class _ExpiryChangeDialogState extends State<ExpiryChangeDialog> {
  DateTime? _newExpiry;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _newExpiry = picked);
  }

  Future<void> _submit() async {
    if (_newExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.selectNewExpiry)));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.enterReason)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApprovalService.createExpiryChangeRequest(
        widget.batchId,
        _newExpiry!.toUtc().toIso8601String(),
        _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showToast(context, context.tr.expiryChangeSubmitted, type: ToastType.success);
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

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.requestExpiryChange,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('${context.tr.product}: ${widget.productName}', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('${context.tr.currentExpiry}: ${widget.currentExpiry}',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 18),
            Text(context.tr.newExpiryDate, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _newExpiry != null
                      ? '${_newExpiry!.year}-${_newExpiry!.month.toString().padLeft(2, '0')}-${_newExpiry!.day.toString().padLeft(2, '0')}'
                      : context.tr.tapToPickDate,
                  style: TextStyle(color: _newExpiry != null ? textColor : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.tr.reason, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.tr.whyChangeNeeded,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A3441) : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr.submitRequest),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
