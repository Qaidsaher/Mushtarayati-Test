import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../data/services/report_service.dart';
import '../../../data/providers/local/sqlite_provider.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/category_model.dart';
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
  String _period = 'month';
  DateTime? _customFrom;
  DateTime? _customTo;

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
    try {
      final now = DateTime.now();
      final month = now.month;
      final year = now.year;
      final branchId = _selectedBranchId;
      final categoryId = _selectedCategoryId;

      final monthly = await _svc.monthlyTotals(
        year: year,
        month: month,
        branchId: branchId,
        categoryId: categoryId,
      );
      final weekly = await _svc.weeklyTotals(
        weeks: 8,
        branchId: branchId,
        categoryId: categoryId,
      );

      final db = await SqliteProvider.database;
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
      final rows = await db.rawQuery(
        'SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE $where ORDER BY items.updated_at DESC LIMIT 50',
        args,
      );

      final branchRepo = BranchRepository();
      final catRepo = CategoryRepository();
      final branches = await branchRepo.getAll();
      final categories = await catRepo.getAll();

      if (mounted) {
        setState(() {
          _monthly = monthly;
          _weekly = weekly;
          _recent = rows;
          _branches = branches;
          _categories = categories;
        });
      }
    } catch (e, st) {
      debugPrint('Reports load error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runCustom() async {
    if (_customFrom == null || _customTo == null) {
      await _loadData();
      return;
    }

    try {
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

      final rows = await db.rawQuery(
        'SELECT date(items.updated_at / 1000, "unixepoch") as day, SUM(items.total) as total FROM items JOIN menus ON menus.id = items.menu_id WHERE $where GROUP BY day ORDER BY day ASC',
        args,
      );

      if (mounted) {
        setState(() => _monthly = rows);
      }
    } catch (e) {
      debugPrint('Custom query error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Modern SliverAppBar with gradient
              _buildModernHeader(context),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Filters section
                    _buildFiltersSection(context),
                    const SizedBox(height: 16),

                    // Summary cards
                    _buildSummaryCards(context),
                    const SizedBox(height: 16),

                    // Charts section
                    _buildChartsSection(context),
                    const SizedBox(height: 16),

                    // Recent purchases
                    _buildRecentPurchases(context),
                    const SizedBox(height: 16),

                    // Export section
                    _buildExportSection(context),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(right: 20, bottom: 16, left: 60),
          title: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'لوحة التقارير',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'نظرة شاملة وتحليلات متقدمة',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          background: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: IconButton(
                  onPressed: _loadData,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: 'تحديث البيانات',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'الفلاتر والتحكم',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Branch filters
            if (_branches.isNotEmpty) ...[
              Text(
                'الفرع:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _branches
                        .map(
                          (b) => FilterChip(
                            label: Text(b.name),
                            selected: _selectedBranchId == b.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedBranchId = selected ? b.id : null;
                                _loadData();
                              });
                            },
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Category filters
            if (_categories.isNotEmpty) ...[
              Text(
                'التصنيف:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _categories
                        .map(
                          (c) => FilterChip(
                            label: Text(c.name),
                            selected: _selectedCategoryId == c.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = selected ? c.id : null;
                                _loadData();
                              });
                            },
                            selectedColor:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Period selection
            Text(
              'الفترة الزمنية:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('يومي'),
                  selected: _period == 'day',
                  onSelected: (s) => setState(() => _period = 'day'),
                ),
                ChoiceChip(
                  label: const Text('أسبوعي'),
                  selected: _period == 'week',
                  onSelected: (s) => setState(() => _period = 'week'),
                ),
                ChoiceChip(
                  label: const Text('شهري'),
                  selected: _period == 'month',
                  onSelected: (s) => setState(() => _period = 'month'),
                ),
                ChoiceChip(
                  label: const Text('مخصص'),
                  selected: _period == 'custom',
                  onSelected: (s) => setState(() => _period = 'custom'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_period == 'custom') {
                    await _runCustom();
                  } else {
                    await _loadData();
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('تطبيق الفلاتر'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final monthlyTotal = _monthly.fold<num>(
      0,
      (sum, e) => sum + ((e['total'] ?? 0) as num),
    );
    final weeklyTotal = _weekly.fold<num>(
      0,
      (sum, e) => sum + ((e['total'] ?? 0) as num),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _StatCard(
                title: 'إجمالي الشهر الحالي',
                value: _formatCurrency(monthlyTotal),
                icon: Icons.calendar_month,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'إجمالي 8 أسابيع',
                value: _formatCurrency(weeklyTotal),
                icon: Icons.date_range,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: 'عدد المشتريات',
                value: '${_recent.length}',
                icon: Icons.shopping_cart,
                color: Colors.green,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'إجمالي الشهر الحالي',
                value: _formatCurrency(monthlyTotal),
                icon: Icons.calendar_month,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'إجمالي 8 أسابيع',
                value: _formatCurrency(weeklyTotal),
                icon: Icons.date_range,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'عدد المشتريات',
                value: '${_recent.length}',
                icon: Icons.shopping_cart,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'التحليلات والرسوم البيانية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'عرض كامل',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main bar chart
            Container(
              height: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: RepaintBoundary(
                key: _largeChartKey,
                child: _LargeBarChart(monthly: _monthly, weekly: _weekly),
              ),
            ),
            const SizedBox(height: 16),

            // Secondary charts
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Column(
                    children: [
                      _buildLineChart(context),
                      const SizedBox(height: 12),
                      _buildPieChart(context),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: _buildLineChart(context)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPieChart(context)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اتجاهات المبيعات',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RepaintBoundary(
              key: _lineChartKey,
              child: _LineTrendChart(monthly: _monthly),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع التصنيفات',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RepaintBoundary(
              key: _pieChartKey,
              child: _CategoryPieChart(
                categories: _categories,
                recent: _recent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchases(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'آخر المشتريات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('لا توجد مشتريات حتى الآن'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recent.length > 10 ? 10 : _recent.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _recent[index];
                  final qty = item['qty'] ?? 0;
                  final unitPrice = item['unit_price'] ?? 0;
                  final total = item['total'] ?? (qty * unitPrice);
                  final notes = item['notes'] ?? 'عنصر';
                  final branchId = item['branch_id'] ?? '-';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.shopping_basket),
                    ),
                    title: Text(
                      notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('الكمية: $qty • الفرع: $branchId'),
                    trailing: Text(
                      _formatCurrency(total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'تصدير البيانات',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportCsv,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('تصدير CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('تصدير PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.file_present),
                  label: const Text('تصدير Excel'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    await _confirmThenExport(
      () async {
        final db = await SqliteProvider.database;
        final rows = await db.rawQuery(
          'SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC',
        );
        return await ExportService.createCsvReport(
          rows: rows.cast<Map<String, dynamic>>(),
          filenamePrefix: 'purchases',
        );
      },
      confirmTitle: 'تصدير CSV',
      subject: 'تقرير المشتريات (CSV)',
      progressLabel: 'جارٍ إعداد ملف CSV...',
    );
  }

  Future<void> _exportPdf() async {
    await _confirmThenExport(
      () => ExportService.createPdfReport(
        monthly: _monthly,
        weekly: _weekly,
        recent: _recent,
        filters: {'branch': _selectedBranchId, 'category': _selectedCategoryId},
      ),
      confirmTitle: 'تصدير PDF',
      subject: 'تقرير المشتريات (PDF)',
      progressLabel: 'جارٍ إعداد ملف PDF...',
    );
  }

  Future<void> _exportExcel() async {
    await _confirmThenExport(
      () async {
        final db = await SqliteProvider.database;
        final rows = await db.rawQuery(
          'SELECT items.*, menus.branch_id FROM items JOIN menus ON menus.id = items.menu_id WHERE items.deleted = 0 ORDER BY items.updated_at DESC',
        );
        return await ExportService.createExcelReport(
          rows: rows.cast<Map<String, dynamic>>(),
        );
      },
      confirmTitle: 'تصدير Excel',
      subject: 'تقرير المشتريات (Excel)',
      progressLabel: 'جارٍ إنشاء ملف Excel...',
    );
  }

  Future<void> _confirmThenExport(
    Future<dynamic> Function() createFile, {
    required String confirmTitle,
    required String subject,
    String? text,
    String? progressLabel,
  }) async {
    try {
      final conf = await ExportService.showConfirmDialog(context, confirmTitle);
      if (conf == null) return;

      final file = await _withProgress(
        () => createFile(),
        label: progressLabel,
      );

      if (!mounted) return;

      await ExportService.shareFile(file, subject: subject, text: text ?? '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم التصدير: $subject'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Export error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التصدير: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<T> _withProgress<T>(Future<T> Function() task, {String? label}) async {
    if (!mounted) return await task();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Expanded(child: Text(label ?? 'جارٍ المعالجة...')),
                ],
              ),
            ),
          ),
    );

    try {
      final res = await task();
      return res;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  String _formatCurrency(num value) {
    if (value == value.round()) {
      return '${value.toInt()} ريال';
    }
    return '${value.toStringAsFixed(2)} ريال';
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Charts
class _LargeBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  final List<Map<String, dynamic>> weekly;

  const _LargeBarChart({required this.monthly, required this.weekly});

  @override
  Widget build(BuildContext context) {
    final data = monthly.map((e) => (e['total'] ?? 0) as num).toList();

    if (data.isEmpty) {
      return const Center(child: Text('لا توجد بيانات للعرض'));
    }

    final maxVal = data.reduce((a, b) => a > b ? a : b).toDouble();
    final groups = <BarChartGroupData>[];

    for (var i = 0; i < data.length; i++) {
      final val = data[i].toDouble();
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              color: Theme.of(context).colorScheme.primary,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal == 0 ? 1 : maxVal * 1.2,
        barGroups: groups,
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 5 : 1,
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'المبلغ: ${rod.toY.toStringAsFixed(0)} ريال',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LineTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;

  const _LineTrendChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];

    for (var i = 0; i < monthly.length; i++) {
      final val = (monthly[i]['total'] ?? 0) as num;
      spots.add(FlSpot(i.toDouble(), val.toDouble()));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<Map<String, dynamic>> recent;

  const _CategoryPieChart({required this.categories, required this.recent});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> totals = {};

    for (var r in recent) {
      final cid = (r['category_id'] ?? 'غير محدد').toString();
      final tot = ((r['total'] ?? 0) as num).toDouble();
      totals[cid] = (totals[cid] ?? 0) + tot;
    }

    if (totals.isEmpty) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final sections = <PieChartSectionData>[];
    final palette = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
    ];

    var i = 0;
    totals.forEach((cid, value) {
      final label =
          categories
              .firstWhere(
                (c) => c.id == cid,
                orElse: () => CategoryModel(id: cid, name: cid),
              )
              .name;

      sections.add(
        PieChartSectionData(
          color: palette[i % palette.length],
          value: value,
          title: '${label}\n${value.toStringAsFixed(0)}',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      i++;
    });

    return PieChart(
      PieChartData(sections: sections, centerSpaceRadius: 20, sectionsSpace: 3),
    );
  }
}
