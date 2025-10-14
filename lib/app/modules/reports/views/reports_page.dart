import 'package:flutter/material.dart';
// image/chart export helpers removed — keep file minimal and responsive
import 'package:fl_chart/fl_chart.dart';
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
  // loading and error state handled inline by RefreshIndicator and local widgets

  @override
  void initState() {
    super.initState();
    _loadData();
    _largeChartKey = GlobalKey();
    _lineChartKey = GlobalKey();
    _pieChartKey = GlobalKey();
  }

  late GlobalKey _largeChartKey;
  late GlobalKey _lineChartKey;
  late GlobalKey _pieChartKey;

  Future<void> _loadData() async {
    // show pull-to-refresh indicator only; local widgets will rebuild when data arrives
    try {
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
    } catch (e, st) {
      debugPrint('Reports load error: $e\n$st');
      // keep UI simple: show debug print and leave any existing data visible
    } finally {
      if (mounted) setState(() {});
    }
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: LayoutBuilder(builder: (context, headerConstraints) {
                final width = headerConstraints.maxWidth;
                final showLogo = width >= 520; // show logo on medium+ screens
                return Row(children: [
                  if (showLogo) ...[
                    Image.asset('assets/images/logo.png', height: 48),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('لوحة التقارير', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('نظرة عامة على المشتريات والملخصات', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70))
                    ])
                  ),
                  IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh, color: Colors.white), tooltip: 'تحديث')
                ]);
              }),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('نظرة عامة', style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 12),

            // filters card (compact, modern)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Branch & Category filter chips (multi-select)
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        const Text('الفرع:'),
                        ..._branches.map((b) => FilterChip(label: Text(b.name), selected: _selectedBranchId == b.id, onSelected: (s) => setState(() => _selectedBranchId = s ? b.id : null))),
                        const SizedBox(width: 12),
                        const Text('التصنيف:'),
                        ..._categories.map((c) => FilterChip(label: Text(c.name), selected: _selectedCategoryId == c.id, onSelected: (s) => setState(() => _selectedCategoryId = s ? c.id : null))),
                      ]),
                      const SizedBox(height: 12),
                      // Responsive chips + run button
                      LayoutBuilder(builder: (ctx, c) {
                        final narrow = c.maxWidth < 480;
                        return Wrap(alignment: WrapAlignment.start, spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          const Text('المدى: '),
                          ChoiceChip(label: const Text('يومي'), selected: _period == 'day', onSelected: (s) => setState(() => _period = 'day')),
                          ChoiceChip(label: const Text('أسبوعي'), selected: _period == 'week', onSelected: (s) => setState(() => _period = 'week')),
                          ChoiceChip(label: const Text('شهري'), selected: _period == 'month', onSelected: (s) => setState(() => _period = 'month')),
                          ChoiceChip(label: const Text('مخصص'), selected: _period == 'custom', onSelected: (s) => setState(() => _period = 'custom')),
                          if (!narrow) const SizedBox(width: 12),
                          ElevatedButton.icon(onPressed: () async { if (_period == 'custom') await _runCustom(); else await _loadData(); }, icon: const Icon(Icons.play_arrow), label: const Text('تشغيل'))
                        ]);
                      }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Summary stat cards (responsive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 480) {
                  // stack vertically on narrow screens
                  return Column(children: [
                    _StatCard(title: 'إجمالي هذا الشهر', value: _formatCurrency(_monthly.fold<num>(0, (p, e) => p + ((e['total'] ?? 0) as num))), color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    _StatCard(title: 'آخر 8 أسابيع', value: _formatCurrency(_weekly.fold<num>(0, (p, e) => p + ((e['total'] ?? 0) as num))), color: Theme.of(context).colorScheme.secondary),
                  ]);
                }
                return Row(children: [Expanded(child: _StatCard(title: 'إجمالي هذا الشهر', value: _formatCurrency(_monthly.fold<num>(0, (p, e) => p + ((e['total'] ?? 0) as num))), color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 12), Expanded(child: _StatCard(title: 'آخر 8 أسابيع', value: _formatCurrency(_weekly.fold<num>(0, (p, e) => p + ((e['total'] ?? 0) as num))), color: Theme.of(context).colorScheme.secondary))]);
              }),
            ),
            const SizedBox(height: 12),

            // Charts area: responsive layout (stack on narrow screens)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 800;
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('مخطط المبيعات', style: Theme.of(context).textTheme.titleMedium),
                                IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list))
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(height: isNarrow ? 260 : 220, child: RepaintBoundary(key: _largeChartKey, child: _LargeBarChart(monthly: _monthly, weekly: _weekly))),
                        const SizedBox(height: 12),
                        if (isNarrow) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('اتجاهات الشهر', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox.shrink(),
                                ]),
                                const SizedBox(height: 8),
                                SizedBox(height: 140, child: RepaintBoundary(key: _lineChartKey, child: _LineTrendChart(monthly: _monthly)))
                              ]),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('توزيع التصنيفات', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox.shrink(),
                                ]),
                                const SizedBox(height: 8),
                                SizedBox(height: 180, child: RepaintBoundary(key: _pieChartKey, child: _CategoryPieChart(categories: _categories, recent: _recent)))
                              ]),
                            ),
                          ),
                        ] else ...[
                          Row(children: [
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('اتجاهات الشهر', style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox.shrink(),
                                    ]),
                                    const SizedBox(height: 8),
                                    SizedBox(height: 140, child: RepaintBoundary(key: _lineChartKey, child: _LineTrendChart(monthly: _monthly)))
                                  ]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('توزيع التصنيفات', style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox.shrink(),
                                    ]),
                                    const SizedBox(height: 8),
                                    SizedBox(height: 140, child: RepaintBoundary(key: _pieChartKey, child: _CategoryPieChart(categories: _categories, recent: _recent)))
                                  ]),
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),

            // Recent purchases (table-like list)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _buildCard('آخر المشتريات', _recent.isEmpty ? const Text('لا توجد مشتريات') : Column(children: _recent.map((r) { final qty = r['qty'] ?? 0; final up = r['unit_price'] ?? 0; final tot = r['total'] ?? (qty * up); return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(r['notes'] ?? 'عنصر', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text('$tot ريال'), subtitle: Text('الكمية: $qty • الفرع: ${r['branch_id'] ?? '-'}')); }).toList()))),
            const SizedBox(height: 24),

            // Table section
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('الجدول', style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [DataColumn(label: Text('ملاحظة')), DataColumn(label: Text('الكمية')), DataColumn(label: Text('سعر الوحدة')), DataColumn(label: Text('المجموع')), DataColumn(label: Text('الفرع'))],
                  rows: _recent.map((r) => DataRow(cells: [DataCell(Text(r['notes'] ?? 'عنصر')), DataCell(Text('${r['qty'] ?? 0}')), DataCell(Text('${r['unit_price'] ?? 0}')), DataCell(Text('${r['total'] ?? ((r['qty'] ?? 0) * (r['unit_price'] ?? 0))}')), DataCell(Text('${r['branch_id'] ?? '-'}'))])).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Export section
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('تصدير البيانات', style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ElevatedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download), label: const Text('تصدير المشتريات (CSV)')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: _exportSummaryCsv, icon: const Icon(Icons.insert_chart), label: const Text('تصدير الملخص (CSV)')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: _exportExcel, icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
              ]),
            ),
            const SizedBox(height: 48),
          ]),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    // ask for confirmation first, then run the export with progress
    await _confirmThenExport(() async {
      final db = await SqliteProvider.database;
      final rows = await db.rawQuery('SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC');
      return await ExportService.createCsvReport(rows: rows.cast<Map<String, dynamic>>(), filenamePrefix: 'purchases');
    }, confirmTitle: 'تصدير CSV', subject: 'تقرير المشتريات (CSV)', progressLabel: 'جارٍ إعداد CSV...');
  }

  Future<void> _exportSummaryCsv() async {
    await _confirmThenExport(() async => ExportService.createCsvReport(rows: _monthly.cast<Map<String, dynamic>>(), filenamePrefix: 'summary'), confirmTitle: 'تصدير الملخص (CSV)', subject: 'ملخص المشتريات', progressLabel: 'جارٍ إعداد الملخص...');
  }

  Future<void> _exportPdf() async {
    await _confirmThenExport(() => ExportService.createPdfReport(monthly: _monthly, weekly: _weekly, recent: _recent, filters: {'branch': _selectedBranchId, 'category': _selectedCategoryId}), confirmTitle: 'تصدير PDF', subject: 'تقرير المشتريات (PDF)', progressLabel: 'جارٍ إعداد PDF...');
  }

  Future<void> _exportExcel() async {
    await _confirmThenExport(() async {
      final db = await SqliteProvider.database;
      final rows = await db.rawQuery('SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC');
      return await ExportService.createExcelReport(rows: rows.cast<Map<String, dynamic>>() );
    }, confirmTitle: 'تصدير Excel', subject: 'تقرير المشتريات (Excel)', progressLabel: 'جارٍ إنشاء ملف Excel...');
  }

  // Unified helper: ask confirmation, run a long-running export with progress, then share the result.
  Future<void> _confirmThenExport(Future<dynamic> Function() createFile, {required String confirmTitle, required String subject, String? text, String? progressLabel}) async {
    final conf = await ExportService.showConfirmDialog(context, confirmTitle);
    if (conf == null) return;
    try {
      final file = await _withProgress(() => createFile(), label: progressLabel);
      if (!mounted) return;
      await ExportService.shareFile(file, subject: subject, text: text ?? '');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم التصدير: $subject')));
    } catch (e, st) {
      debugPrint('Export error: $e\n$st');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التصدير: ${e.toString()}')));
    }
  }

  // Helper to show an indeterminate progress dialog while running an async task
  Future<T> _withProgress<T>(Future<T> Function() task, {String? label}) async {
    // show dialog
    if (!mounted) return await task();
  showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => WillPopScope(onWillPop: () async => false, child: AlertDialog(content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 16), Expanded(child: Text(label ?? 'جارٍ المعالجة...'))]))));
    try {
      final res = await task();
      return res;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  String _formatCurrency(num value) {
    // Simple formatter: show integer when possible, otherwise show two decimals
    if (value == value.round()) return '${value.toInt()} ريال';
    return '${value.toStringAsFixed(2)} ريال';
  }

  // Chart capture/export helpers removed per request.
  // chart export widgets removed per user request

}

