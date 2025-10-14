import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/models/category_model.dart';

class DayPdfExportServices {
  static Future<File> createDayHorizontalPdf(
    DateTime date, {
    String fontAsset = 'assets/fonts/NotoNaskhArabic-Regular.ttf',
    String logoAsset = 'assets/images/logo.png',
    String totalKey = 'الإجمالي',
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final menus = await menuRepo.list(date: dateStr);
    final cats = await catRepo.getAll();

    final allSections = <Map<String, dynamic>>[];

    for (final m in menus) {
      final items = await itemRepo.listByMenu(m.id);
      final rows = items.map((it) {
        CategoryModel? cat;
        try {
          cat = cats.firstWhere((c) => c.id == (it.categoryId ?? ''));
        } catch (_) {
          cat = null;
        }
        return {
          'ملاحظة': it.notes ?? '',
          'كمية': it.qty,
          'سعر الوحدة': it.unitPrice,
          'الفئة': cat?.name ?? '',
          'الإجمالي': it.total != 0 ? it.total : (it.qty * it.unitPrice),
        };
      }).toList();

      allSections.add({'menuName': m.name, 'rows': rows});
    }

    final doc = pw.Document();

    // === Font & Logo ===
    pw.Font? arabicFont;
    try {
      final fontData = await rootBundle.load(fontAsset);
      arabicFont = pw.Font.ttf(fontData);
    } catch (_) {
      arabicFont = null;
    }

    Uint8List? logoBytes;
    try {
      final lb = await rootBundle.load(logoAsset);
      logoBytes = lb.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    // === Build pages ===
    const chunkSize = 4; // number of menus per page (2x2 layout)

    for (var p = 0; p < allSections.length; p += chunkSize) {
      final chunk = allSections.sublist(
        p,
        (p + chunkSize) > allSections.length
            ? allSections.length
            : p + chunkSize,
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(12),
          build: (context) {
            final widgets = <pw.Widget>[];

            // ===== Header =====
            widgets.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'تقرير اليوم (أفقي): $dateStr',
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'عدد القوائم في الصفحة: ${chunk.length}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    if (logoBytes != null)
                      pw.Container(
                        width: 60,
                        height: 60,
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                  ],
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 10));

            // ===== Menus side by side =====
            widgets.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: chunk.map((section) {
                    final menuName = section['menuName'] as String;
                    final rows = section['rows'] as List<Map<String, dynamic>>;

                    final headers =
                        rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
                    final headersWithIndex =
                        <String>['رقم'] + headers.map((h) => h.toString()).toList();

                    final dataWithIndex = <List<String>>[];
                    double totalSum = 0.0;

                    for (var i = 0; i < rows.length; i++) {
                      final r = rows[i];
                      final rowValues = <String>[];
                      final candidate = r[totalKey] ?? r.values.last;
                      double parsed = 0.0;
                      if (candidate != null) {
                        if (candidate is num) {
                          parsed = candidate.toDouble();
                        } else {
                          parsed = double.tryParse(
                                  candidate.toString().replaceAll(',', '.')) ??
                              0.0;
                        }
                      }
                      totalSum += parsed;
                      rowValues.add('${i + 1}');
                      for (final h in headers) {
                        rowValues.add((r[h] ?? '').toString());
                      }
                      dataWithIndex.add(rowValues);
                    }

                    return pw.Container(
                      width: 360,
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Text(
                            menuName,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.TableHelper.fromTextArray(
                            headers: headersWithIndex,
                            data: dataWithIndex,
                            headerStyle:
                                pw.TextStyle(font: arabicFont, fontSize: 11),
                            cellStyle:
                                pw.TextStyle(font: arabicFont, fontSize: 9),
                            headerDecoration: const pw.BoxDecoration(
                              color: PdfColors.grey300,
                            ),
                            cellAlignments: {
                              for (var i = 0; i < headersWithIndex.length; i++)
                                i: pw.Alignment.centerRight,
                            },
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'الإجمالي: ${totalSum.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.end,
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );

            return widgets;
          },
          footer: (context) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: pw.TextStyle(font: arabicFont, fontSize: 9),
            ),
          ),
        ),
      );
    }

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/day_horizontal_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }
}
