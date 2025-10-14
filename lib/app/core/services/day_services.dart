import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as xls;
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/category_repository.dart';
// uses excel and pdf packages directly
import '../../data/models/category_model.dart';

/// Day-level export helpers: create a single Excel or PDF that contains all menus for a date.
class DayServices {
  /// Create a combined Excel file for the given date. Returns the created File.
  static Future<File> createDayExcel(
    DateTime date, {
    String totalKey = 'total',
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final menus = await menuRepo.list(date: dateStr);
    final cats = await catRepo.getAll();

    // Build an Excel workbook with one titled table per menu
    final excel = xls.Excel.createExcel();
    final sheet = excel['Sheet1'];

    for (final m in menus) {
      // title row
      sheet.appendRow([m.name]);
      // headers
      final headers = [
        'رقم',
        'ملاحظة',
        'كمية',
        'سعر الوحدة',
        'الفئة',
        'الإجمالي',
      ];
      sheet.appendRow(headers);

      final items = await itemRepo.listByMenu(m.id);
      double menuTotal = 0.0;
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        CategoryModel? cat;
        try {
          cat = cats.firstWhere((c) => c.id == (it.categoryId ?? ''));
        } catch (_) {
          cat = null;
        }
        final lineTotal = it.total != 0 ? it.total : (it.qty * it.unitPrice);
        menuTotal += lineTotal;
        sheet.appendRow([
          i + 1,
          it.notes ?? '',
          it.qty,
          it.unitPrice,
          cat?.name ?? '',
          lineTotal,
        ]);
      }

      // totals row for this menu
      sheet.appendRow([
        '',
        '',
        '',
        '',
        'الإجمالي',
        menuTotal.toStringAsFixed(2),
      ]);
      // empty row as spacer
      sheet.appendRow([]);
    }

    final bytes = excel.encode();
    final dir = await getApplicationDocumentsDirectory();
    final outName =
        'day_services_${date.year.toString()}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final file = File(
      '${dir.path}/${outName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }

static Future<File> createDayStyleExcel(DateTime date) async {
  final menuRepo = MenuRepository();
  final itemRepo = ItemRepository();
  final catRepo = CategoryRepository();

  final dateStr =
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final menus = await menuRepo.list(date: dateStr);
  final cats = await catRepo.getAll();

  final excel = xls.Excel.createExcel();
  excel.delete('Sheet1');

  for (var idx = 0; idx < menus.length; idx++) {
    final menu = menus[idx];
    final safeSheetName = menu.name.replaceAll(RegExp(r'[\\/:*?\[\]]'), '_');
    final sheet = excel[safeSheetName];
    final items = await itemRepo.listByMenu(menu.id);

    // === Title ===
    final titleCell = sheet.cell(xls.CellIndex.indexByString('A1'));
    titleCell.value = '${menu.name} ($dateStr)';
    titleCell.cellStyle = xls.CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: xls.HorizontalAlign.Center,
    );
    sheet.merge(
      xls.CellIndex.indexByString('A1'),
      xls.CellIndex.indexByString('F1'),
    );

    // === Headers ===
    const headers = ['رقم', 'ملاحظة', 'كمية', 'سعر الوحدة', 'الفئة', 'الإجمالي'];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2),
      );
      cell.value = headers[c];
      cell.cellStyle = xls.CellStyle(
        bold: true,
        fontSize: 12,
        horizontalAlign: xls.HorizontalAlign.Center,
      );
    }

    // === Data ===
    double totalSum = 0;
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      CategoryModel? cat;
      try {
        cat = cats.firstWhere((c) => c.id == (it.categoryId ?? ''));
      } catch (_) {
        cat = null;
      }
      final lineTotal = it.total != 0 ? it.total : (it.qty * it.unitPrice);
      totalSum += lineTotal;

      final rowIndex = i + 3;
      final rowData = [
        i + 1,
        it.notes ?? '',
        it.qty,
        it.unitPrice,
        cat?.name ?? '',
        lineTotal,
      ];

      for (int j = 0; j < rowData.length; j++) {
        final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
        );
        cell.value = rowData[j];
        cell.cellStyle = xls.CellStyle(
          horizontalAlign: xls.HorizontalAlign.Center,
          fontSize: 11,
        );
      }
    }

    // === Totals ===
    final totalRowIndex = items.length + 3;
    sheet.merge(
      xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
      xls.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex),
    );

    final labelCell = sheet.cell(
      xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
    );
    labelCell.value = 'الإجمالي';
    labelCell.cellStyle = xls.CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: xls.HorizontalAlign.Center,
    );

    final totalCell = sheet.cell(
      xls.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex),
    );
    totalCell.value = totalSum.toStringAsFixed(2);
    totalCell.cellStyle = xls.CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: xls.HorizontalAlign.Center,
    );

    sheet.appendRow([]); // spacer
  }

  final bytes = excel.encode();
  final dir = await getApplicationDocumentsDirectory();
  final outName =
      'styled_day_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  final file = File('${dir.path}/$outName.xlsx');
  if (bytes != null) await file.writeAsBytes(bytes);
  return file;
}

  /// Create a single PDF file that contains one section per menu for the given date.
  /// Returns the created File.
  static Future<File> createDayPdf(
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
      final rows =
          items.map((it) {
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

    // attempt to load fonts and logo
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

    // chunk menus into pages with up to 3 tables per page
    const chunkSize = 3;
    for (var p = 0; p < allSections.length; p += chunkSize) {
      final chunk = allSections.sublist(
        p,
        (p + chunkSize) > allSections.length
            ? allSections.length
            : p + chunkSize,
      );
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
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'تقرير اليوم: $dateStr',
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
                        width: 64,
                        height: 64,
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                  ],
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 12));

            for (final section in chunk) {
              final menuName = section['menuName'] as String;
              final rows = section['rows'] as List<Map<String, dynamic>>;

              widgets.add(
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Text(
                    menuName,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              );

              final headers =
                  rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
              final headersWithIndex =
                  <String>['رقم'] + headers.map((h) => h.toString()).toList();

              final dataWithIndex = <List<String>>[];
              double totalSum = 0.0;
              for (var i = 0; i < rows.length; i++) {
                final r = rows[i];
                final rowValues = <String>[];
                dynamic candidate = r[totalKey] ?? r.values.last;
                double parsed = 0.0;
                if (candidate != null) {
                  if (candidate is num)
                    parsed = candidate.toDouble();
                  else
                    parsed =
                        double.tryParse(
                          candidate.toString().replaceAll(',', '.'),
                        ) ??
                        0.0;
                }
                totalSum += parsed;
                rowValues.add('${i + 1}');
                for (final h in headers) rowValues.add((r[h] ?? '').toString());
                dataWithIndex.add(rowValues);
              }

              widgets.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.TableHelper.fromTextArray(
                    headers: headersWithIndex,
                    data: dataWithIndex,
                    headerStyle: pw.TextStyle(font: arabicFont, fontSize: 12),
                    cellStyle: pw.TextStyle(font: arabicFont, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    cellAlignments: {
                      for (var i = 0; i < headersWithIndex.length; i++)
                        i: pw.Alignment.centerRight,
                    },
                  ),
                ),
              );

              widgets.add(pw.SizedBox(height: 6));
              widgets.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'عدد العناصر: ${rows.length}',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'الإجمالي: ${totalSum.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: arabicFont,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              widgets.add(pw.Divider());
            }

            return widgets;
          },
          footer:
              (context) => pw.Container(
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
      '${dir.path}/day_services_${date.year.toString()}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }
}