// compact chart removed; use _LargeBarChart for main visuals

// Stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _StatCard({Key? key, required this.title, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(children: [
          Container(width: 8, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 6), Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))])),
        ]),
      ),
    );
  }
}

// Large chart widget with Arabic tooltips
class _LargeBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  final List<Map<String, dynamic>> weekly;
  const _LargeBarChart({Key? key, required this.monthly, required this.weekly}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = monthly.map((e) => (e['total'] ?? 0) as num).toList();
    if (data.isEmpty) return const Center(child: Text('لا توجد بيانات للمخطط'));
    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      final val = data[i].toDouble();
      groups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: val, width: 18, borderRadius: BorderRadius.circular(6), color: Theme.of(context).colorScheme.primary)]));
    }

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxVal == 0 ? 1 : maxVal * 1.2,
      barGroups: groups,
      titlesData: FlTitlesData(show: true, leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(tooltipBgColor: Colors.black87, getTooltipItem: (group, groupIndex, rod, rodIndex) {
        return BarTooltipItem('الإجمالي: ${rod.toY} ريال', const TextStyle(color: Colors.white));
      })),
    ));
  }
}

// Line chart for monthly trend
class _LineTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  const _LineTrendChart({Key? key, required this.monthly}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < monthly.length; i++) {
      final val = (monthly[i]['total'] ?? 0) as num;
      spots.add(FlSpot(i.toDouble(), val.toDouble()));
    }
    if (spots.isEmpty) return const Center(child: Text('لا توجد بيانات'));
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return LineChart(LineChartData(
      minX: 0,
      maxX: spots.length - 1.toDouble(),
      minY: 0,
      maxY: maxY * 1.2,
      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Theme.of(context).colorScheme.primary, barWidth: 3, dotData: FlDotData(show: false))],
      titlesData: FlTitlesData(show: false),
      gridData: FlGridData(show: false),
    ));
  }
}

// Pie chart for category distribution (uses recent items)
class _CategoryPieChart extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<Map<String, dynamic>> recent;
  const _CategoryPieChart({Key? key, required this.categories, required this.recent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // aggregate totals by category id
    final Map<String, double> totals = {};
    for (var r in recent) {
      final cid = (r['category_id'] ?? 'غير محدد').toString();
      final tot = ((r['total'] ?? 0) as num).toDouble();
      totals[cid] = (totals[cid] ?? 0) + tot;
    }
    if (totals.isEmpty) return const Center(child: Text('لا توجد بيانات'));

    final sections = <PieChartSectionData>[];
    final palette = [Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal];
    var i = 0;
    totals.forEach((cid, value) {
      final label = categories.firstWhere((c) => c.id == cid, orElse: () => CategoryModel(id: cid, name: cid)).name;
      sections.add(PieChartSectionData(color: palette[i % palette.length], value: value, title: '${label}\n${value.toStringAsFixed(0)}', radius: 36, titleStyle: const TextStyle(fontSize: 10, color: Colors.white)));
      i++;
    });

    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 18, sectionsSpace: 2));
  }
}
