import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import '../../data/repositories/menu_repository.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/branch_repository.dart';

class ExcelExportServices {
  static Future<File> createDayStyleExcel(
    DateTime date, {
    String? branchId,
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();
    final branchRepo = BranchRepository();

    // === Format date ===
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final menus = await menuRepo.list(date: dateStr, branchId: branchId);
    final cats = await catRepo.getAll();
    final branches = await branchRepo.getAll();
    final branchNames = {for (final b in branches) b.id: b.name};

    // === Create workbook and single sheet ===
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'المشتريات النقدية';

    // === Colors ===
    const sectionColors = ['#FFF8E1', '#E8F5E9', '#E3F2FD', '#FFF3E0'];
    const altRowColor = '#F9F9F9';
    const headerColor = '#FFD966';
    const totalColor = '#FFF59D';

    // === General layout setup ===
    const colsPerSection = 4;
    const dividerWidth = 1;
    const startCol = 1;

    final endCol =
        (colsPerSection + dividerWidth) * menus.length - dividerWidth;

    // === Title row (merged across all sections) ===
    sheet.getRangeByIndex(1, 1, 1, endCol).merge();
    final title = sheet.getRangeByIndex(1, 1);
    title.setText('المشتريات النقدية ($dateStr)');
    title.cellStyle
      ..bold = true
      ..fontSize = 16
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..backColor = headerColor
      ..borders.all.lineStyle = LineStyle.thin;

    // === Border template ===
    final thinBorder = LineStyle.thin;

    // === Loop through menus (side-by-side) ===
    for (var idx = 0; idx < menus.length; idx++) {
      final menu = menus[idx];
      final items = await itemRepo.listByMenu(menu.id);
      final baseCol = startCol + idx * (colsPerSection + dividerWidth);
      final bgColor = sectionColors[idx % sectionColors.length];
      final branchName =
          (menu.branchId != null && branchNames.containsKey(menu.branchId))
              ? branchNames[menu.branchId]!
              : 'فرع غير معروف';

      // --- Section title ---
      sheet.getRangeByIndex(3, baseCol, 3, baseCol + 3).merge();
      final sectionTitle = sheet.getRangeByIndex(3, baseCol);
      sectionTitle.setText('$branchName • ${menu.name} $dateStr');
      sectionTitle.cellStyle
        ..bold = true
        ..fontSize = 13
        ..backColor = bgColor
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;

      // --- Column headers ---
      const headers = ['اسم الفئة', 'الكمية', 'السعر', 'الإجمالي'];
      for (int j = 0; j < headers.length; j++) {
        final headerCell = sheet.getRangeByIndex(4, baseCol + j);
        headerCell.setText(headers[j]);
        headerCell.cellStyle
          ..bold = true
          ..backColor = bgColor
          ..hAlign = HAlignType.center
          ..vAlign = VAlignType.center
          ..borders.all.lineStyle = thinBorder;
      }

      // --- Data rows ---
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

        final rowIndex = i + 5; // data starts at row 5
        final rowData = [
          cat?.name ?? 'غير محدد', // اسم الفئة
          it.qty.toString(),
          it.unitPrice.toStringAsFixed(2),
          lineTotal.toStringAsFixed(2),
        ];

        for (int j = 0; j < rowData.length; j++) {
          final dataCell = sheet.getRangeByIndex(rowIndex, baseCol + j);
          dataCell.setText(rowData[j]);
          dataCell.cellStyle
            ..hAlign = HAlignType.center
            ..vAlign = VAlignType.center
            ..borders.all.lineStyle = thinBorder;
          if (rowIndex.isEven) {
            dataCell.cellStyle.backColor = altRowColor;
          }
        }
      }

      // --- Expenses rows (before total) ---
      final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
      final double transport = (menu.transportationExpenses ?? 0).toDouble();
      final expensesStartRow = items.length + 5;

      // Stationery row (label in first column only)
      final stationeryLabel = sheet.getRangeByIndex(expensesStartRow, baseCol);
      stationeryLabel.setText('مصاريف القرطاسية');
      stationeryLabel.cellStyle
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;
      final stationeryValue = sheet.getRangeByIndex(
        expensesStartRow,
        baseCol + 3,
      );
      stationeryValue.setNumber(stationery);
      stationeryValue.cellStyle
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;
      // Ensure borders across the entire row
      for (int c = 0; c < colsPerSection; c++) {
        final cell = sheet.getRangeByIndex(expensesStartRow, baseCol + c);
        cell.cellStyle
          ..borders.all.lineStyle = thinBorder
          ..hAlign = HAlignType.center
          ..vAlign = VAlignType.center;
      }

      // Transportation row (label in first column only)
      final transportRow = expensesStartRow + 1;
      final transportLabel = sheet.getRangeByIndex(transportRow, baseCol);
      transportLabel.setText('مصاريف النقل');
      transportLabel.cellStyle
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;
      final transportValue = sheet.getRangeByIndex(transportRow, baseCol + 3);
      transportValue.setNumber(transport);
      transportValue.cellStyle
        ..bold = true
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;
      // Ensure borders across the entire row
      for (int c = 0; c < colsPerSection; c++) {
        final cell = sheet.getRangeByIndex(transportRow, baseCol + c);
        cell.cellStyle
          ..borders.all.lineStyle = thinBorder
          ..hAlign = HAlignType.center
          ..vAlign = VAlignType.center;
      }

      // --- Grand total row (items + expenses) ---
      final totalRow = expensesStartRow + 2;
      sheet.getRangeByIndex(totalRow, baseCol, totalRow, baseCol + 2).merge();
      final totalLabel = sheet.getRangeByIndex(totalRow, baseCol);
      totalLabel.setText('الإجـــــــــــــمالـــــــــــي');
      totalLabel.cellStyle
        ..bold = true
        ..backColor = totalColor
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;

      final totalValue = sheet.getRangeByIndex(totalRow, baseCol + 3);
      totalValue.setNumber(totalSum + stationery + transport);
      totalValue.cellStyle
        ..bold = true
        ..backColor = totalColor
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;

      // --- Divider column (spacing) ---
      if (idx < menus.length - 1) {
        final dividerCol = baseCol + colsPerSection;
        sheet.getRangeByIndex(1, dividerCol, totalRow, dividerCol).cellStyle
          ..backColor = '#FFFFFF';
        sheet.setColumnWidthInPixels(dividerCol, 20);
      }

      // --- Adjust column widths ---
      for (int c = 0; c < colsPerSection; c++) {
        sheet.setColumnWidthInPixels(baseCol + c, 100);
      }
    }

    // === Save file ===
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final outName =
        'day_purchases_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/$outName.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// === دالة جديدة لإنشاء ملف Excel لقائمة واحدة فقط ===
  static Future<File> createMenuStyleExcel(String menuId) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final catRepo = CategoryRepository();

    // --- جلب القائمة المحددة ---
    final menu = await menuRepo.getById(menuId);
    if (menu == null) {
      throw Exception('❌ لم يتم العثور على القائمة المطلوبة');
    }

    // --- جلب العناصر والفئات ---
    final items = await itemRepo.listByMenu(menuId);
    final cats = await catRepo.getAll();

    // --- إنشاء ملف Excel ---
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = menu.name;

    // === ألوان التصميم كما في التقرير اليومي ===
    const bgColor = '#E8F5E9';
    const altRowColor = '#F9F9F9';
    const headerColor = '#FFD966';
    const totalColor = '#FFF59D';
    final thinBorder = LineStyle.thin;

    // --- عنوان التقرير ---
    sheet.getRangeByIndex(1, 1, 1, 5).merge();
    final title = sheet.getRangeByIndex(1, 1);
    title.setText('تقرير قائمة: ${menu.name}');
    title.cellStyle
      ..bold = true
      ..fontSize = 16
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..backColor = headerColor
      ..borders.all.lineStyle = thinBorder;

    // --- رؤوس الأعمدة ---
    const headers = ['اسم الفئة', 'الكمية', 'السعر', 'الإجمالي', 'الملاحظات'];
    for (int j = 0; j < headers.length; j++) {
      final headerCell = sheet.getRangeByIndex(3, j + 1);
      headerCell.setText(headers[j]);
      headerCell.cellStyle
        ..bold = true
        ..backColor = bgColor
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;
    }

    // --- صفوف البيانات ---
    double totalSum = 0;
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      CategoryModel? cat;
      try {
        cat = cats.firstWhere((c) => c.id == (it.categoryId ?? ''));
      } catch (_) {
        cat = null;
      }

      final lineTotal = it.total != 0 ? it.total : (it.qty * it.unitPrice);
      totalSum += lineTotal;

      final rowIndex = i + 4;
      final rowData = [
        cat?.name ?? 'غير محدد',
        it.qty.toString(),
        it.unitPrice.toStringAsFixed(2),
        lineTotal.toStringAsFixed(2),
        it.notes ?? '', // ملاحظات إضافية إن وجدت
      ];

      for (int j = 0; j < rowData.length; j++) {
        final dataCell = sheet.getRangeByIndex(rowIndex, j + 1);
        dataCell.setText(rowData[j]);
        dataCell.cellStyle
          ..hAlign = HAlignType.center
          ..vAlign = VAlignType.center
          ..borders.all.lineStyle = thinBorder;
        if (rowIndex.isEven) {
          dataCell.cellStyle.backColor = altRowColor;
        }
      }
    }

