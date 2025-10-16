import 'dart:io';
import 'package:get/get.dart';
import '../../../core/services/excel_services.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../data/providers/local/sqlite_provider.dart';

class ReportsController extends GetxController {
  // Filters/state
  final selectedBranchId = RxnString();
  final period = 'month'.obs; // 'day' | 'week' | 'month' | 'custom'
  final chartMode = 'month'.obs; // 'month' | 'week'
  final customFromMs = RxnInt(); // millisecondsSinceEpoch
  final customToMs = RxnInt();

  void setBranch(String? id) => selectedBranchId.value = id;
  void setPeriod(String p) => period.value = p;
  void setChartMode(String m) => chartMode.value = m;
  void setCustomRange(DateTime? from, DateTime? to) {
    customFromMs.value = from?.millisecondsSinceEpoch;
    customToMs.value = to?.millisecondsSinceEpoch;
  }

  void reset() {
    selectedBranchId.value = null;
    period.value = 'month';
    chartMode.value = 'month';
    customFromMs.value = null;
    customToMs.value = null;
    update();
  }

  Future<File> generateStyledPdf({
    required DateTime startDate,
    required DateTime endDate,
    required String periodKey,
    String reportType = 'sheets',
    String? branchId,
    String? logoAsset,
    String appName = 'مشترياتي',
    String? userName,
    String? contact,
    String? extraInfo,
  }) async {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (periodKey == 'day') {
      return PdfService.createDayStylePdf(
        normalizedStart,
        branchId: branchId,
        logoAsset: logoAsset,
        appName: appName,
        userName: userName,
        contact: contact,
        extraInfo: extraInfo,
      );
    }

    final exportPeriod =
        periodKey == 'week'
            ? 'week'
            : periodKey == 'month'
            ? 'month'
            : 'custom';

    return PdfService.createPeriodStylePdf(
      startDate: normalizedStart,
      periodType: exportPeriod,
      reportType: reportType,
      branchId: branchId,
      endDateOverride: normalizedEnd,
      logoAsset: logoAsset,
      appName: appName,
      userName: userName,
      contact: contact,
      extraInfo: extraInfo,
    );
  }

  Future<File> generateStyledExcel({
    required DateTime startDate,
    required DateTime endDate,
    required String periodKey,
    String reportType = 'sheets',
    String? branchId,
  }) async {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (periodKey == 'day') {
      return ExcelExportServices.createDayStyleExcel(
        normalizedStart,
        branchId: branchId,
      );
    }

    final exportPeriod =
        periodKey == 'week'
            ? 'week'
            : periodKey == 'month'
            ? 'month'
            : 'custom';

    return ExcelExportServices.createPeriodStyleExcel(
      startDate: normalizedStart,
      periodType: exportPeriod,
      reportType: reportType,
      branchId: branchId,
      endDateOverride: normalizedEnd,
    );
  }

  // ---- Export helpers (generate files) ----
  Future<File> generatePdf({
    required List<Map<String, dynamic>> monthly,
    required List<Map<String, dynamic>> weekly,
    required List<Map<String, dynamic>> recent,
    Map<String, String?>? filters,
    String? logoAsset,
    String? fontAsset,
  }) async {
    return ExportService.createPdfReport(
      monthly: monthly,
      weekly: weekly,
      recent: recent,
      filters: filters,
      logoAsset: logoAsset,
      fontAsset: fontAsset,
    );
  }

  Future<File> generateExcelRecent() async {
    final db = await SqliteProvider.database;
    final rows = await db.rawQuery(
      'SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC',
    );
    return ExportService.createExcelReport(
      rows: rows.cast<Map<String, dynamic>>(),
    );
  }

  Future<File> generateCsvRecent({String prefix = 'purchases'}) async {
    final db = await SqliteProvider.database;
    final rows = await db.rawQuery(
      'SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC',
    );
    return ExportService.createCsvReport(
      rows: rows.cast<Map<String, dynamic>>(),
      filenamePrefix: prefix,
    );
  }
}
