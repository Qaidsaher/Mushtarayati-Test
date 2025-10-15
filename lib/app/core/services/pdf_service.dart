import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/category_repository.dart';

// Lightweight internal data holders for period sheets prefetching
class _MenuItemsData {
  final dynamic menu; // Menu model (kept dynamic to avoid extra imports)
  final List<dynamic> items; // Item models
  _MenuItemsData({required this.menu, required this.items});
}

class _DayMenusData {
  final String dateStr;
  final List<_MenuItemsData> menus;
  _DayMenusData({required this.dateStr, required this.menus});
}

class PdfService {
  // ===== Shared styling helpers for modern, professional look =====
  static const PdfColor _headerBg = PdfColor.fromInt(0xFFE8F5E9);
  static const PdfColor _altRowBg = PdfColor.fromInt(0xFFF9F9F9);
  static const PdfColor _sectionBg = PdfColor.fromInt(0xFFFFF3E0);
  // Note: totals use header background styling for consistency

  static Future<(pw.Font?, pw.Font?)> _loadArabicFonts() async {
    pw.Font? arabicFont;
    pw.Font? arabicFontBold;
    try {
      final reg = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      arabicFont = pw.Font.ttf(reg);
      final bold = await rootBundle.load(
        'assets/fonts/NotoNaskhArabic-Bold.ttf',
      );
      arabicFontBold = pw.Font.ttf(bold);
    } catch (_) {
      arabicFont = null;
      arabicFontBold = null;
    }
    return (arabicFont, arabicFontBold ?? arabicFont);
  }