    // --- صفوف المصاريف قبل الإجمالي ---
    final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
    final double transport = (menu.transportationExpenses ?? 0).toDouble();
    final expensesStartRow = items.length + 5;

    // مصاريف القرطاسية (ضمن عمود اسم الفئة)
    final stationeryLabel = sheet.getRangeByIndex(expensesStartRow, 1);
    stationeryLabel.setText('مصاريف القرطاسية');
    stationeryLabel.cellStyle
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..borders.all.lineStyle = thinBorder;
    final stationeryValue = sheet.getRangeByIndex(expensesStartRow, 4);
    stationeryValue.setNumber(stationery);
    stationeryValue.cellStyle
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..borders.all.lineStyle = thinBorder;
    // Ensure borders across the entire row
    for (int c = 1; c <= 4; c++) {
      final cell = sheet.getRangeByIndex(expensesStartRow, c);
      cell.cellStyle
        ..borders.all.lineStyle = thinBorder
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center;
    }

    // مصاريف النقل (ضمن عمود اسم الفئة)
    final transportRow = expensesStartRow + 1;
    final transportLabel = sheet.getRangeByIndex(transportRow, 1);
    transportLabel.setText('مصاريف النقل');
    transportLabel.cellStyle
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..borders.all.lineStyle = thinBorder;
    final transportValue = sheet.getRangeByIndex(transportRow, 4);
    transportValue.setNumber(transport);
    transportValue.cellStyle
      ..bold = true
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..borders.all.lineStyle = thinBorder;
    // Ensure borders across the entire row
    for (int c = 1; c <= 4; c++) {
      final cell = sheet.getRangeByIndex(transportRow, c);
      cell.cellStyle
        ..borders.all.lineStyle = thinBorder
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center;
    }

