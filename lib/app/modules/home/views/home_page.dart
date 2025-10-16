import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingSkeleton(context);
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome Header
              _buildWelcomeHeader(context),
              const SizedBox(height: 24),

              // Quick Stats Cards
              _buildQuickStatsGrid(context),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Branch Statistics
              if (controller.branchStats.isNotEmpty) ...[
                _buildSectionHeader(context, 'إحصائيات الفروع', Icons.store),
                const SizedBox(height: 12),
                _buildBranchStats(context),
                const SizedBox(height: 24),
              ],

              // Top Categories
              if (controller.topCategories.isNotEmpty) ...[
                _buildSectionHeader(context, 'أكثر الفئات', Icons.category),
                const SizedBox(height: 12),
                _buildTopCategories(context),
                const SizedBox(height: 24),
              ],

              // Recent Purchases
              if (controller.recentPurchases.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  'آخر المشتريات',
                  Icons.shopping_bag,
                ),
                const SizedBox(height: 12),
                _buildRecentPurchases(context),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);

    try {
      final now = DateTime.now();

      // Simple date formatting without locale initialization
      final weekDays = [
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      final months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      final dateStr =
          '${weekDays[now.weekday % 7]}، ${now.day} ${months[now.month - 1]} ${now.year}';

      String greeting;
      final hour = now.hour;
      if (hour < 12) {
        greeting = 'صباح الخير';
      } else if (hour < 18) {
        greeting = 'مساء الخير';
      } else {
        greeting = 'مساء الخير';
      }

      return Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مرحباً بك في مشترياتي',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.waving_hand,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'حدث خطأ في تحميل الترحيب',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildQuickStatsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var maxWidth = constraints.maxWidth;
        if (maxWidth == double.infinity) {
          maxWidth = MediaQuery.of(context).size.width;
        }
        final crossAxisCount = _calculateColumnsForWidth(maxWidth, maxCount: 4);
        const spacing = 12.0;
        const cardHeight = 170.0;
        final availableWidth = maxWidth - (spacing * (crossAxisCount - 1));
        final itemWidth = availableWidth / crossAxisCount;
        final aspectRatio = itemWidth / cardHeight;

        return Obx(() {
          final stats = [
            _StatCardConfig(
              title: 'اليوم',
              value: controller.totalPurchasesToday.value,
              icon: Icons.today,
              color: Colors.blue,
              subtitle: '${controller.totalMenusToday.value} قائمة',
            ),
            _StatCardConfig(
              title: 'هذا الأسبوع',
              value: controller.totalPurchasesWeek.value,
              icon: Icons.date_range,
              color: Colors.green,
            ),
            _StatCardConfig(
              title: 'هذا الشهر',
              value: controller.totalPurchasesMonth.value,
              icon: Icons.calendar_month,
              color: Colors.orange,
            ),
            _StatCardConfig(
              title: 'الفروع',
              value: controller.totalBranches.value.toDouble(),
              icon: Icons.store,
              color: Colors.purple,
              isCurrency: false,
              subtitle: '${controller.totalCategories.value} فئة',
            ),
          ];

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildStatCard(
                context,
                stat.title,
                stat.value,
                stat.icon,
                stat.color,
                isCurrency: stat.isCurrency,
                subtitle: stat.subtitle,
              );
            },
          );
        });
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    double value,
    IconData icon,
    Color color, {
    bool isCurrency = true,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    try {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCurrency
                        ? NumberFormat.currency(
                          locale: 'ar',
                          symbol: 'ر.ي',
                          decimalDigits: 0,
                        ).format(value)
                        : value.toInt().toString(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        elevation: 2,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      );
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إجراءات سريعة',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'عرض التقارير',
                Icons.assessment,
                Colors.green,
                () => Get.find<HomeController>().update(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'إضافة قائمة',
                Icons.add_shopping_cart,
                Colors.blue,
                () => Get.find<HomeController>().update(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBranchStats(BuildContext context) {
    return Obx(() {
      if (controller.branchStats.isEmpty) {
        return const SizedBox.shrink();
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.branchStats.length,
        itemBuilder: (context, index) {
          final branch = controller.branchStats[index];
          return _buildBranchStatCard(context, branch);
        },
      );
    });
  }

  Widget _buildBranchStatCard(
    BuildContext context,
    Map<String, dynamic> branch,
  ) {
    final theme = Theme.of(context);

    try {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          trailing: Text(
            NumberFormat.currency(
              locale: 'ar',
              symbol: 'ر.ي',
              decimalDigits: 0,
            ).format(branch['total'] ?? 0),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            branch['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('${branch['menu_count'] ?? 0} قائمة'),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.store, color: theme.colorScheme.primary),
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            'خطأ في تحميل البيانات',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }
  }

  Widget _buildTopCategories(BuildContext context) {
    return Obx(() {
      final categories = controller.topCategories;
      if (categories.isEmpty) {
        return const SizedBox.shrink();
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          var maxWidth = constraints.maxWidth;
          if (maxWidth == double.infinity) {
            maxWidth = MediaQuery.of(context).size.width;
          }
          const cardHeight = 160.0;
          final calculatedWidth = maxWidth * 0.45;
          final itemWidth = calculatedWidth.clamp(160.0, 280.0);

          return SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: false,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = categories[index];
                return SizedBox(
                  width: itemWidth,
                  child: _buildCategoryCard(context, category, index),
                );
              },
            ),
          );
        },
      );
    });
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
    int index,
  ) {
    final theme = Theme.of(context);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    final color = colors[index % colors.length];

    try {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category['name'] ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.category, color: color, size: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category['item_count'] ?? 0} عنصر',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    NumberFormat.compact(
                      locale: 'ar',
                    ).format(category['total'] ?? 0),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRecentPurchases(BuildContext context) {
    return Obx(() {
      if (controller.recentPurchases.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مشتريات حتى الآن',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recentPurchases.length,
        itemBuilder: (context, index) {
          final purchase = controller.recentPurchases[index];
          return _buildPurchaseCard(context, purchase);
        },
      );
    });
  }

  Widget _buildPurchaseCard(
    BuildContext context,
    Map<String, dynamic> purchase,
  ) {
    final theme = Theme.of(context);

    try {
      final updatedAt = purchase['updated_at'] as int?;
      final date =
          updatedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(updatedAt)
              : DateTime.now();

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          trailing: Text(
            NumberFormat.currency(
              locale: 'ar',
              symbol: '',
              decimalDigits: 0,
            ).format(purchase['total'] ?? 0),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            purchase['notes']?.toString() ?? 'بدون ملاحظات',
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${purchase['qty']} × ${purchase['unit_price']}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  if (purchase['category_name'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        purchase['category_name'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (purchase['branch_name'] != null)
                    Text(
                      purchase['branch_name'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  Text(
                    '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(
              Icons.shopping_basket,
              color: theme.colorScheme.secondary,
              size: 20,
            ),
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(
            'خطأ في عرض العنصر',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceVariant.withOpacity(0.5);
    final highlightColor = theme.colorScheme.surface.withOpacity(0.9);

    Widget shimmerBox({
      double height = 120,
      double? width,
      BorderRadius? radius,
    }) {
      return Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: radius ?? BorderRadius.circular(16),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        shimmerBox(height: 150),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            var maxWidth = constraints.maxWidth;
            if (maxWidth == double.infinity) {
              maxWidth = MediaQuery.of(context).size.width;
            }
            final crossAxisCount = _calculateColumnsForWidth(
              maxWidth,
              maxCount: 4,
            );
            const spacing = 12.0;
            final availableWidth = maxWidth - (spacing * (crossAxisCount - 1));
            final itemWidth = availableWidth / crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                4,
                (_) => shimmerBox(height: 140, width: itemWidth),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        shimmerBox(height: 100),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            var maxWidth = constraints.maxWidth;
            if (maxWidth == double.infinity) {
              maxWidth = MediaQuery.of(context).size.width;
            }
            final crossAxisCount = _calculateColumnsForWidth(
              maxWidth,
              maxCount: 3,
            );
            const spacing = 12.0;
            final availableWidth = maxWidth - (spacing * (crossAxisCount - 1));
            final itemWidth = availableWidth / crossAxisCount;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                3,
                (_) => shimmerBox(height: 160, width: itemWidth),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        shimmerBox(height: 80),
        const SizedBox(height: 12),
        shimmerBox(height: 80),
        const SizedBox(height: 12),
        shimmerBox(height: 80),
      ],
    );
  }

  int _calculateColumnsForWidth(double width, {required int maxCount}) {
    var columns = 1;
    if (width >= 600) {
      columns = 2;
    }
    if (width >= 900) {
      columns = 3;
    }
    if (width >= 1200) {
      columns = 4;
    }
    if (columns > maxCount) {
      columns = maxCount;
    }
    if (columns < 1) {
      columns = 1;
    }
    return columns;
  }
}

class _StatCardConfig {
  const _StatCardConfig({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = true,
    this.subtitle,
  });

  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;
  final String? subtitle;
}
