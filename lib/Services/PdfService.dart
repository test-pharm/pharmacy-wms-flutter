import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';

class PdfService {
  static Future<pw.ThemeData> getTheme() async {
    final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttfRegular = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontBoldData);
    return pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
    );
  }

  static pw.Widget buildHeader(pw.MemoryImage logoImage, String docTitle, AppLocalizations tr, {String? subtitle}) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0A6B6E), width: 2.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logoImage, width: 45, height: 45),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tr.isArabic ? "جامعة 6 أكتوبر" : "October 6 University",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
                  ),
                  pw.Text(
                    tr.isArabic ? "كلية الصيدلة - مستودع المواد" : "Faculty of Pharmacy - WMS",
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                docTitle,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
              ),
              if (subtitle != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget buildFooter(pw.Context ctx, AppLocalizations tr) {
    final now = DateTime.now().toString().substring(0, 16);
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 15),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            tr.isArabic ? "نظام إدارة مستودع الصيدلية \u2014 وثيقة رسمية" : "Pharmacy WMS \u2014 Official Document",
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
          ),
          pw.Text(
            '${tr.isArabic ? "تم الإنشاء: " : "Generated: "}$now  |  ${tr.isArabic ? "صفحة" : "Page"} ${ctx.pageNumber} ${tr.isArabic ? "من" : "of"} ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _styledCell(String text, {bool isHeader = false, PdfColor? bgColor, PdfColor? textColor, double fontSize = 9, pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      color: bgColor,
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: fontSize,
          color: textColor ?? (isHeader ? PdfColors.white : PdfColors.black),
        ),
      ),
    );
  }

  static pw.Widget _pdfKpiCard(String label, String value, PdfColor accentColor) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(8),
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
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: accentColor),
          ),
        ],
      ),
    );
  }

  // 1. Inventory Report PDF
  static Future<pw.Document> generateInventoryReport(
    List<MaterialModel> products,
    AppLocalizations tr,
    int lowStockCount,
    int expiringSoonCount,
    int criticalCount,
  ) async {
    final pdf = pw.Document(theme: await getTheme());
    final logoData = await rootBundle.load('assets/pharmacy faculty logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final statusMap = <String, String>{
      'Good': tr.statusGood,
      'Expiring Soon': tr.statusExpiringSoon,
      'Expired': tr.statusExpired,
      'Low Stock': tr.statusLowStock,
    };

    final statusColors = <String, PdfColor>{
      'Good': PdfColors.green100,
      'Expiring Soon': PdfColors.orange100,
      'Expired': PdfColors.red100,
      'Low Stock': PdfColors.amber100,
    };

    final statusTextColors = <String, PdfColor>{
      'Good': PdfColors.green900,
      'Expiring Soon': PdfColors.orange900,
      'Expired': PdfColors.red900,
      'Low Stock': PdfColors.amber900,
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.SizedBox.shrink(), // Headers handled inside build
        footer: (ctx) => buildFooter(ctx, tr),
        build: (pw.Context ctx) {
          final tableRows = <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B6E)),
              children: [
                _styledCell(tr.materialName, isHeader: true),
                _styledCell(tr.category, isHeader: true),
                _styledCell(tr.sku, isHeader: true),
                _styledCell(tr.quantity, isHeader: true, alignment: pw.Alignment.centerRight),
                _styledCell(tr.expiryDate, isHeader: true),
                _styledCell(tr.status, isHeader: true),
              ],
            ),
          ];

          for (final m in products) {
            // Determine status
            String status = 'Good';
            if (m.isFullyExpired) {
              status = 'Expired';
            } else if (m.batches.any((b) => b.isExpiringSoon)) {
              status = 'Expiring Soon';
            } else if (m.quantity < (m.minStockLevel > 0 ? m.minStockLevel : 20)) {
              status = 'Low Stock';
            }

            final displayStatus = statusMap[status] ?? status;
            final cellBg = statusColors[status] ?? PdfColors.white;
            final cellText = statusTextColors[status] ?? PdfColors.black;

            tableRows.add(
              pw.TableRow(
                children: [
                  _styledCell(m.name),
                  _styledCell(m.category.isEmpty ? tr.uncategorized : m.category),
                  _styledCell(m.sku),
                  _styledCell(m.quantity.toString(), alignment: pw.Alignment.centerRight),
                  _styledCell(m.expiryDate.substring(0, 10)),
                  _styledCell(displayStatus, bgColor: cellBg, textColor: cellText),
                ],
              ),
            );
          }

          return [
            pw.Directionality(
              textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(logoImage, tr.reportsTitle, tr, subtitle: tr.inventoryTitle),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _pdfKpiCard(tr.totalMaterials, products.length.toString(), PdfColors.teal800),
                      _pdfKpiCard(tr.statusLowStock, lowStockCount.toString(), PdfColors.amber800),
                      _pdfKpiCard(tr.statusExpiringSoon, expiringSoonCount.toString(), PdfColors.orange800),
                      _pdfKpiCard(tr.criticalAlertsTitle, criticalCount.toString(), PdfColors.red800),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    tr.inventoryTitle,
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.0),
                      1: const pw.FlexColumnWidth(2.0),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.0),
                      4: const pw.FlexColumnWidth(2.0),
                      5: const pw.FlexColumnWidth(1.8),
                    },
                    children: tableRows,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  // 2. Receipt Document (إذن دخول)
  static Future<pw.Document> generateReceiptDocument(
    String invId,
    String partyName,
    DateTime date,
    List<OrderModel> orders,
    AppLocalizations tr,
  ) async {
    final pdf = pw.Document(theme: await getTheme());
    final logoData = await rootBundle.load('assets/pharmacy faculty logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final docNum = invId;
    final formattedDate = date.toLocal().toString().substring(0, 16);
    final creator = orders.isNotEmpty ? orders.first.createdBy : tr.unknownUser;
    final invoiceNo = orders.isNotEmpty ? orders.first.invoiceNumber ?? '-' : '-';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => buildFooter(ctx, tr),
        build: (pw.Context ctx) {
          final tableRows = <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B6E)),
              children: [
                _styledCell(tr.isArabic ? "م" : "S/N", isHeader: true, fontSize: 8),
                _styledCell(tr.materialName, isHeader: true, fontSize: 8),
                _styledCell(tr.sku, isHeader: true, fontSize: 8),
                _styledCell(tr.isArabic ? "رقم التشغيلة" : "Batch ID", isHeader: true, fontSize: 8),
                _styledCell(tr.quantity, isHeader: true, alignment: pw.Alignment.centerRight, fontSize: 8),
                _styledCell(tr.unit, isHeader: true, fontSize: 8),
                _styledCell(tr.expiryDate, isHeader: true, fontSize: 8),
              ],
            ),
          ];

          for (int i = 0; i < orders.length; i++) {
            final o = orders[i];
            tableRows.add(
              pw.TableRow(
                children: [
                  _styledCell((i + 1).toString(), fontSize: 8),
                  _styledCell(o.productName, fontSize: 8),
                  _styledCell(o.productSku, fontSize: 8),
                  _styledCell(o.logNumber, fontSize: 8),
                  _styledCell(o.quantity.toString(), alignment: pw.Alignment.centerRight, fontSize: 8),
                  _styledCell(o.unit.isEmpty ? '-' : o.unit, fontSize: 8),
                  _styledCell(o.expiryDate != null ? o.expiryDate!.substring(0, 10) : '-', fontSize: 8),
                ],
              ),
            );
          }

          return [
            pw.Directionality(
              textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(logoImage, tr.isArabic ? "إذن إضافة مواد للمستودع" : "Material Receipt Document", tr, subtitle: '${tr.isArabic ? "رقم الإذن: " : "Doc No: "}$docNum'),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${tr.supplier}: $partyName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text('${tr.invoiceNumber}: $invoiceNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${tr.date}: $formattedDate', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                            pw.Text('${tr.createdBy}: $creator', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    tr.isArabic ? "المواد المستلمة المضافة للمخزون:" : "Received items credited to inventory:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(20),
                      1: const pw.FlexColumnWidth(3.0),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.0),
                      5: const pw.FlexColumnWidth(1.0),
                      6: const pw.FlexColumnWidth(1.8),
                    },
                    children: tableRows,
                  ),
                  pw.SizedBox(height: 35),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "مسؤول الفحص والاستلام" : "Inspected & Received By", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "أمين المستودع" : "Storekeeper Signature", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "يعتمد، عميد الكلية" : "Approved by Faculty Dean", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  // 3. Dispatch Document (إذن صرف)
  static Future<pw.Document> generateDispatchDocument(
    String invId,
    String partyName,
    DateTime date,
    List<OrderModel> orders,
    AppLocalizations tr,
  ) async {
    final pdf = pw.Document(theme: await getTheme());
    final logoData = await rootBundle.load('assets/pharmacy faculty logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final docNum = invId;
    final formattedDate = date.toLocal().toString().substring(0, 16);
    final creator = orders.isNotEmpty ? orders.first.createdBy : tr.unknownUser;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => buildFooter(ctx, tr),
        build: (pw.Context ctx) {
          final tableRows = <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B6E)),
              children: [
                _styledCell(tr.isArabic ? "م" : "S/N", isHeader: true, fontSize: 8),
                _styledCell(tr.materialName, isHeader: true, fontSize: 8),
                _styledCell(tr.sku, isHeader: true, fontSize: 8),
                _styledCell(tr.isArabic ? "رقم التشغيلة" : "Batch ID", isHeader: true, fontSize: 8),
                _styledCell(tr.quantity, isHeader: true, alignment: pw.Alignment.centerRight, fontSize: 8),
                _styledCell(tr.unit, isHeader: true, fontSize: 8),
                _styledCell(tr.expiryDate, isHeader: true, fontSize: 8),
              ],
            ),
          ];

          for (int i = 0; i < orders.length; i++) {
            final o = orders[i];
            tableRows.add(
              pw.TableRow(
                children: [
                  _styledCell((i + 1).toString(), fontSize: 8),
                  _styledCell(o.productName, fontSize: 8),
                  _styledCell(o.productSku, fontSize: 8),
                  _styledCell(o.logNumber, fontSize: 8),
                  _styledCell(o.quantity.toString(), alignment: pw.Alignment.centerRight, fontSize: 8),
                  _styledCell(o.unit.isEmpty ? '-' : o.unit, fontSize: 8),
                  _styledCell(o.expiryDate != null ? o.expiryDate!.substring(0, 10) : '-', fontSize: 8),
                ],
              ),
            );
          }

          return [
            pw.Directionality(
              textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(logoImage, tr.isArabic ? "إذن صرف مواد من المستودع" : "Material Dispatch Document", tr, subtitle: '${tr.isArabic ? "رقم الصرف: " : "Dispatch No: "}$docNum'),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('${tr.recipient}: $partyName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.SizedBox(height: 4),
                            pw.Text('${tr.date}: $formattedDate', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('${tr.createdBy}: $creator', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    tr.isArabic ? "المواد المنصرفة والمخصومة من العهدة المخزنية:" : "Dispatched materials debited from inventory:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0A6B6E)),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(20),
                      1: const pw.FlexColumnWidth(3.0),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.0),
                      5: const pw.FlexColumnWidth(1.0),
                      6: const pw.FlexColumnWidth(1.8),
                    },
                    children: tableRows,
                  ),
                  pw.SizedBox(height: 35),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "المستلم (المصروف له)" : "Recipient Signature", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "أمين المستودع (القائم بالصرف)" : "Storekeeper Signature", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "يعتمد، مدير المستودع" : "Approved by Warehouse Mgr", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  // 4. Expiry Report PDF
  static Future<pw.Document> generateExpiryReport(
    List<MaterialModel> products,
    AppLocalizations tr,
  ) async {
    final pdf = pw.Document(theme: await getTheme());
    final logoData = await rootBundle.load('assets/pharmacy faculty logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final now = DateTime.now();
    final expiredItems = <Map<String, dynamic>>[];
    final expiringThisMonth = <Map<String, dynamic>>[];
    final expiringThreeMonths = <Map<String, dynamic>>[];

    for (final p in products) {
      for (final b in p.batches) {
        if (b.quantity <= 0) continue;
        final expDate = DateTime.tryParse(b.expiryDate);
        if (expDate == null) continue;

        final diff = expDate.difference(now).inDays;
        final itemMap = {
          'name': p.name,
          'sku': p.sku,
          'batchId': b.id,
          'qty': b.quantity,
          'unit': p.unit.isEmpty ? '-' : p.unit,
          'expiry': b.expiryDate.substring(0, 10),
          'days': diff,
        };

        if (diff <= 0) {
          expiredItems.add(itemMap);
        } else if (diff <= 30) {
          expiringThisMonth.add(itemMap);
        } else if (diff <= 90) {
          expiringThreeMonths.add(itemMap);
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        footer: (ctx) => buildFooter(ctx, tr),
        build: (pw.Context ctx) {
          pw.TableRow _buildHeaderRow() {
            return pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A6B6E)),
              children: [
                _styledCell(tr.isArabic ? "م" : "S/N", isHeader: true, fontSize: 8),
                _styledCell(tr.materialName, isHeader: true, fontSize: 8),
                _styledCell(tr.sku, isHeader: true, fontSize: 8),
                _styledCell(tr.isArabic ? "رقم التشغيلة" : "Batch ID", isHeader: true, fontSize: 8),
                _styledCell(tr.quantity, isHeader: true, alignment: pw.Alignment.centerRight, fontSize: 8),
                _styledCell(tr.expiryDate, isHeader: true, fontSize: 8),
                _styledCell(tr.isArabic ? "الأيام المتبقية" : "Days Left", isHeader: true, fontSize: 8),
              ],
            );
          }

          pw.TableRow _buildItemRow(int idx, Map<String, dynamic> item, PdfColor bgColor, PdfColor textColor) {
            final days = item['days'] as int;
            final daysText = days <= 0 
                ? (tr.isArabic ? "منتهي" : "EXPIRED") 
                : '$days ${tr.isArabic ? "يوم" : "days"}';

            return pw.TableRow(
              children: [
                _styledCell((idx + 1).toString(), fontSize: 8),
                _styledCell(item['name'], fontSize: 8),
                _styledCell(item['sku'], fontSize: 8),
                _styledCell(item['batchId'], fontSize: 8),
                _styledCell('${item['qty']} ${item['unit']}', alignment: pw.Alignment.centerRight, fontSize: 8),
                _styledCell(item['expiry'], fontSize: 8),
                _styledCell(daysText, bgColor: bgColor, textColor: textColor, fontSize: 8),
              ],
            );
          }

          final List<pw.Widget> content = [];

          content.add(
            pw.Directionality(
              textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(logoImage, tr.expiryReport, tr, subtitle: tr.isArabic ? "تحليل تاريخ الصلاحية وجداول المواد المنتهية" : "Material Expiry Audit & Timeline"),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _pdfKpiCard(tr.isArabic ? "منتهي الصلاحية" : "Expired Lots", expiredItems.length.toString(), PdfColors.red800),
                      _pdfKpiCard(tr.isArabic ? "ينتهي هذا الشهر" : "Expiring < 30 Days", expiringThisMonth.length.toString(), PdfColors.orange800),
                      _pdfKpiCard(tr.isArabic ? "ينتهي في 3 أشهر" : "Expiring < 90 Days", expiringThreeMonths.length.toString(), PdfColors.amber800),
                    ],
                  ),
                ],
              ),
            ),
          );

          // Expired section
          if (expiredItems.isNotEmpty) {
            final rows = <pw.TableRow>[_buildHeaderRow()];
            for (int i = 0; i < expiredItems.length; i++) {
              rows.add(_buildItemRow(i, expiredItems[i], PdfColors.red100, PdfColors.red900));
            }
            content.add(pw.SizedBox(height: 15));
            content.add(
              pw.Directionality(
                textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      tr.isArabic ? "مواد منتهية الصلاحية (حرجة - تتطلب الإتلاف):" : "Expired Materials (Critical - Disposal Required):",
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(20),
                        1: const pw.FlexColumnWidth(2.5),
                        2: const pw.FlexColumnWidth(1.2),
                        3: const pw.FlexColumnWidth(1.2),
                        4: const pw.FlexColumnWidth(1.5),
                        5: const pw.FlexColumnWidth(1.5),
                        6: const pw.FlexColumnWidth(1.5),
                      },
                      children: rows,
                    ),
                  ],
                ),
              ),
            );
          }

          // Expiring this month
          if (expiringThisMonth.isNotEmpty) {
            final rows = <pw.TableRow>[_buildHeaderRow()];
            for (int i = 0; i < expiringThisMonth.length; i++) {
              rows.add(_buildItemRow(i, expiringThisMonth[i], PdfColors.orange100, PdfColors.orange900));
            }
            content.add(pw.SizedBox(height: 15));
            content.add(
              pw.Directionality(
                textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      tr.isArabic ? "مواد تنتهي الصلاحية هذا الشهر (عالية الخطورة):" : "Materials Expiring within 30 Days (High Alert):",
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(20),
                        1: const pw.FlexColumnWidth(2.5),
                        2: const pw.FlexColumnWidth(1.2),
                        3: const pw.FlexColumnWidth(1.2),
                        4: const pw.FlexColumnWidth(1.5),
                        5: const pw.FlexColumnWidth(1.5),
                        6: const pw.FlexColumnWidth(1.5),
                      },
                      children: rows,
                    ),
                  ],
                ),
              ),
            );
          }

          // Expiring within 3 months
          if (expiringThreeMonths.isNotEmpty) {
            final rows = <pw.TableRow>[_buildHeaderRow()];
            for (int i = 0; i < expiringThreeMonths.length; i++) {
              rows.add(_buildItemRow(i, expiringThreeMonths[i], PdfColors.amber100, PdfColors.amber900));
            }
            content.add(pw.SizedBox(height: 15));
            content.add(
              pw.Directionality(
                textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      tr.isArabic ? "مواد تنتهي الصلاحية خلال 3 أشهر (تنبيه مسبق):" : "Materials Expiring within 90 Days (Warning Alert):",
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      columnWidths: {
                        0: const pw.FixedColumnWidth(20),
                        1: const pw.FlexColumnWidth(2.5),
                        2: const pw.FlexColumnWidth(1.2),
                        3: const pw.FlexColumnWidth(1.2),
                        4: const pw.FlexColumnWidth(1.5),
                        5: const pw.FlexColumnWidth(1.5),
                        6: const pw.FlexColumnWidth(1.5),
                      },
                      children: rows,
                    ),
                  ],
                ),
              ),
            );
          }

          if (expiredItems.isEmpty && expiringThisMonth.isEmpty && expiringThreeMonths.isEmpty) {
            content.add(pw.SizedBox(height: 30));
            content.add(
              pw.Directionality(
                textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Center(
                  child: pw.Text(
                    tr.isArabic ? "لا توجد أي تشغيلات منتهية الصلاحية أو قريبة من الانتهاء حالياً." : "No expired or expiring-soon batches found.",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                  ),
                ),
              ),
            );
          }

          return content;
        },
      ),
    );
    return pdf;
  }

  // 5. Disposal Document (إذن إتلاف)
  static Future<pw.Document> generateDisposalDocument(
    String invId,
    String method,
    DateTime date,
    List<OrderModel> orders,
    AppLocalizations tr,
  ) async {
    final pdf = pw.Document(theme: await getTheme());
    final logoData = await rootBundle.load('assets/pharmacy faculty logo.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final docNum = invId;
    final formattedDate = date.toLocal().toString().substring(0, 16);
    final creator = orders.isNotEmpty ? orders.first.createdBy : tr.unknownUser;
    final notes = orders.isNotEmpty ? orders.first.notes ?? '-' : '-';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        footer: (ctx) => buildFooter(ctx, tr),
        build: (pw.Context ctx) {
          final tableRows = <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.red800),
              children: [
                _styledCell(tr.isArabic ? "م" : "S/N", isHeader: true, fontSize: 8),
                _styledCell(tr.materialName, isHeader: true, fontSize: 8),
                _styledCell(tr.sku, isHeader: true, fontSize: 8),
                _styledCell(tr.isArabic ? "رقم التشغيلة" : "Batch ID", isHeader: true, fontSize: 8),
                _styledCell(tr.quantity, isHeader: true, alignment: pw.Alignment.centerRight, fontSize: 8),
                _styledCell(tr.unit, isHeader: true, fontSize: 8),
                _styledCell(tr.expiryDate, isHeader: true, fontSize: 8),
              ],
            ),
          ];

          for (int i = 0; i < orders.length; i++) {
            final o = orders[i];
            tableRows.add(
              pw.TableRow(
                children: [
                  _styledCell((i + 1).toString(), fontSize: 8),
                  _styledCell(o.productName, fontSize: 8),
                  _styledCell(o.productSku, fontSize: 8),
                  _styledCell(o.logNumber, fontSize: 8),
                  _styledCell(o.quantity.toString(), alignment: pw.Alignment.centerRight, fontSize: 8),
                  _styledCell(o.unit.isEmpty ? '-' : o.unit, fontSize: 8),
                  _styledCell(o.expiryDate != null ? o.expiryDate!.substring(0, 10) : '-', fontSize: 8),
                ],
              ),
            );
          }

          return [
            pw.Directionality(
              textDirection: tr.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildHeader(logoImage, tr.isArabic ? "محضر إتلاف مواد صيدلانية منتهية" : "Expired Materials Disposal Document", tr, subtitle: '${tr.isArabic ? "رقم المحضر: " : "Disposal No: "}$docNum'),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${tr.disposalMethod}: $method', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                            pw.Text('${tr.date}: $formattedDate', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('${tr.createdBy}: $creator', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                            pw.Text('${tr.notes}: $notes', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    tr.isArabic ? "المواد التالفة المخصومة كلياً من العهدة المخزنية:" : "Disposed materials fully written off from stock ledger:",
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(20),
                      1: const pw.FlexColumnWidth(3.0),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.0),
                      5: const pw.FlexColumnWidth(1.0),
                      6: const pw.FlexColumnWidth(1.8),
                    },
                    children: tableRows,
                  ),
                  pw.SizedBox(height: 35),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "القائم بالإتلاف (أمين المستودع)" : "Disposed By (Storekeeper)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "مدير المستودع" : "Warehouse Manager", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(tr.isArabic ? "يعتمد، عميد الكلية" : "Approved by Faculty Dean", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.SizedBox(height: 35),
                          pw.Text("____________________", style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    return pdf;
  }
}
