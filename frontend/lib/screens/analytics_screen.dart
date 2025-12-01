import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/models.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  final String vin;

  const AnalyticsScreen({super.key, required this.vin});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  VehicleDashboard? _dashboard;
  CostPerMileData? _costPerMile;
  List<MonthlySpending> _monthlySpending = [];
  List<CategorySpending> _categorySpending = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboard = await _apiService.getDashboard(widget.vin);
      final costPerMile = await _apiService.getCostPerMile(widget.vin);
      final monthlySpending =
          await _apiService.getMonthlySpending(widget.vin, months: 6);
      final categorySpending =
          await _apiService.getSpendingByCategory(widget.vin);

      setState(() {
        _dashboard = dashboard;
        _costPerMile = costPerMile;
        _monthlySpending = monthlySpending;
        _categorySpending = categorySpending;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.2),
              colorScheme.surface,
              colorScheme.tertiaryContainer.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(colorScheme)
              : _errorMessage != null
                  ? _buildErrorState(theme, colorScheme)
                  : _buildContent(theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing your data...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 40,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analytics Unavailable',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(theme, colorScheme),
          ),

          // Total Cost Overview
          SliverToBoxAdapter(
            child: _buildTotalCostCard(theme, colorScheme),
          ),

          // Cost Per Mile
          SliverToBoxAdapter(
            child: _buildCostPerMileCard(theme, colorScheme),
          ),

          // Monthly Spending Chart
          if (_monthlySpending.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildMonthlySpendingChart(theme, colorScheme),
            ),

          // Category Breakdown
          if (_categorySpending.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildCategoryBreakdown(theme, colorScheme),
            ),

          // Quick Stats Grid
          SliverToBoxAdapter(
            child: _buildQuickStats(theme, colorScheme),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  _dashboard?.vehicleDisplayName ?? 'Vehicle Insights',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCostCard(ThemeData theme, ColorScheme colorScheme) {
    final totalCost = _dashboard?.totalCost ?? 0;
    final repairCost = _dashboard?.repairs.totalCost ?? 0;
    final fuelCost = _dashboard?.fuel.totalCost ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final progress = Curves.easeOutCubic.transform(
            _animationController.value.clamp(0.0, 1.0),
          );

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Spent',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '\$${(totalCost * progress).toStringAsFixed(2)}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildCostBreakdownItem(
                        theme,
                        colorScheme,
                        icon: Icons.build_rounded,
                        label: 'Repairs',
                        value: repairCost * progress,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildCostBreakdownItem(
                        theme,
                        colorScheme,
                        icon: Icons.local_gas_station_rounded,
                        label: 'Fuel',
                        value: fuelCost * progress,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCostBreakdownItem(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required double value,
  }) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.onPrimary.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(0)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCostPerMileCard(ThemeData theme, ColorScheme colorScheme) {
    final cpm = _costPerMile;
    if (cpm == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cost Per Mile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_formatNumber(cpm.totalMiles)} mi tracked',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCpmStat(
                  theme,
                  colorScheme,
                  label: 'Total',
                  value: cpm.costPerMile,
                  color: colorScheme.primary,
                  isMain: true,
                ),
                _buildCpmStat(
                  theme,
                  colorScheme,
                  label: 'Fuel',
                  value: cpm.fuelCostPerMile,
                  color: colorScheme.tertiary,
                ),
                _buildCpmStat(
                  theme,
                  colorScheme,
                  label: 'Repairs',
                  value: cpm.repairCostPerMile,
                  color: colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCpmStat(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String label,
    required double value,
    required Color color,
    bool isMain = false,
  }) {
    return Column(
      children: [
        Container(
          width: isMain ? 80 : 70,
          height: isMain ? 80 : 70,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '\$${value.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isMain ? 18 : 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlySpendingChart(ThemeData theme, ColorScheme colorScheme) {
    final maxSpending = _monthlySpending
        .map((s) => s.total)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Monthly Spending',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final progress = Curves.easeOutCubic.transform(
                    _animationController.value.clamp(0.0, 1.0),
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _monthlySpending.map((spending) {
                      final heightFactor =
                          maxSpending > 0 ? spending.total / maxSpending : 0.0;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '\$${spending.total.toStringAsFixed(0)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 120 * heightFactor * progress,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.primary.withValues(alpha: 0.6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                spending.displayMonth,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(theme, colorScheme, 'Repairs', colorScheme.secondary),
                const SizedBox(width: 24),
                _buildLegendItem(theme, colorScheme, 'Fuel', colorScheme.tertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      ThemeData theme, ColorScheme colorScheme, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme, ColorScheme colorScheme) {
    final totalCost =
        _categorySpending.fold(0.0, (sum, cat) => sum + cat.totalCost);

    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Spending by Category',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Pie Chart
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _PieChartPainter(
                        categories: _categorySpending,
                        totalCost: totalCost,
                        colors: colors,
                        progress: _animationController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Category list
            ...List.generate(
              math.min(_categorySpending.length, 5),
              (index) {
                final cat = _categorySpending[index];
                final percentage =
                    totalCost > 0 ? (cat.totalCost / totalCost * 100) : 0;
                final color = colors[index % colors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cat.category,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${cat.totalCost.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, ColorScheme colorScheme) {
    final dashboard = _dashboard;
    if (dashboard == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colorScheme,
                  icon: Icons.build_rounded,
                  label: 'Total Repairs',
                  value: '${dashboard.repairs.count}',
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colorScheme,
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fill-ups',
                  value: '${dashboard.fuel.fillUps}',
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colorScheme,
                  icon: Icons.route_rounded,
                  label: 'Total Trips',
                  value: '${dashboard.trips.count}',
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  colorScheme,
                  icon: Icons.speed_rounded,
                  label: 'Avg MPG',
                  value: dashboard.mpg.averageMpg?.toStringAsFixed(1) ?? '-',
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// Custom painter for the pie chart
class _PieChartPainter extends CustomPainter {
  final List<CategorySpending> categories;
  final double totalCost;
  final List<Color> colors;
  final double progress;

  _PieChartPainter({
    required this.categories,
    required this.totalCost,
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCost <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final sweepAngle = (category.totalCost / totalCost) * 2 * math.pi * progress;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Add white border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle (donut effect)
    final centerPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.55, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