    // --- صف الإجمالي (العناصر + المصاريف) ---
    final totalRow = expensesStartRow + 2;
    sheet.getRangeByIndex(totalRow, 1, totalRow, 3).merge();
    final totalLabel = sheet.getRangeByIndex(totalRow, 1);
    totalLabel.setText('الإجـــــــــــــمالـــــــــــي');
    totalLabel.cellStyle
      ..bold = true
      ..backColor = totalColor
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..borders.all.lineStyle = thinBorder;

    final totalValue = sheet.getRangeByIndex(totalRow, 4);
    totalValue.setNumber(totalSum + stationery + transport);
    totalValue.cellStyle
      ..bold = true
      ..backColor = totalColor
      ..hAlign = HAlignType.center
      ..vAlign = VAlignType.center
      ..borders.all.lineStyle = thinBorder;

    // --- ضبط عرض الأعمدة ---
    for (int c = 1; c <= headers.length; c++) {
      sheet.setColumnWidthInPixels(c, 120);
    }

    // --- حفظ الملف ---
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/menu_${menu.id}.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  static Future<File> createPeriodStyleExcel({
    required DateTime startDate,
    required String periodType, // "week" أو "month" أو "custom"
    String reportType = "sheets", // "sheets" أو "summary"
    String? branchId,
    DateTime? endDateOverride,
  }) async {
    final menuRepo = MenuRepository();
    final itemRepo = ItemRepository();
    final branchRepo = BranchRepository();

    // === تحديد نطاق الأيام بناءً على النوع ===
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    DateTime computedEnd;
    if (periodType == "week") {
      computedEnd = normalizedStart.add(const Duration(days: 6));
    } else if (periodType == "month") {
      computedEnd = DateTime(
        normalizedStart.year,
        normalizedStart.month + 1,
        0,
      );
    } else {
      computedEnd = endDateOverride ?? normalizedStart;
    }

    final DateTime endDate =
        endDateOverride != null
            ? DateTime(
              endDateOverride.year,
              endDateOverride.month,
              endDateOverride.day,
            )
            : computedEnd;

    final Workbook workbook = Workbook();

    // === ألوان ثابتة ===
    const sectionColors = ['#FFF8E1', '#E8F5E9', '#E3F2FD', '#FFF3E0'];
    const altRowColor = '#F9F9F9';
    const headerColor = '#FFD966';
    const totalColor = '#FFF59D';
    final thinBorder = LineStyle.thin;

    // جلب أسماء الفئات لاستخدامها في أوراق الفترة
    final catRepo = CategoryRepository();
    final cats = await catRepo.getAll();
    final Map<String, String> catNames = {for (final c in cats) c.id: c.name};
    final branchNames = {
      for (final b in await branchRepo.getAll()) b.id: b.name,
    };

    if (reportType == "sheets") {
      // === لكل يوم ورقة منفصلة ===
      for (
        DateTime d = normalizedStart;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        final dateStr =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final menus = await menuRepo.list(date: dateStr, branchId: branchId);
        if (menus.isEmpty) continue;

        final sheet = workbook.worksheets.addWithName('يوم ${d.day}');
        const colsPerSection = 4;
        const dividerWidth = 1;
        const startCol = 1;
        final endCol =
            (colsPerSection + dividerWidth) * menus.length - dividerWidth;

        // عنوان اليوم
        sheet.getRangeByIndex(1, 1, 1, endCol).merge();
        final title = sheet.getRangeByIndex(1, 1);
        title
          ..setText('تقرير المشتريات ليوم $dateStr')
          ..cellStyle.bold = true
          ..cellStyle.fontSize = 16
          ..cellStyle.hAlign = HAlignType.center
          ..cellStyle.vAlign = VAlignType.center
          ..cellStyle.backColor = headerColor
          ..cellStyle.borders.all.lineStyle = thinBorder;

        // لكل قائمة
        for (var idx = 0; idx < menus.length; idx++) {
          final menu = menus[idx];
          final items = await itemRepo.listByMenu(menu.id);
          final baseCol = startCol + idx * (colsPerSection + dividerWidth);
          final bgColor = sectionColors[idx % sectionColors.length];
          final branchName =
              (menu.branchId != null && branchNames.containsKey(menu.branchId))
                  ? branchNames[menu.branchId]!
                  : 'فرع غير معروف';

          sheet.getRangeByIndex(3, baseCol, 3, baseCol + 3).merge();
          final sectionTitle = sheet.getRangeByIndex(3, baseCol);
          sectionTitle
            ..setText('$branchName • ${menu.name} $dateStr')
            ..cellStyle.bold = true
            ..cellStyle.fontSize = 13
            ..cellStyle.backColor = bgColor
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;

          // رؤوس الأعمدة
          const headers = ['اسم الفئة', 'الكمية', 'السعر', 'الإجمالي'];
          for (int j = 0; j < headers.length; j++) {
            final headerCell = sheet.getRangeByIndex(4, baseCol + j);
            headerCell
              ..setText(headers[j])
              ..cellStyle.bold = true
              ..cellStyle.backColor = bgColor
              ..cellStyle.hAlign = HAlignType.center
              ..cellStyle.vAlign = VAlignType.center
              ..cellStyle.borders.all.lineStyle = thinBorder;
          }

          double totalSum = 0;
          for (var i = 0; i < items.length; i++) {
            final it = items[i];
            final lineTotal =
                it.total != 0 ? it.total : (it.qty * it.unitPrice);
            totalSum += lineTotal;

            final rowIndex = i + 5;
            final rowData = [
              catNames[it.categoryId ?? ''] ?? 'غير محدد',
              it.qty.toString(),
              it.unitPrice.toStringAsFixed(2),
              lineTotal.toStringAsFixed(2),
            ];
            for (int j = 0; j < rowData.length; j++) {
              final dataCell = sheet.getRangeByIndex(rowIndex, baseCol + j);
              dataCell
                ..setText(rowData[j])
                ..cellStyle.hAlign = HAlignType.center
                ..cellStyle.vAlign = VAlignType.center
                ..cellStyle.borders.all.lineStyle = thinBorder;
              if (rowIndex.isEven) {
                dataCell.cellStyle.backColor = altRowColor;
              }
            }
          }

          // مصاريف قبل الإجمالي
          final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
          final double transport =
              (menu.transportationExpenses ?? 0).toDouble();
          final expensesStartRow = items.length + 5;

          // مصاريف القرطاسية (ضمن عمود اسم الفئة)
          final stationeryLabel = sheet.getRangeByIndex(
            expensesStartRow,
            baseCol,
          );
          stationeryLabel
            ..setText('مصاريف القرطاسية')
            ..cellStyle.bold = true
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;
          final stationeryValue = sheet.getRangeByIndex(
            expensesStartRow,
            baseCol + 3,
          );
          stationeryValue
            ..setNumber(stationery)
            ..cellStyle.bold = true
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;
          // Ensure borders across the entire row
          for (int c = 0; c < colsPerSection; c++) {
            final cell = sheet.getRangeByIndex(expensesStartRow, baseCol + c);
            cell.cellStyle
              ..borders.all.lineStyle = thinBorder
              ..hAlign = HAlignType.center
              ..vAlign = VAlignType.center;
          }

          // مصاريف النقل (ضمن عمود اسم الفئة)
          final transportRow = expensesStartRow + 1;
          final transportLabel = sheet.getRangeByIndex(transportRow, baseCol);
          transportLabel
            ..setText('مصاريف النقل')
            ..cellStyle.bold = true
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;
          final transportValue = sheet.getRangeByIndex(
            transportRow,
            baseCol + 3,
          );
          transportValue
            ..setNumber(transport)
            ..cellStyle.bold = true
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;
          // Ensure borders across the entire row
          for (int c = 0; c < colsPerSection; c++) {
            final cell = sheet.getRangeByIndex(transportRow, baseCol + c);
            cell.cellStyle
              ..borders.all.lineStyle = thinBorder
              ..hAlign = HAlignType.center
              ..vAlign = VAlignType.center;
          }

          // الإجمالي النهائي (العناصر + المصاريف)
          final totalRow = expensesStartRow + 2;
          sheet
              .getRangeByIndex(totalRow, baseCol, totalRow, baseCol + 2)
              .merge();
          final totalLabel = sheet.getRangeByIndex(totalRow, baseCol);
          totalLabel
            ..setText('الإجمالي')
            ..cellStyle.bold = true
            ..cellStyle.backColor = totalColor
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;

          final totalValue = sheet.getRangeByIndex(totalRow, baseCol + 3);
          totalValue
            ..setNumber(totalSum + stationery + transport)
            ..cellStyle.bold = true
            ..cellStyle.backColor = totalColor
            ..cellStyle.hAlign = HAlignType.center
            ..cellStyle.vAlign = VAlignType.center
            ..cellStyle.borders.all.lineStyle = thinBorder;
        }
      }
    } else {
      // === ملخص إجمالي (Sheet واحد) ===
      final sheet = workbook.worksheets[0];
      sheet.name = 'ملخص الفترة';
      sheet.getRangeByIndex(1, 1).setText('اليوم');
      sheet.getRangeByIndex(1, 2).setText('الفرع / القائمة');
      sheet.getRangeByIndex(1, 3).setText('الإجمالي');
      sheet.getRangeByIndex(1, 4).setText('عدد الأصناف');
      sheet.getRangeByIndex(1, 5).setText('تاريخ');

      int row = 2;
      for (
        DateTime d = normalizedStart;
        !d.isAfter(endDate);
        d = d.add(const Duration(days: 1))
      ) {
        final dateStr =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final menus = await menuRepo.list(date: dateStr, branchId: branchId);
        for (var menu in menus) {
          final items = await itemRepo.listByMenu(menu.id);
          final branchName =
              (menu.branchId != null && branchNames.containsKey(menu.branchId))
                  ? branchNames[menu.branchId]!
                  : 'فرع غير معروف';
          final total = items.fold<double>(
            0,
            (sum, it) =>
                sum + (it.total != 0 ? it.total : it.qty * it.unitPrice),
          );
          final double stationery = (menu.stationeryExpenses ?? 0).toDouble();
          final double transport =
              (menu.transportationExpenses ?? 0).toDouble();
          sheet.getRangeByIndex(row, 1).setText('اليوم ${d.day}');
          sheet.getRangeByIndex(row, 2).setText('$branchName • ${menu.name}');
          sheet
              .getRangeByIndex(row, 3)
              .setNumber(total + stationery + transport);
          sheet.getRangeByIndex(row, 4).setNumber(items.length.toDouble());
          sheet.getRangeByIndex(row, 5).setText(dateStr);
          row++;
        }
      }

      // ترويسة الأعمدة
      sheet.getRangeByIndex(1, 1, 1, 5).cellStyle
        ..bold = true
        ..backColor = headerColor
        ..hAlign = HAlignType.center
        ..vAlign = VAlignType.center
        ..borders.all.lineStyle = thinBorder;

      for (int r = 1; r < row; r++) {
        for (int c = 1; c <= 5; c++) {
          sheet.getRangeByIndex(r, c).cellStyle
            ..borders.all.lineStyle = thinBorder
            ..hAlign = HAlignType.center
            ..vAlign = VAlignType.center;
        }
      }
    }

    // === حفظ الملف ===
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final outName =
        '${reportType}_${periodType}_${startDate.year}${startDate.month.toString().padLeft(2, '0')}${startDate.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/$outName.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
