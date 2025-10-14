import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class PdfService {
  /// Create a generic PDF report (monthly/weekly/recent)
  static Future<File> createPdfReport({
    required List<Map<String, dynamic>> monthly,
    required List<Map<String, dynamic>> weekly,
    required List<Map<String, dynamic>> recent,
    Map<String, String?>? filters,
    String? logoAsset,
    String? fontAsset,
    String totalKey = 'total',
  }) async {
    final doc = pw.Document();

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
    try {
      final boldPath = fontAsset?.replaceFirst('.ttf', '-Bold.ttf');
      if (boldPath != null) {
        final bdata = await rootBundle.load(boldPath);
        arabicFontBold = pw.Font.ttf(bdata);
      }
    } catch (_) {
      arabicFontBold = arabicFont;
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

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        final widgets = <pw.Widget>[];

        widgets.add(pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('مشترياتي', style: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('تقرير المشتريات', style: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 16)),
                  pw.SizedBox(height: 6),
                  pw.Text('تاريخ الإنشاء: ${DateTime.now()}', style: pw.TextStyle(fontSize: 10, font: arabicFont)),
                ]),
              ),
              if (logoBytes != null) pw.Container(width: 80, height: 80, child: pw.Image(pw.MemoryImage(logoBytes))),
            ],
          ),
        ));

        widgets.add(pw.SizedBox(height: 12));

        widgets.add(pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Text('ملخص يومي / شهري', style: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 14))));
        widgets.add(pw.SizedBox(height: 8));
        final monthHeaders = ['الفترة', 'المجموع'];
        widgets.add(pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.TableHelper.fromTextArray(
            headers: monthHeaders,
            data: monthly.map((r) => [r['day'] ?? '', (r['total'] ?? 0).toString()]).toList(),
            headerStyle: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 12),
            cellStyle: pw.TextStyle(font: arabicFont, fontSize: 11),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.centerRight},
          ),
        ));

        widgets.add(pw.SizedBox(height: 12));

        widgets.add(pw.Directionality(textDirection: pw.TextDirection.rtl, child: pw.Text('آخر المشتريات', style: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 14))));
        widgets.add(pw.SizedBox(height: 8));
        final recentHeaders = ['ملاحظة', 'كمية', 'سعر', 'مجموع', 'فرع'];
        widgets.add(pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.TableHelper.fromTextArray(
            headers: recentHeaders,
            data: recent.map((r) => [r['notes'] ?? '', (r['qty'] ?? 0).toString(), (r['unit_price'] ?? 0).toString(), (r['total'] ?? 0).toString(), r['branch_id'] ?? '']).toList(),
            headerStyle: pw.TextStyle(font: arabicFontBold ?? arabicFont, fontSize: 12),
            cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {0: pw.Alignment.centerRight, 1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
          ),
        ));

        return widgets;
      },
      footer: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 6),
        child: pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: arabicFont, fontSize: 9)),
      ),
    ));

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/saher_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Create a PDF report for a specific menu. Adds numbering, total calculation and footer.
  static Future<File> createPdfReportForMenu({
    required String menuName,
    required List<Map<String, dynamic>> rows,
    String? logoAsset,
    String? fontAsset,
    String totalKey = 'total',
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

    final headers = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
    final headersWithIndex = <String>['رقم'] + headers.map((h) => h.toString()).toList();

    double totalSum = 0.0;
    final dataWithIndex = <List<String>>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowValues = <String>[];

      dynamic totalCandidate;
      final possibleTotalKeys = [totalKey, 'الإجمالي', 'total', 'total_price', 'مجموع', 'sum', 'المجموع', 'price_total'];
      for (final k in possibleTotalKeys) {
        if (r.containsKey(k)) {
          totalCandidate = r[k];
          break;
        }
      }
      if (totalCandidate == null && r.isNotEmpty) totalCandidate = r[r.keys.last];

      double parsed = 0.0;
      if (totalCandidate != null) {
        if (totalCandidate is num) parsed = totalCandidate.toDouble();
        else parsed = double.tryParse(totalCandidate.toString().replaceAll(',', '.')) ?? 0.0;
      }
      totalSum += parsed;

      rowValues.add('${i + 1}');
      for (final h in headers) rowValues.add((r[h] ?? '').toString());
      dataWithIndex.add(rowValues);
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        final w = <pw.Widget>[];

        w.add(pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('تقرير القائمة: $menuName', style: pw.TextStyle(font: arabicFont, fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('تاريخ الإنشاء: ${DateTime.now()}', style: pw.TextStyle(font: arabicFont, fontSize: 9)),
            ])),
            if (logoBytes != null)
              pw.Column(children: [pw.Container(width: 64, height: 64, child: pw.Image(pw.MemoryImage(logoBytes))), pw.SizedBox(height: 6), pw.Text('مشترياتي', style: pw.TextStyle(font: arabicFont, fontSize: 10))]),
          ]),
        ));

        w.add(pw.SizedBox(height: 12));

        w.add(pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.TableHelper.fromTextArray(
            headers: headersWithIndex,
            data: dataWithIndex,
            headerStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
            cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {for (var i = 0; i < headersWithIndex.length; i++) i: pw.Alignment.centerRight},
          ),
        ));

        w.add(pw.SizedBox(height: 8));
        w.add(pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('عدد العناصر: ${rows.length}', style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text('الإجمالي الكلي: ${totalSum.toStringAsFixed(2)}', style: pw.TextStyle(font: arabicFont, fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ]),
        ));

        return w;
      },
      footer: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 6),
        child: pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: arabicFont, fontSize: 9)),
      ),
    ));

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/report_menu_${menuName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> shareFile(File file, {String? subject, String? text}) async {
    try {
      await Share.shareXFiles([XFile(file.path)], subject: subject ?? 'تصدير الملف', text: text ?? '');
    } catch (e) {
      if (kDebugMode) debugPrint('Share error: $e');
    }
  }
}