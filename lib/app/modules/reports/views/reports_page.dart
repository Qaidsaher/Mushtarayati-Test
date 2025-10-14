import 'package:flutter/material.dart';
import '../../../data/services/report_service.dart';
import '../../../data/providers/local/sqlite_provider.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/category_model.dart';
// file operations and sharing moved to ExportService
import '../../../core/services/export_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _svc = ReportService();
  List<Map<String, dynamic>> _monthly = [];
  List<Map<String, dynamic>> _weekly = [];
  List<Map<String, dynamic>> _recent = [];
  List<BranchModel> _branches = [];
  List<CategoryModel> _categories = [];

  String? _selectedBranchId;
  String? _selectedCategoryId;
  String _period = 'month'; // day | week | month | custom
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;
    // prepare filters
    final branchId = _selectedBranchId;
    final categoryId = _selectedCategoryId;

    final monthly = await _svc.monthlyTotals(year: year, month: month, branchId: branchId, categoryId: categoryId);
    final weekly = await _svc.weeklyTotals(weeks: 8, branchId: branchId, categoryId: categoryId);

    final db = await SqliteProvider.database;
    // Recent items (filtered)
    final whereParts = ['items.deleted = 0'];
    final args = <Object?>[];
    if (branchId != null) {
      whereParts.add('menus.branch_id = ?');
      args.add(branchId);
    }
    if (categoryId != null) {
      whereParts.add('items.category_id = ?');
      args.add(categoryId);
    }
    final where = whereParts.join(' AND ');
    final rows = await db.rawQuery('SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE $where ORDER BY items.updated_at DESC LIMIT 50', args);

    // load branches/categories for filters
    final branchRepo = BranchRepository();
    final catRepo = CategoryRepository();
    final branches = await branchRepo.getAll();
    final categories = await catRepo.getAll();

    setState(() {
      _monthly = monthly;
      _weekly = weekly;
      _recent = rows;
      _branches = branches;
      _categories = categories;
    });
  }

  Future<void> _runCustom() async {
    // If custom range provided, query ReportService via raw SQL or extend service.
    if (_customFrom == null || _customTo == null) {
      await _loadData();
      return;
    }
    final db = await SqliteProvider.database;
    final start = _customFrom!.millisecondsSinceEpoch;
    final end = _customTo!.millisecondsSinceEpoch;
    final args = <Object?>[start, end];
    var where = 'items.updated_at BETWEEN ? AND ? AND items.deleted = 0';
    if (_selectedBranchId != null) {
      where += ' AND menus.branch_id = ?';
      args.add(_selectedBranchId);
    }
    if (_selectedCategoryId != null) {
      where += ' AND items.category_id = ?';
      args.add(_selectedCategoryId);
    }
    final rows = await db.rawQuery('SELECT date(items.updated_at / 1000, "unixepoch") as day, SUM(items.total) as total FROM items JOIN menus ON menus.id = items.menu_id WHERE $where GROUP BY day ORDER BY day ASC', args);
    setState(() {
      _monthly = rows;
    });
  }

  Widget _buildCard(String title, Widget child) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            child
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          bottom: const TabBar(tabs: [Tab(text: 'نظرة عامة'), Tab(text: 'الجدول'), Tab(text: 'تصدير')]),
        ),
        body: TabBarView(children: [
          // Overview
          RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('نظرة عامة', style: Theme.of(context).textTheme.titleLarge)),
                const SizedBox(height: 12),
                // filters card (compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(child: DropdownButtonFormField<String?>(value: _selectedBranchId, decoration: const InputDecoration(labelText: 'الفرع'), items: [const DropdownMenuItem(value: null, child: Text('كل الفروع')), ..._branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))], onChanged: (v) => setState(() => _selectedBranchId = v))),
                            const SizedBox(width: 8),
                            Expanded(child: DropdownButtonFormField<String?>(value: _selectedCategoryId, decoration: const InputDecoration(labelText: 'التصنيف'), items: [const DropdownMenuItem(value: null, child: Text('كل التصنيفات')), ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))], onChanged: (v) => setState(() => _selectedCategoryId = v))),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [Expanded(child: DropdownButtonFormField<String>(value: _period, decoration: const InputDecoration(labelText: 'المدى'), items: const [DropdownMenuItem(value: 'day', child: Text('يومي')), DropdownMenuItem(value: 'week', child: Text('أسبوعي')), DropdownMenuItem(value: 'month', child: Text('شهري')), DropdownMenuItem(value: 'custom', child: Text('مخصص'))], onChanged: (v) => setState(() => _period = v ?? 'month'))), const SizedBox(width: 8), ElevatedButton(onPressed: () async { if (_period == 'custom') await _runCustom(); else await _loadData(); }, child: const Text('تشغيل'))]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Cards and mini chart
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildCard('مجموع اليوميات لهذا الشهر', _monthly.isEmpty ? const Text('لا توجد بيانات') : SizedBox(height: 120, child: _MiniBarChart(data: _monthly.map((e) => (e['total'] ?? 0) as num).toList())))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildCard('المجموع الأسبوعي (8 أسابيع)', _weekly.isEmpty ? const Text('لا توجد بيانات') : SizedBox(height: 120, child: _MiniBarChart(data: _weekly.map((e) => (e['total'] ?? 0) as num).toList())))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildCard('آخر المشتريات', _recent.isEmpty ? const Text('لا توجد مشتريات') : Column(children: _recent.map((r) { final qty = r['qty'] ?? 0; final up = r['unit_price'] ?? 0; final tot = r['total'] ?? (qty * up); return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(r['notes'] ?? 'عنصر', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text('$tot ريال'), subtitle: Text('الكمية: $qty • الفرع: ${r['branch_id'] ?? '-'}')); }).toList()))),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Table view
          RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: DataTable(
                columns: const [DataColumn(label: Text('ملاحظة')), DataColumn(label: Text('الكمية')), DataColumn(label: Text('سعر الوحدة')), DataColumn(label: Text('المجموع')), DataColumn(label: Text('الفرع'))],
                rows: _recent.map((r) => DataRow(cells: [DataCell(Text(r['notes'] ?? 'عنصر')), DataCell(Text('${r['qty'] ?? 0}')), DataCell(Text('${r['unit_price'] ?? 0}')), DataCell(Text('${r['total'] ?? ((r['qty'] ?? 0) * (r['unit_price'] ?? 0))}')), DataCell(Text('${r['branch_id'] ?? '-'}'))])).toList(),
              ),
            ),
          ),

          // Export tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تصدير البيانات', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ElevatedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download), label: const Text('تصدير المشتريات (CSV)')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: _exportSummaryCsv, icon: const Icon(Icons.insert_chart), label: const Text('تصدير الملخص (CSV)')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: _exportExcel, icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final db = await SqliteProvider.database;
    final rows = await db.rawQuery('SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC');
    final file = await ExportService.createCsvReport(rows: rows.cast<Map<String, dynamic>>(), filenamePrefix: 'purchases');
    if (!mounted) return;
    final conf = await ExportService.showConfirmDialog(context, 'تصدير CSV');
    if (conf == null) return;
    await ExportService.shareFile(file, subject: 'تقرير المشتريات (CSV)', text: 'ملف المشتريات');
  }

  Future<void> _exportSummaryCsv() async {
    final file = await ExportService.createCsvReport(rows: _monthly.cast<Map<String, dynamic>>(), filenamePrefix: 'summary');
    if (!mounted) return;
    final conf = await ExportService.showConfirmDialog(context, 'تصدير الملخص (CSV)');
    if (conf == null) return;
    await ExportService.shareFile(file, subject: 'ملخص المشتريات', text: 'ملخص شهري');
  }

  Future<void> _exportPdf() async {
    final conf = await ExportService.showConfirmDialog(context, 'تصدير PDF');
    if (conf == null) return;
    final file = await ExportService.createPdfReport(monthly: _monthly, weekly: _weekly, recent: _recent, filters: {'branch': _selectedBranchId, 'category': _selectedCategoryId});
    await ExportService.shareFile(file, subject: 'تقرير المشتريات (PDF)', text: 'تقرير المشتريات');
  }

  Future<void> _exportExcel() async {
    final db = await SqliteProvider.database;
    final rows = await db.rawQuery('SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC');
    final file = await ExportService.createExcelReport(rows: rows.cast<Map<String, dynamic>>());
    if (!mounted) return;
    final conf = await ExportService.showConfirmDialog(context, 'تصدير Excel');
    if (conf == null) return;
    await ExportService.shareFile(file, subject: 'تقرير المشتريات (Excel)', text: 'ملف Excel للمشتريات');
  }

}

class _MiniBarChart extends StatelessWidget {
  final List<num> data;
  const _MiniBarChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('لا توجد بيانات'));
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return LayoutBuilder(builder: (context, constraints) {
      final barWidth = (constraints.maxWidth / data.length) - 4;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((v) {
          final h = maxVal == 0 ? 0.0 : (v / maxVal) * (constraints.maxHeight - 8);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(width: barWidth.clamp(4, 40), height: h, color: Theme.of(context).colorScheme.primary),
          );
        }).toList(),
      );
    });
  }
}
