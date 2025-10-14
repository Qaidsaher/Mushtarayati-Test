import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';

class ExcelService {
  static Future<File> createExcelReport({required List<Map<String, dynamic>> rows, String totalKey = 'total'}) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Sheet1'];

    if (rows.isNotEmpty) {
      final headers = rows.first.keys.toList();
      // add numbering column at start
      final headersWithIndex = <String>['رقم'] + headers.map((h) => h.toString()).toList();
      sheet.appendRow(headersWithIndex);

      double totalSum = 0.0;
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        final row = <dynamic>[];
        row.add(i + 1);
        for (final h in headers) {
          row.add(r[h] ?? '');
        }
        sheet.appendRow(row);

        // accumulate total from totalKey or fallback
        dynamic candidate;
        if (r.containsKey(totalKey)) candidate = r[totalKey];
        else if (r.containsKey('الإجمالي')) candidate = r['الإجمالي'];
        else if (r.containsKey('total')) candidate = r['total'];
        if (candidate != null) {
          if (candidate is num) totalSum += candidate.toDouble();
          else totalSum += double.tryParse(candidate.toString().replaceAll(',', '.')) ?? 0.0;
        }
      }

      // append total row
      final totalRow = List<dynamic>.filled(headersWithIndex.length, '');
      totalRow[0] = 'الإجمالي';
      totalRow[headersWithIndex.length - 1] = totalSum.toStringAsFixed(2);
      sheet.appendRow(totalRow);
    }

    final bytes = excel.encode();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/saher_purchases_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File> createExcelForEntity({required String prefix, required List<Map<String, dynamic>> rows, String totalKey = 'total'}) async {
    final file = await createExcelReport(rows: rows, totalKey: totalKey);
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.copy(dest.path);
    return dest;
  }
}
