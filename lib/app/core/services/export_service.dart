import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart'; // ✅ updated import
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';

class ExportService {
  /// Shows a confirmation dialog with an option to attach to email.
  static Future<Map<String, dynamic>?> showConfirmDialog(
      BuildContext context, String title) async {
    bool attach = true;
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('هل تريد تصدير الملف ومشاركته عبر البريد الإلكتروني؟'),
                  Row(
                    children: [
                      Checkbox(
                        value: attach,
                        onChanged: (v) => setState(() => attach = v ?? true),
                      ),
                      const SizedBox(width: 8),
                      const Text('إرفاق في البريد الإلكتروني'),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop({'attach': attach}),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
    return res;
  }

  /// Create a PDF report and optionally share it.
  /// Accepts optional asset paths for logo and font.
  static Future<File> createPdfReport({
    required List<Map<String, dynamic>> monthly,
    required List<Map<String, dynamic>> weekly,
    required List<Map<String, dynamic>> recent,
    Map<String, String?>? filters,
    String? logoAsset,
    String? fontAsset,
  }) async {
    final doc = pw.Document();

    // Try to load Arabic fonts if provided. If not found, fall back to default.
    pw.Font? arabicFont;
    pw.Font? arabicFontBold;
    if (fontAsset != null) {
      try {
        final fontData = await rootBundle.load(fontAsset);
        arabicFont = pw.Font.ttf(fontData);
      } catch (_) {
        arabicFont = null;
      }
    }
    // If bold variant exists next to provided font, try to load it too
    try {
      final boldPath = fontAsset?.replaceFirst('.ttf', '-Bold.ttf');
      if (boldPath != null) {
        final bdata = await rootBundle.load(boldPath);
        arabicFontBold = pw.Font.ttf(bdata);
      }
    } catch (_) {
      arabicFontBold = arabicFont;
    }

    final baseStyle = pw.TextStyle(font: arabicFont, fontSize: 12);

    Uint8List? logoBytes;
    if (logoAsset != null) {
      try {
        final lb = await rootBundle.load(logoAsset);
        logoBytes = lb.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // place text column first so logo appears on the right in RTL
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('مشترياتي', style: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('تقرير المشتريات', style: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 16)),
                        pw.SizedBox(height: 6),
                        pw.Text('تاريخ الإنشاء: ${DateTime.now()}', style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                        if (arabicFont == null) pw.SizedBox(height: 8),
                        if (arabicFont == null)
                          pw.Text('تنبيه: لم يتم تحميل خط عربي. أضف ملف TTF في assets/fonts/ ثم مرّر مسار الخط عند التصدير لعرض النص العربي بشكل صحيح.',
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.red)),
                      ],
                    ),
                  ),
                  if (logoBytes != null) pw.Container(width: 80, height: 80, child: pw.Image(pw.MemoryImage(logoBytes))),
                ],
              ),
            ),
          );

          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Text('الفلاتر: ${filters ?? {}}', style: baseStyle)));
          widgets.add(pw.SizedBox(height: 12));

          // Monthly summary
          widgets.add(pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Text('ملخص يومي / شهري', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: arabicFontBold ?? arabicFont))));
          widgets.add(pw.SizedBox(height: 6));
          final monthHeaders = ['الفترة', 'المجموع'];
          widgets.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.TableHelper.fromTextArray(
                headers: monthHeaders,
                data: monthly.map((r) => [r['day'] ?? '', (r['total'] ?? 0).toString()]).toList(),
                headerStyle: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 12),
                cellStyle: pw.TextStyle(font: arabicFont, fontSize: 11),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.centerRight},
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 12));

          // Recent purchases
          widgets.add(pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Text('آخر المشتريات', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, font: arabicFontBold ?? arabicFont))));
          widgets.add(pw.SizedBox(height: 6));
          final recentHeaders = ['ملاحظة', 'كمية', 'سعر', 'مجموع', 'فرع'];
          widgets.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.TableHelper.fromTextArray(
                headers: recentHeaders,
                data: recent
                    .map((r) => [r['notes'] ?? '', (r['qty'] ?? 0).toString(), (r['unit_price'] ?? 0).toString(), (r['total'] ?? 0).toString(), r['branch_id'] ?? '']).toList(),
                headerStyle: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 12),
                cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignments: {
                  0: pw.Alignment.centerRight,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1), 3: const pw.FlexColumnWidth(1), 4: const pw.FlexColumnWidth(1)},
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/saher_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Create an Excel report
  static Future<File> createExcelReport(
      {required List<Map<String, dynamic>> rows}) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Sheet1'];
    if (rows.isNotEmpty) {
      final headers = rows.first.keys.toList();
    sheet.appendRow(headers);
      for (final r in rows) {
        sheet.appendRow(headers.map((h) => r[h] ?? '').toList());
      }
    }
    final bytes = excel.encode();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/saher_purchases_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }

  /// Share a file (PDF, Excel, etc.)
  static Future<void> shareFile(File file,
      {String? subject, String? text, bool attach = true}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'تصدير الملف',
        text: text ?? '',
      );
    } catch (e) {
      debugPrint('❌ خطأ أثناء المشاركة: $e');
    }
  }

  /// Create CSV export
  static Future<File> createCsvReport(
      {required List<Map<String, dynamic>> rows, String? filenamePrefix}) async {
    final sb = StringBuffer();
    if (rows.isEmpty) {
      sb.writeln('no_data');
    } else {
      final headers = rows.first.keys.toList();
      sb.writeln(headers.join(','));
      for (final r in rows) {
        sb.writeln(headers
            .map((h) => '"${(r[h] ?? '').toString().replaceAll('"', '""')}"')
            .join(','));
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/${filenamePrefix ?? 'saher_export'}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(sb.toString());
    return file;
  }

  // --- Convenience exports for specific menu, branch, or all data ---

  /// Create a PDF report for a specific menu.
  static Future<File> createPdfReportForMenu({
    required String menuName,
    required List<Map<String, dynamic>> rows,
    String? logoAsset,
    String? fontAsset,
  }) async {
    final doc = pw.Document();
    pw.Font? arabicFont;
    if (fontAsset != null) {
      try {
        final fontData = await rootBundle.load(fontAsset);
        arabicFont = pw.Font.ttf(fontData);
      } catch (_) {
        arabicFont = null;
      }
    }

    Uint8List? logoBytes;
    if (logoAsset != null) {
      try {
        final lb = await rootBundle.load(logoAsset);
        logoBytes = lb.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }
    }

    doc.addPage(pw.MultiPage(build: (context) {
      final List<pw.Widget> w = [];
      w.add(pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('مشترياتي', style: pw.TextStyle(font: arabicFont, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('تقرير القائمة: $menuName', style: pw.TextStyle(font: arabicFont, fontSize: 14)),
              pw.SizedBox(height: 6),
              pw.Text('تاريخ الإنشاء: ${DateTime.now()}', style: pw.TextStyle(fontSize: 9, font: arabicFont)),
            ]),
          ),
          if (logoBytes != null) pw.Container(width: 64, height: 64, child: pw.Image(pw.MemoryImage(logoBytes))),
        ]),
      ));

      w.add(pw.SizedBox(height: 12));
      // table header (Arabic)
      final headers = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
      w.add(pw.Directionality(
        textDirection: pw.TextDirection.rtl,
        child: pw.TableHelper.fromTextArray(
          headers: headers.map((h) => h.toString()).toList(),
          data: rows.map((r) => headers.map((h) => (r[h] ?? '').toString()).toList()).toList(),
          headerStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
          cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: { for (var i = 0; i < headers.length; i++) i: pw.Alignment.centerRight },
        ),
      ));

      return w;
    }));

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_menu_${menuName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Create a PDF report for a specific branch.
  static Future<File> createPdfReportForBranch({
    required String branchName,
    required List<Map<String, dynamic>> rows,
    String? logoAsset,
    String? fontAsset,
  }) async {
    // reuse the menu generator but change heading
    return createPdfReportForMenu(menuName: branchName, rows: rows, logoAsset: logoAsset, fontAsset: fontAsset);
  }

  /// Create a PDF report for all items (general report).
  static Future<File> createPdfReportForAll({
    required List<Map<String, dynamic>> rows,
    String? logoAsset,
    String? fontAsset,
  }) async {
    return createPdfReportForMenu(menuName: 'كل المشتريات', rows: rows, logoAsset: logoAsset, fontAsset: fontAsset);
  }

  /// Create Excel for menu/branch/all
  static Future<File> createExcelForEntity({required String prefix, required List<Map<String, dynamic>> rows}) async {
    return createExcelReport(rows: rows).then((f) async {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await f.copy(dest.path);
      return dest;
    });
  }

  /// Create CSV for menu/branch/all
  static Future<File> createCsvForEntity({required String prefix, required List<Map<String, dynamic>> rows}) async {
    return createCsvReport(rows: rows, filenamePrefix: prefix);
  }
}
