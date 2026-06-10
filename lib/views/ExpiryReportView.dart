import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';

class ExpiryReportPage extends StatefulWidget {
  const ExpiryReportPage({super.key});
  @override
  State<ExpiryReportPage> createState() => _ExpiryReportPageState();
}

class _ExpiryReportPageState extends State<ExpiryReportPage> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/Dashboard/expiry-report'), headers: AuthService.authHeaders)
          .timeout(const Duration(seconds: 60));
      final decoded = _decodeBody(response.body);
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> items;
        if (decoded is List) {
          items = decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map && decoded['items'] is List) {
          items = List<Map<String, dynamic>>.from(decoded['items']);
        } else if (decoded is Map && decoded['data'] is List) {
          items = List<Map<String, dynamic>>.from(decoded['data']);
        } else {
          items = [];
        }
        items.sort((a, b) {
          final da = DateTime.tryParse((a['expiryDate'] ?? '').toString());
          final db = DateTime.tryParse((b['expiryDate'] ?? '').toString());
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
        if (!mounted) return;
        setState(() { _items = items; _loading = false; });
      } else {
        throw Exception(_extractError(response.statusCode, decoded));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _expiryStatus(String expiryDate) {
    try {
      final dt = DateTime.parse(expiryDate);
      final days = dt.difference(DateTime.now()).inDays;
      if (days < 0) return 'Expired';
      if (days <= 30) return 'Expiring Soon';
      return 'Valid';
    } catch (_) {
      return 'Unknown';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Expired': return Colors.red;
      case 'Expiring Soon': return Colors.orange;
      case 'Valid': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.isEmpty ? '-' : raw;
    }
  }

  String _localizedStatus(String key) {
    switch (key) {
      case 'Expired': return context.tr.statusExpired;
      case 'Expiring Soon': return context.tr.expiringSoonStatus;
      case 'Valid': return context.tr.valid;
      default: return context.tr.statusUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.tr.expiryReport, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const Spacer(),
              if (_loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _load,
                tooltip: context.tr.refresh,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent(isDark, textColor)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: Text(context.tr.retry)),
          ],
        ),
      );
    }

    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64,
                color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text(context.tr.noExpiryData,
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          columns: [
            DataColumn(label: Text(context.tr.product)),
            DataColumn(label: Text(context.tr.sku)),
            DataColumn(label: Text(context.tr.expiryDate)),
            DataColumn(label: Text(context.tr.quantity), numeric: true),
            DataColumn(label: Text(context.tr.status)),
          ],
          rows: _items!.map((item) {
            final expiryDate = (item['expiryDate'] ?? item['expiry'] ?? '').toString();
            final status = _expiryStatus(expiryDate);
            final statusColor = _statusColor(status);
            return DataRow(
              color: WidgetStatePropertyAll(
                status == 'Expired'
                    ? Colors.red.withOpacity(0.08)
                    : status == 'Expiring Soon'
                        ? Colors.orange.withOpacity(0.08)
                        : null,
              ),
              cells: [
                DataCell(Text((item['productName'] ?? item['materialName'] ?? item['name'] ?? '').toString())),
                DataCell(Text((item['sku'] ?? item['materialSKU'] ?? '').toString())),
                DataCell(Text(_formatDate(expiryDate))),
                DataCell(Text((item['quantity'] ?? 0).toString())),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _localizedStatus(status),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try { return jsonDecode(body); } catch (_) { return body; }
  }

  static String _extractError(int statusCode, dynamic body) {
    final fallback = 'Request failed ($statusCode).';
    if (body is Map<String, dynamic>) {
      return (body['message'] ?? body['error'] ?? body['title'] ?? fallback).toString();
    }
    if (body is String && body.trim().isNotEmpty) return body;
    return fallback;
  }
}
