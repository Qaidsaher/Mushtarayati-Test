import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import '../../../data/providers/local/sqlite_provider.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/models/branch_model.dart';
import '../../../core/services/export_service.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import '../controllers/reports_controller.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _c = Get.put(ReportsController());

  List<Map<String, dynamic>> _recent = [];
  List<BranchModel> _branches = [];
  List<_BranchSnapshot> _branchSnapshots = [];

  bool _loading = true;

  DateTime? _customFrom;
  DateTime? _customTo;

  num _overallSales = 0;
  num _overallStationery = 0;
  num _overallTransport = 0;
  String _periodLabel = '';

  static const _maxTopItemsPerBranch = 6;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) setState(() => _loading = true);

      final now = DateTime.now();
      final rangeConfig = _resolveRange(now);
      final range = rangeConfig.range;
      final branchFilter = _c.selectedBranchId.value;
      final startMs = range.start.millisecondsSinceEpoch;
      final endMs = range.end.millisecondsSinceEpoch;

      final db = await SqliteProvider.database;

      final menuWhereParts = [
        'menus.updated_at BETWEEN ? AND ?',
        'menus.deleted = 0',
      ];
      final menuArgs = <Object?>[startMs, endMs];
      if (branchFilter != null) {
        menuWhereParts.add('menus.branch_id = ?');
        menuArgs.add(branchFilter);
      }

      final branchRows = await db.rawQuery('''
        SELECT menus.branch_id AS branch_id,
               SUM(COALESCE(items.total, 0)) AS total_sales,
               SUM(COALESCE(menus.stationery_expenses, 0)) AS stationery,
               SUM(COALESCE(menus.transportation_expenses, 0)) AS transport,
               COUNT(DISTINCT menus.id) AS menus_count,
               SUM(COALESCE(items.qty, 0)) AS total_qty
        FROM menus
        LEFT JOIN items ON items.menu_id = menus.id AND items.deleted = 0
        WHERE ${menuWhereParts.join(' AND ')}
        GROUP BY menus.branch_id
        ''', menuArgs);

      final itemWhereParts = [
        'items.deleted = 0',
        'menus.deleted = 0',
        'items.updated_at BETWEEN ? AND ?',
      ];
      final itemArgs = <Object?>[startMs, endMs];
      if (branchFilter != null) {
        itemWhereParts.add('menus.branch_id = ?');
        itemArgs.add(branchFilter);
      }

      final itemRows = await db.rawQuery('''
        SELECT menus.branch_id AS branch_id,
               COALESCE(items.notes, 'عنصر') AS item_name,
               SUM(COALESCE(items.total, 0)) AS total_value,
               SUM(COALESCE(items.qty, 0)) AS qty_value
        FROM items
        JOIN menus ON menus.id = items.menu_id
        WHERE ${itemWhereParts.join(' AND ')}
        GROUP BY menus.branch_id, item_name
        ORDER BY menus.branch_id, total_value DESC
        ''', itemArgs);

      final recentWhereParts = [
        'items.deleted = 0',
        'menus.deleted = 0',
        'items.updated_at BETWEEN ? AND ?',
      ];
      final recentArgs = <Object?>[startMs, endMs];
      if (branchFilter != null) {
        recentWhereParts.add('menus.branch_id = ?');
        recentArgs.add(branchFilter);
      }

      final recent = await db.rawQuery('''
        SELECT items.*, menus.branch_id
        FROM items
        JOIN menus ON menus.id = items.menu_id
        WHERE ${recentWhereParts.join(' AND ')}
        ORDER BY items.updated_at DESC
        LIMIT 50
        ''', recentArgs);

      final branchRepo = BranchRepository();
      final branches = await branchRepo.getAll();

      final itemsByBranch = <String, List<_ItemSnapshot>>{};
      for (final row in itemRows) {
        final branchIdValue = row['branch_id'];
        if (branchIdValue == null) continue;
        final branchIdString = branchIdValue.toString();
        final rawName = row['item_name'] as String? ?? 'عنصر';
        final name = rawName.trim().isEmpty ? 'عنصر' : rawName.trim();
        final total = _toNum(row['total_value']);
        final qty = _toInt(row['qty_value']);
        final list = itemsByBranch.putIfAbsent(branchIdString, () => []);
        list.add(_ItemSnapshot(name: name, total: total, qty: qty));
      }

      for (final entry in itemsByBranch.entries) {
        entry.value.sort((a, b) => b.total.compareTo(a.total));
      }

      final snapshots = <_BranchSnapshot>[];
      final seenBranchIds = <String>{};
      num totalSales = 0;
      num totalStationery = 0;
      num totalTransport = 0;

      for (final row in branchRows) {
        final branchIdValue = row['branch_id'];
        if (branchIdValue == null) continue;
        final branchIdString = branchIdValue.toString();
        final branch = _findBranch(branches, branchIdString);
        final sales = _toNum(row['total_sales']);
        final stationery = _toNum(row['stationery']);
        final transport = _toNum(row['transport']);
        final menusCount = _toInt(row['menus_count']);
        final itemsCount = _toInt(row['total_qty']);
        final topItemsSource =
            itemsByBranch[branchIdString] ?? const <_ItemSnapshot>[];
        final topItems = topItemsSource.take(_maxTopItemsPerBranch).toList();

        snapshots.add(
          _BranchSnapshot(
            branch: branch,
            totalSales: sales,
            stationeryExpenses: stationery,
            transportationExpenses: transport,
            menusCount: menusCount,
            itemsCount: itemsCount,
            topItems: topItems,
          ),
        );

        seenBranchIds.add(branchIdString);
        totalSales += sales;
        totalStationery += stationery;
        totalTransport += transport;
      }

      if (branchFilter == null) {
        for (final branch in branches) {
          if (seenBranchIds.contains(branch.id)) continue;
          final topItemsSource =
              itemsByBranch[branch.id] ?? const <_ItemSnapshot>[];
          snapshots.add(
            _BranchSnapshot(
              branch: branch,
              totalSales: 0,
              stationeryExpenses: 0,
              transportationExpenses: 0,
              menusCount: 0,
              itemsCount: 0,
              topItems: topItemsSource.take(_maxTopItemsPerBranch).toList(),
            ),
          );
        }
      } else if (!seenBranchIds.contains(branchFilter)) {
        final branch = _findBranch(branches, branchFilter);
        final topItemsSource =
            itemsByBranch[branchFilter] ?? const <_ItemSnapshot>[];
        snapshots.add(
          _BranchSnapshot(
            branch: branch,
            totalSales: 0,
            stationeryExpenses: 0,
            transportationExpenses: 0,
            menusCount: 0,
            itemsCount: 0,
            topItems: topItemsSource.take(_maxTopItemsPerBranch).toList(),
          ),
        );
      }

      snapshots.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));

      if (mounted) {
        setState(() {
          _recent = recent;
          _branches = branches;
          _branchSnapshots = snapshots;
          _overallSales = totalSales;
          _overallStationery = totalStationery;
          _overallTransport = totalTransport;
          _periodLabel = rangeConfig.label;
          _loading = false;
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
        setState(() => _loading = false);
      }
    }
  }

  _RangeConfig _resolveRange(DateTime reference) {
    final todayStart = DateTime(reference.year, reference.month, reference.day);
    final todayEnd = _endOfDay(reference);

    switch (_c.period.value) {
      case 'day':
        return _RangeConfig(
          DateTimeRange(start: todayStart, end: todayEnd),
          'اليوم',
        );
      case 'week':
        final start = todayStart.subtract(const Duration(days: 6));
        return _RangeConfig(
          DateTimeRange(start: start, end: todayEnd),
          'آخر 7 أيام',
        );
      case 'custom':
        if (_customFrom != null && _customTo != null) {
          final start = DateTime(
            _customFrom!.year,
            _customFrom!.month,
            _customFrom!.day,
          );
          final end = _endOfDay(_customTo!);
          final label = '${_fmtDate(_customFrom!)} → ${_fmtDate(_customTo!)}';
          return _RangeConfig(DateTimeRange(start: start, end: end), label);
        }
        break;
    }

    final monthStart = DateTime(reference.year, reference.month, 1);
    final nextMonth =
        reference.month == 12
            ? DateTime(reference.year + 1, 1, 1)
            : DateTime(reference.year, reference.month + 1, 1);
    final monthEnd = _endOfDay(nextMonth.subtract(const Duration(days: 1)));
    final monthLabel =
        '${monthStart.year}/${monthStart.month.toString().padLeft(2, '0')}';
    return _RangeConfig(
      DateTimeRange(start: monthStart, end: monthEnd),
      'شهر $monthLabel',
    );
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  BranchModel _findBranch(List<BranchModel> branches, String id) {
    for (final branch in branches) {
      if (branch.id == id) return branch;
    }
    return BranchModel(id: id, name: 'فرع غير معروف');
  }

  num _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _resetFilters() {
    setState(() {
      _customFrom = null;
      _customTo = null;
      _c.reset();
    });
    _loadData();
  }

  String _branchNameFor(String? id) {
    if (id == null) return 'غير محدد';
    for (final branch in _branches) {
      if (branch.id == id) return branch.name;
    }
    return 'فرع غير معروف';
  }

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
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
                    _buildFiltersSection(context),
                    const SizedBox(height: 16),
                    _buildSummaryCards(context),
                    const SizedBox(height: 16),
                    _buildBranchPerformanceSection(context),
                    const SizedBox(height: 16),
                    _buildRecentPurchases(context),
                    const SizedBox(height: 16),
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
      actions: [
        IconButton(
          onPressed: _exportPdf,
          icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
          tooltip: 'تصدير PDF',
        ),
        IconButton(
          onPressed: _exportExcel,
          icon: const Icon(Icons.file_present, size: 20, color: Colors.green),
          tooltip: 'تصدير Excel',
        ),
        IconButton(
          onPressed: _printPdf,
          icon: const Icon(Icons.print_rounded, size: 20, color: Colors.blue),
          tooltip: 'طباعة PDF',
        ),
      ],
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
    final theme = Theme.of(context);
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
                Icon(Icons.filter_list, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'الفلاتر والتحكم',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('إعادة الضبط'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_c.period.value == 'custom') ...[
              Text(
                'الفترة المخصصة:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range),
                    label: const Text('اختيار المدى'),
                  ),
                  if (_customFrom != null)
                    Chip(
                      avatar: const Icon(Icons.play_arrow, size: 18),
                      label: Text('من: ${_fmtDate(_customFrom!)}'),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => setState(() => _customFrom = null),
                    ),
                  if (_customTo != null)
                    Chip(
                      avatar: const Icon(Icons.stop, size: 18),
                      label: Text('إلى: ${_fmtDate(_customTo!)}'),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => setState(() => _customTo = null),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_branches.isNotEmpty) ...[
              Text(
                'الفروع:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('الكل'),
                        selected: _c.selectedBranchId.value == null,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => _c.setBranch(null));
                          _loadData();
                        },
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    ..._branches.map(
                      (branch) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(branch.name),
                          selected: _c.selectedBranchId.value == branch.id,
                          onSelected: (selected) {
                            if (!selected) {
                              setState(() => _c.setBranch(null));
                            } else {
                              setState(() => _c.setBranch(branch.id));
                            }
                            _loadData();
                          },
                          selectedColor: theme.colorScheme.primaryContainer,
                          checkmarkColor: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'الفترة الزمنية:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('يومي'),
                  selected: _c.period.value == 'day',
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _c.setPeriod('day');
                      _customFrom = null;
                      _customTo = null;
                    });
                    _loadData();
                  },
                ),
                ChoiceChip(
                  label: const Text('أسبوعي'),
                  selected: _c.period.value == 'week',
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _c.setPeriod('week');
                      _customFrom = null;
                      _customTo = null;
                    });
                    _loadData();
                  },
                ),
                ChoiceChip(
                  label: const Text('شهري'),
                  selected: _c.period.value == 'month',
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _c.setPeriod('month');
                      _customFrom = null;
                      _customTo = null;
                    });
                    _loadData();
                  },
                ),
                ChoiceChip(
                  label: const Text('مخصص'),
                  selected: _c.period.value == 'custom',
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _c.setPeriod('custom'));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_c.period.value == 'custom' &&
                      (_customFrom == null || _customTo == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'يرجى اختيار تاريخ البداية والنهاية للفترة المخصصة.',
                        ),
                      ),
                    );
                    return;
                  }
                  await _loadData();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('تطبيق الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final theme = Theme.of(context);
    const spacing = 12.0;
    final summaryConfigs = [
      _SummaryCardData(
        title: 'إجمالي المبيعات',
        value: _formatCurrency(_overallSales),
        icon: Icons.point_of_sale,
        color: theme.colorScheme.primary,
      ),
      _SummaryCardData(
        title: 'مصروفات القرطاسية',
        value: _formatCurrency(_overallStationery),
        icon: Icons.edit_note,
        color: Colors.orange,
      ),
      _SummaryCardData(
        title: 'مصروفات النقل',
        value: _formatCurrency(_overallTransport),
        icon: Icons.local_shipping,
        color: Colors.teal,
      ),
      _SummaryCardData(
        title: 'الإجمالي الكلي',
        value: _formatCurrency(
          _overallSales + _overallStationery + _overallTransport,
        ),
        icon: Icons.summarize,
        color: Colors.green,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assessment, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'ملخص الفترة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (!_loading && _periodLabel.isNotEmpty)
              Chip(
                label: Text(_periodLabel),
                backgroundColor: theme.colorScheme.surfaceVariant,
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth;
            if (constraints.maxWidth >= 1100) {
              itemWidth = (constraints.maxWidth - spacing * 3) / 4;
            } else if (constraints.maxWidth >= 700) {
              itemWidth = (constraints.maxWidth - spacing) / 2;
            } else {
              itemWidth = constraints.maxWidth;
            }

            if (_loading) {
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(
                  summaryConfigs.length,
                  (_) => SizedBox(
                    width: itemWidth,
                    child: const _ShimmerStatCard(),
                  ),
                ),
              );
            }

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children:
                  summaryConfigs
                      .map(
                        (config) => SizedBox(
                          width: itemWidth,
                          child: _StatCard(
                            title: config.title,
                            value: config.value,
                            icon: config.icon,
                            color: config.color,
                          ),
                        ),
                      )
                      .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBranchPerformanceSection(BuildContext context) {
    final theme = Theme.of(context);
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
                Icon(Icons.storefront, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'أداء الفروع',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_loading && _branchSnapshots.isNotEmpty)
                  Chip(
                    label: Text('${_branchSnapshots.length} فرع'),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const _BranchSummaryShimmer()
            else if (_branchSnapshots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('لا توجد بيانات متاحة لهذه الفترة.')),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < _branchSnapshots.length; i++) ...[
                    _BranchSummaryCard(
                      snapshot: _branchSnapshots[i],
                      formatCurrency: _formatCurrency,
                    ),
                    if (i != _branchSnapshots.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
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
            if (_loading)
              const _ShimmerList(count: 6)
            else if (_recent.isEmpty)
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
                  final notes = (item['notes'] ?? 'عنصر') as String;
                  final branchId = item['branch_id']?.toString();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.shopping_basket,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      notes.isEmpty ? 'عنصر' : notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'الفرع: ${_branchNameFor(branchId)} • الكمية: $qty',
                    ),
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
                ElevatedButton.icon(
                  onPressed: _printPdf,
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('طباعة PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.blue,
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

  Future<void> _pickDateRange() async {
    final initialRange =
        (_customFrom != null && _customTo != null)
            ? DateTimeRange(start: _customFrom!, end: _customTo!)
            : null;
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      locale: const Locale('ar'),
      firstDate: DateTime(now.year - 3, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      initialDateRange: initialRange,
      helpText: 'اختر الفترة',
      confirmText: 'تم',
      cancelText: 'إلغاء',
    );
    if (result != null) {
      setState(() {
        _customFrom = DateTime(
          result.start.year,
          result.start.month,
          result.start.day,
        );
        _customTo = DateTime(
          result.end.year,
          result.end.month,
          result.end.day,
          23,
          59,
          59,
          999,
        );
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_c.period.value == 'custom' &&
        (_customFrom == null || _customTo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد تاريخ البداية والنهاية قبل التصدير.'),
        ),
      );
      return;
    }

    final rangeConfig = _resolveRange(DateTime.now());
    final branchId = _c.selectedBranchId.value;
    final periodKey = _c.period.value;
    final startDate = rangeConfig.range.start;
    final endDate = rangeConfig.range.end;
    final label =
        rangeConfig.label.isNotEmpty ? rangeConfig.label : 'الفترة الحالية';

    await _confirmThenExport(
      () => _c.generateStyledPdf(
        startDate: startDate,
        endDate: endDate,
        periodKey: periodKey,
        branchId: branchId,
        reportType: 'sheets',
      ),
      confirmTitle: 'تصدير PDF',
      subject: 'تقرير $label (PDF)',
      progressLabel: 'جارٍ إعداد تقرير PDF...',
    );
  }

  Future<void> _exportExcel() async {
    if (_c.period.value == 'custom' &&
        (_customFrom == null || _customTo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد تاريخ البداية والنهاية قبل التصدير.'),
        ),
      );
      return;
    }

    final rangeConfig = _resolveRange(DateTime.now());
    final branchId = _c.selectedBranchId.value;
    final periodKey = _c.period.value;
    final startDate = rangeConfig.range.start;
    final endDate = rangeConfig.range.end;
    final label =
        rangeConfig.label.isNotEmpty ? rangeConfig.label : 'الفترة الحالية';

    await _confirmThenExport(
      () => _c.generateStyledExcel(
        startDate: startDate,
        endDate: endDate,
        periodKey: periodKey,
        branchId: branchId,
        reportType: 'sheets',
      ),
      confirmTitle: 'تصدير Excel',
      subject: 'تقرير $label (Excel)',
      progressLabel: 'جارٍ تجهيز ملف Excel...',
    );
  }

  Future<void> _printPdf() async {
    if (_c.period.value == 'custom' &&
        (_customFrom == null || _customTo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد تاريخ البداية والنهاية قبل الطباعة.'),
        ),
      );
      return;
    }

    final rangeConfig = _resolveRange(DateTime.now());
    final branchId = _c.selectedBranchId.value;
    final periodKey = _c.period.value;
    final startDate = rangeConfig.range.start;
    final endDate = rangeConfig.range.end;

    try {
      final file = await _withProgress(
        () => _c.generateStyledPdf(
          startDate: startDate,
          endDate: endDate,
          periodKey: periodKey,
          branchId: branchId,
          reportType: 'sheets',
        ),
        label: 'جارٍ إنشاء ملف PDF للطباعة...',
      );
      final bytes = await File(file.path).readAsBytes();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الطباعة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

class _ShimmerStatCard extends StatelessWidget {
  const _ShimmerStatCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList({this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 120, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(height: 12, width: 60, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

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
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
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

class _BranchSummaryCard extends StatelessWidget {
  const _BranchSummaryCard({
    required this.snapshot,
    required this.formatCurrency,
  });

  final _BranchSnapshot snapshot;
  final String Function(num value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = [
      _MetricChip(
        icon: Icons.shopping_bag,
        label: 'المبيعات',
        value: formatCurrency(snapshot.totalSales),
        color: theme.colorScheme.primary,
      ),
      _MetricChip(
        icon: Icons.edit_note,
        label: 'القرطاسية',
        value: formatCurrency(snapshot.stationeryExpenses),
        color: Colors.orange,
      ),
      _MetricChip(
        icon: Icons.local_shipping,
        label: 'النقل',
        value: formatCurrency(snapshot.transportationExpenses),
        color: Colors.teal,
      ),
      _MetricChip(
        icon: Icons.fact_check,
        label: 'القوائم',
        value: '${snapshot.menusCount}',
        color: theme.colorScheme.secondary,
      ),
      _MetricChip(
        icon: Icons.shopping_cart,
        label: 'إجمالي الكمية',
        value: '${snapshot.itemsCount}',
        color: Colors.indigo,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.store, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.branch.name.isEmpty
                          ? 'فرع غير معروف'
                          : snapshot.branch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (snapshot.branch.location != null &&
                        snapshot.branch.location!.isNotEmpty)
                      Text(
                        snapshot.branch.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                formatCurrency(snapshot.grandTotal),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
          if (snapshot.topItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'أبرز العناصر',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    snapshot.topItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Chip(
                              avatar: const Icon(Icons.label_outline, size: 18),
                              backgroundColor: theme.colorScheme.surface,
                              label: Text(
                                '${item.name} • ${item.qty}× • ${formatCurrency(item.total)}',
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchSummaryShimmer extends StatelessWidget {
  const _BranchSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 1 ? 0 : 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchSnapshot {
  const _BranchSnapshot({
    required this.branch,
    required this.totalSales,
    required this.stationeryExpenses,
    required this.transportationExpenses,
    required this.menusCount,
    required this.itemsCount,
    required this.topItems,
  });

  final BranchModel branch;
  final num totalSales;
  final num stationeryExpenses;
  final num transportationExpenses;
  final int menusCount;
  final int itemsCount;
  final List<_ItemSnapshot> topItems;

  num get totalExpenses => stationeryExpenses + transportationExpenses;

  num get grandTotal => totalSales + totalExpenses;
}

class _ItemSnapshot {
  const _ItemSnapshot({
    required this.name,
    required this.total,
    required this.qty,
  });

  final String name;
  final num total;
  final int qty;
}

class _RangeConfig {
  const _RangeConfig(this.range, this.label);

  final DateTimeRange range;
  final String label;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}