  static pw.TableRow _modernHeaderRow(
    List<String> headers,
    pw.Font? base,
    pw.Font? bold,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _headerBg),
      children:
          headers
              .map(
                (h) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(width: 0.5),
                      bottom: pw.BorderSide(width: 0.5),
                      left: pw.BorderSide(width: 0.5),
                      right: pw.BorderSide(width: 0.5),
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      font: bold ?? base,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              )
              .toList(),
    );
  }

  static pw.TableRow _modernDataRow(
    List<String> cells,
    pw.Font? base, {
    bool alt = false,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: alt ? _altRowBg : null),
      children:
          cells
              .map(
                (c) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(width: 0.5),
                      bottom: pw.BorderSide(width: 0.5),
                      left: pw.BorderSide(width: 0.5),
                      right: pw.BorderSide(width: 0.5),
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    c,
                    style: pw.TextStyle(font: base, fontSize: 11),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              )
              .toList(),
    );
  }

  static pw.Widget _sectionTitle(String text, pw.Font? bold) => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: _sectionBg,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 13)),
  );

  static String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Header: logo on the right, title centered
  static pw.Widget _pageHeader({
    required String appName,
    required String title,
    required pw.Font? base,
    required pw.Font? bold,
    Uint8List? logoBytes,
    String? userName,
    String? contact,
    String? extraInfo,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null)
              pw.Container(
                width: 56,
                height: 56,
                child: pw.Image(pw.MemoryImage(logoBytes)),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    appName,
                    style: pw.TextStyle(
                      font: bold ?? base,
                      fontSize: 15,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    title,
                    style: pw.TextStyle(font: bold ?? base, fontSize: 13),
                  ),
                  if (userName != null)
                    pw.Text(
                      'المستخدم: $userName',
                      style: pw.TextStyle(
                        font: base,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  if (contact != null)
                    pw.Text(
                      contact,
                      style: pw.TextStyle(
                        font: base,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  if (extraInfo != null)
                    pw.Text(
                      extraInfo,
                      style: pw.TextStyle(
                        font: base,
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  // Footer: page numbers and timestamp
  static pw.Widget _pageFooter({
    required pw.Font? base,
    required int pageNumber,
    required int pagesCount,
    String? appName,
    String? printedAt,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Column(
          children: [
            pw.Container(height: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  printedAt ?? '',
                  style: pw.TextStyle(
                    font: base,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
                if (appName != null)
                  pw.Text(
                    appName,
                    style: pw.TextStyle(
                      font: base,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.Text(
                  'صفحة $pageNumber من $pagesCount',
                  style: pw.TextStyle(
                    font: base,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== New: Day-style PDF mirroring Excel (categories, expenses, grand total) =====
  static Future<File> createDayStylePdf(
    DateTime date, {
    String? logoAsset,
    String appName = 'مشترياتي',
    String? userName,
    String? contact,
    String? extraInfo,
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();

    final menus = await menuRepo.list(date: _dateStr(date));
    final cats = await catRepo.getAll();
    final catNames = {for (final c in cats) c.id: c.name};

    // Prefetch items per menu to avoid async in build
    final Map<String, List<dynamic>> itemsByMenu = {};
    for (final m in menus) {
      itemsByMenu[m.id] = await itemRepo.listByMenu(m.id);
    }

    final doc = pw.Document();
    final (arabicFont, arabicBold) = await _loadArabicFonts();
    Uint8List? logoBytes;
    if (logoAsset != null) {
      try {
        final lb = await rootBundle.load(logoAsset);
        logoBytes = lb.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }
    }

    final printedAt = 'تم الإنشاء: ${DateTime.now()}';
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        header:
            (context) => _pageHeader(
              appName: appName,
              title: 'المشتريات النقدية (${_dateStr(date)})',
              base: arabicFont,
              bold: arabicBold,
              logoBytes: logoBytes,
              userName: userName,
              contact: contact,
              extraInfo: extraInfo,
            ),
        footer:
            (context) => _pageFooter(
              base: arabicFont,
              pageNumber: context.pageNumber,
              pagesCount: context.pagesCount,
              appName: appName,
              printedAt: printedAt,
            ),
        build: (context) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.SizedBox(height: 8));

          for (final menu in menus) {
            widgets.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: _sectionTitle(
                  '${menu.name} ${_dateStr(date)}',
                  arabicBold,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));

            final items = itemsByMenu[menu.id] ?? const <dynamic>[];
            double totalSum = 0;
            final rows = <pw.TableRow>[];
            rows.add(
              _modernHeaderRow(
                ['اسم الفئة', 'الكمية', 'السعر', 'الإجمالي'],
                arabicFont,
                arabicBold,
              ),
            );
            for (var i = 0; i < items.length; i++) {
              final it = items[i];
              final lineTotal =
                  it.total != 0 ? it.total : (it.qty * it.unitPrice);
              totalSum += lineTotal;
              final name = catNames[it.categoryId] ?? 'غير محدد';
              rows.add(
                _modernDataRow(
                  [
                    name,
                    it.qty.toString(),
                    it.unitPrice.toStringAsFixed(2),
                    lineTotal.toStringAsFixed(2),
                  ],
                  arabicFont,
                  alt: (i % 2 == 1),
                ),
              );
            }

            final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
            final double transport =
                (menu.transportationExpenses ?? 0).toDouble();
            final grand = totalSum + stationery + transport;

            // Expenses rows
            rows.add(
              _modernDataRow([
                'مصاريف القرطاسية',
                '',
                '',
                stationery.toStringAsFixed(2),
              ], arabicBold),
            );
            rows.add(
              _modernDataRow([
                'مصاريف النقل',
                '',
                '',
                transport.toStringAsFixed(2),
              ], arabicBold),
            );

            // Grand total row
            rows.add(
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _headerBg),
                children: [
                  ...['الإجمالي', '', '', grand.toStringAsFixed(2)].map(
                    (c) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(width: 0.5),
                          bottom: pw.BorderSide(width: 0.5),
                          left: pw.BorderSide(width: 0.5),
                          right: pw.BorderSide(width: 0.5),
                        ),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        c,
                        style: pw.TextStyle(font: arabicBold, fontSize: 12),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ),
                ],
              ),
            );

            widgets.add(
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: rows,
              ),
            );
            widgets.add(pw.SizedBox(height: 12));
          }

          return widgets;
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/day_purchases_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  // ===== New: Single menu PDF mirroring Excel (with notes, expenses, total) =====
  static Future<File> createMenuStylePdf(
    String menuId, {
    String? logoAsset,
    String appName = 'مشترياتي',
    String? userName,
    String? contact,
    String? extraInfo,
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();

    final menu = await menuRepo.getById(menuId);
    if (menu == null) {
      throw Exception('❌ لم يتم العثور على القائمة المطلوبة');
    }
    final items = await itemRepo.listByMenu(menuId);
    final cats = await catRepo.getAll();
    final catNames = {for (final c in cats) c.id: c.name};

    final doc = pw.Document();
    final (arabicFont, arabicBold) = await _loadArabicFonts();
    Uint8List? logoBytes;
    if (logoAsset != null) {
      try {
        final lb = await rootBundle.load(logoAsset);
        logoBytes = lb.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }
    }

    final printedAt = 'تم الإنشاء: ${DateTime.now()}';
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        header:
            (context) => _pageHeader(
              appName: appName,
              title: 'تقرير قائمة: ${menu.name}',
              base: arabicFont,
              bold: arabicBold,
              logoBytes: logoBytes,
              userName: userName,
              contact: contact,
              extraInfo: extraInfo,
            ),
        footer:
            (context) => _pageFooter(
              base: arabicFont,
              pageNumber: context.pageNumber,
              pagesCount: context.pagesCount,
              appName: appName,
              printedAt: printedAt,
            ),
        build: (context) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.SizedBox(height: 8));

          double totalSum = 0;
          final rows = <pw.TableRow>[];
          rows.add(
            _modernHeaderRow(
              ['اسم الفئة', 'الكمية', 'السعر', 'الإجمالي', 'الملاحظات'],
              arabicFont,
              arabicBold,
            ),
          );
          for (var i = 0; i < items.length; i++) {
            final it = items[i];
            final lineTotal =
                it.total != 0 ? it.total : (it.qty * it.unitPrice);
            totalSum += lineTotal;
            final name = catNames[it.categoryId] ?? 'غير محدد';
            rows.add(
              _modernDataRow(
                [
                  name,
                  it.qty.toString(),
                  it.unitPrice.toStringAsFixed(2),
                  lineTotal.toStringAsFixed(2),
                  it.notes ?? '',
                ],
                arabicFont,
                alt: (i % 2 == 1),
              ),
            );
          }

          final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
          final double transport =
              (menu.transportationExpenses ?? 0).toDouble();
          final grand = totalSum + stationery + transport;

          // Expenses rows (values in total column)
          rows.add(
            _modernDataRow([
              'مصاريف القرطاسية',
              '',
              '',
              stationery.toStringAsFixed(2),
              '',
            ], arabicBold),
          );
          rows.add(
            _modernDataRow([
              'مصاريف النقل',
              '',
              '',
              transport.toStringAsFixed(2),
              '',
            ], arabicBold),
          );

          // Grand total row
          rows.add(
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _headerBg),
              children: [
                ...['الإجمالي', '', '', grand.toStringAsFixed(2), ''].map(
                  (c) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(width: 0.5),
                        bottom: pw.BorderSide(width: 0.5),
                        left: pw.BorderSide(width: 0.5),
                        right: pw.BorderSide(width: 0.5),
                      ),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      c,
                      style: pw.TextStyle(font: arabicBold, fontSize: 12),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),
              ],
            ),
          );

          widgets.add(
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(2),
              },
              children: rows,
            ),
          );

          return widgets;
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/menu_${menu.id}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  // ===== New: Period PDF (sheets per day OR summary) mirroring Excel =====
  static Future<File> createPeriodStylePdf({
    required DateTime startDate,
    required String periodType, // "week" or "month"
    String reportType = "sheets", // "sheets" or "summary"
    String? logoAsset,
    String appName = 'مشترياتي',
    String? userName,
    String? contact,
    String? extraInfo,
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();

    // Determine end date
    DateTime endDate;
    if (periodType == "week") {
      endDate = startDate.add(const Duration(days: 6));
    } else {
      endDate = DateTime(startDate.year, startDate.month + 1, 0);
    }

    final cats = await catRepo.getAll();
    final catNames = {for (final c in cats) c.id: c.name};

    final doc = pw.Document();
    final (arabicFont, arabicBold) = await _loadArabicFonts();
    Uint8List? logoBytes;
    if (logoAsset != null) {
      try {
        final lb = await rootBundle.load(logoAsset);
        logoBytes = lb.buffer.asUint8List();
      } catch (_) {
        logoBytes = null;
      }
    }

    if (reportType == 'sheets') {
      // Prefetch all data to avoid async in build
      final List<_DayMenusData> daysData = [];
      for (
        DateTime d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        final dateStr = _dateStr(d);
        final menus = await menuRepo.list(date: dateStr);
        final List<_MenuItemsData> menuData = [];
        for (final m in menus) {
          final items = await itemRepo.listByMenu(m.id);
          menuData.add(_MenuItemsData(menu: m, items: items));
        }
        daysData.add(_DayMenusData(dateStr: dateStr, menus: menuData));
      }

      final printedAt = 'تم الإنشاء: ${DateTime.now()}';
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
          header:
              (context) => _pageHeader(
                appName: appName,
                title: 'تقرير الفترة',
                base: arabicFont,
                bold: arabicBold,
                logoBytes: logoBytes,
                userName: userName,
                contact: contact,
                extraInfo: extraInfo,
              ),
          footer:
              (context) => _pageFooter(
                base: arabicFont,
                pageNumber: context.pageNumber,
                pagesCount: context.pagesCount,
                appName: appName,
                printedAt: printedAt,
              ),
          build: (context) {
            final widgets = <pw.Widget>[];
            for (final day in daysData) {
              if (day.menus.isEmpty) continue;
              widgets.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Center(
                    child: pw.Text(
                      'تقرير المشتريات ليوم ${day.dateStr}',
                      style: pw.TextStyle(font: arabicBold, fontSize: 14),
                    ),
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 8));
              for (final md in day.menus) {
                final menu = md.menu;
                widgets.add(
                  pw.Directionality(
                    textDirection: pw.TextDirection.rtl,
                    child: _sectionTitle(
                      '${menu.name} ${day.dateStr}',
                      arabicBold,
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 6));

                double totalSum = 0;
                final rows = <pw.TableRow>[];
                rows.add(
                  _modernHeaderRow(
                    ['اسم الفئة', 'الكمية', 'السعر', 'الإجمالي'],
                    arabicFont,
                    arabicBold,
                  ),
                );
                for (var i = 0; i < md.items.length; i++) {
                  final it = md.items[i];
                  final lineTotal =
                      it.total != 0 ? it.total : (it.qty * it.unitPrice);
                  totalSum += lineTotal;
                  rows.add(
                    _modernDataRow(
                      [
                        catNames[it.categoryId] ?? 'غير محدد',
                        it.qty.toString(),
                        it.unitPrice.toStringAsFixed(2),
                        lineTotal.toStringAsFixed(2),
                      ],
                      arabicFont,
                      alt: (i % 2 == 1),
                    ),
                  );
                }

                final double stationery =
                    (menu.stationeryExpenses ?? 0).toDouble();
                final double transport =
                    (menu.transportationExpenses ?? 0).toDouble();
                final grand = totalSum + stationery + transport;

                rows.add(
                  _modernDataRow([
                    'مصاريف القرطاسية',
                    '',
                    '',
                    stationery.toStringAsFixed(2),
                  ], arabicBold),
                );
                rows.add(
                  _modernDataRow([
                    'مصاريف النقل',
                    '',
                    '',
                    transport.toStringAsFixed(2),
                  ], arabicBold),
                );

                rows.add(
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _headerBg),
                    children: [
                      ...['الإجمالي', '', '', grand.toStringAsFixed(2)].map(
                        (c) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(width: 0.5),
                              bottom: pw.BorderSide(width: 0.5),
                              left: pw.BorderSide(width: 0.5),
                              right: pw.BorderSide(width: 0.5),
                            ),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            c,
                            style: pw.TextStyle(font: arabicBold, fontSize: 12),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                widgets.add(
                  pw.Table(
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(1),
                      2: pw.FlexColumnWidth(1),
                      3: pw.FlexColumnWidth(1),
                    },
                    children: rows,
                  ),
                );
                widgets.add(pw.SizedBox(height: 12));
              }
            }
            return widgets;
          },
        ),
      );
    } else {
      // summary mode
      final rows = <List<String>>[];
      for (
        DateTime d = startDate;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        final dateStr = _dateStr(d);
        final menus = await menuRepo.list(date: dateStr);
        for (final menu in menus) {
          final items = await itemRepo.listByMenu(menu.id);
          final itemsTotal = items.fold<double>(
            0,
            (sum, it) =>
                sum + (it.total != 0 ? it.total : (it.qty * it.unitPrice)),
          );
          final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
          final double transport =
              (menu.transportationExpenses ?? 0).toDouble();
          final grand = itemsTotal + stationery + transport;
          rows.add([
            'اليوم ${d.day}',
            menu.name,
            grand.toStringAsFixed(2),
            items.length.toString(),
            dateStr,
          ]);
        }
      }

      final printedAt = 'تم الإنشاء: ${DateTime.now()}';
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
          header:
              (context) => _pageHeader(
                appName: appName,
                title: 'ملخص الفترة',
                base: arabicFont,
                bold: arabicBold,
                logoBytes: logoBytes,
                userName: userName,
                contact: contact,
                extraInfo: extraInfo,
              ),
          footer:
              (context) => _pageFooter(
                base: arabicFont,
                pageNumber: context.pageNumber,
                pagesCount: context.pagesCount,
                appName: appName,
                printedAt: printedAt,
              ),
          build:
              (context) => [
                pw.SizedBox(height: 8),
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.TableHelper.fromTextArray(
                    headers: const [
                      'اليوم',
                      'الفرع',
                      'الإجمالي',
                      'عدد الأصناف',
                      'تاريخ',
                    ],
                    data: rows,
                    headerStyle: pw.TextStyle(font: arabicBold, fontSize: 12),
                    cellStyle: pw.TextStyle(font: arabicFont, fontSize: 11),
                    headerDecoration: const pw.BoxDecoration(color: _headerBg),
                    cellAlignments: const {
                      0: pw.Alignment.centerRight,
                      1: pw.Alignment.centerRight,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerRight,
                      4: pw.Alignment.centerRight,
                    },
                  ),
                ),
              ],
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final outName =
        '${reportType}_${periodType}_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/$outName.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  /// Create a PDF report for a specific menu. Adds numbering, total calculation and footer.
  static Future<File> createPdfReportForMenu({
    required String menuName,
    required List<Map<String, dynamic>> rows,
    String? logoAsset,
    String? fontAsset,
    String appName = 'مشترياتي',
    String? userName,
    String? contact,
    String? extraInfo,
    String totalKey = 'total',
  }) async {
    final doc = pw.Document();
    var (arabicFont, arabicBold) = await _loadArabicFonts();
    if (fontAsset != null) {
      try {
        final fontData = await rootBundle.load(fontAsset);
        arabicFont = pw.Font.ttf(fontData);
        arabicBold = arabicBold ?? arabicFont;
      } catch (_) {}
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
    final headersWithIndex =
        <String>['رقم'] + headers.map((h) => h.toString()).toList();

    double totalSum = 0.0;
    final dataWithIndex = <List<String>>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final rowValues = <String>[];

      dynamic totalCandidate;
      final possibleTotalKeys = [
        totalKey,
        'الإجمالي',
        'total',
        'total_price',
        'مجموع',
        'sum',
        'المجموع',
        'price_total',
      ];
      for (final k in possibleTotalKeys) {
        if (r.containsKey(k)) {
          totalCandidate = r[k];
          break;
        }
      }
      if (totalCandidate == null && r.isNotEmpty)
        totalCandidate = r[r.keys.last];

      double parsed = 0.0;
      if (totalCandidate != null) {
        if (totalCandidate is num)
          parsed = totalCandidate.toDouble();
        else
          parsed =
              double.tryParse(totalCandidate.toString().replaceAll(',', '.')) ??
              0.0;
      }
      totalSum += parsed;

      rowValues.add('${i + 1}');
      for (final h in headers) rowValues.add((r[h] ?? '').toString());
      dataWithIndex.add(rowValues);
    }

    final printedAt = 'تم الإنشاء: ${DateTime.now()}';
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        header:
            (context) => _pageHeader(
              appName: appName,
              title: 'تقرير القائمة: $menuName',
              base: arabicFont,
              bold: arabicBold,
              logoBytes: logoBytes,
              userName: userName,
              contact: contact,
              extraInfo: extraInfo,
            ),
        footer:
            (context) => _pageFooter(
              base: arabicFont,
              pageNumber: context.pageNumber,
              pagesCount: context.pagesCount,
              appName: appName,
              printedAt: printedAt,
            ),
        build: (context) {
          final w = <pw.Widget>[];

          w.add(pw.SizedBox(height: 12));

          w.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.TableHelper.fromTextArray(
                headers: headersWithIndex,
                data: dataWithIndex,
                headerStyle: pw.TextStyle(
                  font: arabicBold ?? arabicFont,
                  fontSize: 12,
                ),
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

          w.add(pw.SizedBox(height: 8));
          w.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'عدد العناصر: ${rows.length}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'الإجمالي الكلي: ${totalSum.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );

          return w;
        },
      ),
    );

    final bytes = await doc.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/report_menu_${menuName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? 'تصدير الملف',
        text: text ?? '',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Share error: $e');
    }
  }
}
