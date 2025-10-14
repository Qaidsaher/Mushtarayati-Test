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

    pw.Font? arabicFont;
    if (fontAsset != null) {
      try {
        final fontData = await rootBundle.load(fontAsset);
        arabicFont = pw.Font.ttf(fontData);
      } catch (_) {
        arabicFont = null;
      }
    }

    final baseStyle = pw.TextStyle(
      font: arabicFont,
      fontSize: 12,
    );

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

          // Header
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoBytes != null)
                  pw.Container(
                    width: 80,
                    height: 80,
                    child: pw.Image(pw.MemoryImage(logoBytes)),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'تقرير المشتريات',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: arabicFont,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'تاريخ الإنشاء: ${DateTime.now()}',
                      style: pw.TextStyle(fontSize: 10, font: arabicFont),
                    ),
                  ],
                ),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 12));
          widgets.add(pw.Text('الفلاتر: ${filters ?? {}}', style: baseStyle));
          widgets.add(pw.SizedBox(height: 12));

          // Monthly summary
          widgets.add(
            pw.Text('ملخص يومي / شهري',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
          );
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(
            pw.TableHelper.fromTextArray(
              data: monthly
                  .map((r) => [r['day'] ?? '', (r['total'] ?? 0).toString()])
                  .toList(),
              headers: ['الفترة', 'المجموع'],
            ),
          );
          widgets.add(pw.SizedBox(height: 12));

          // Recent purchases
          widgets.add(pw.Text('آخر المشتريات',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(
            pw.TableHelper.fromTextArray(
              data: recent
                  .map((r) => [
                        r['notes'] ?? '',
                        (r['qty'] ?? 0).toString(),
                        (r['unit_price'] ?? 0).toString(),
                        (r['total'] ?? 0).toString(),
                        r['branch_id'] ?? '',
                      ])
                  .toList(),
              headers: ['ملاحظة', 'كمية', 'سعر', 'مجموع', 'فرع'],
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
}
