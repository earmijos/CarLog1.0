import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MaintenanceScreen extends StatefulWidget {
  final String vin;

  const MaintenanceScreen({super.key, required this.vin});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  MaintenanceSchedule? _schedule;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int retryCount = 0}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schedule = await _apiService.getMaintenanceSchedule(widget.vin);
      if (!mounted) return;
      setState(() {
        _schedule = schedule;
        _isLoading = false;
      });
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      // Retry once
      if (retryCount < 1) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          return _loadData(retryCount: retryCount + 1);
        }
        return;
      }
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load maintenance data. Tap retry to try again.';
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
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
            color: colorScheme.tertiary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading maintenance schedule...',
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
                Icons.build_circle_outlined,
                size: 40,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Data',
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
    final schedule = _schedule;
    if (schedule == null) {
      return _buildEmptyState(theme, colorScheme);
    }

    final overdue = schedule.overdue;
    final dueSoon = schedule.dueSoon;
    final ok = schedule.ok;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: colorScheme.tertiary,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(theme, colorScheme),
          ),

          // Status Summary
          SliverToBoxAdapter(
            child: _buildStatusSummary(theme, colorScheme, overdue.length, dueSoon.length, ok.length),
          ),

          // Overdue Section
          if (overdue.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                theme,
                colorScheme,
                'Overdue',
                Icons.warning_rounded,
                const Color(0xFFEF4444),
                overdue.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMaintenanceCard(
                    theme,
                    colorScheme,
                    overdue[index],
                    MaintenanceStatus.overdue,
                  ),
                  childCount: overdue.length,
                ),
              ),
            ),
          ],

          // Due Soon Section
          if (dueSoon.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                theme,
                colorScheme,
                'Due Soon',
                Icons.schedule_rounded,
                const Color(0xFFF59E0B),
                dueSoon.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMaintenanceCard(
                    theme,
                    colorScheme,
                    dueSoon[index],
                    MaintenanceStatus.dueSoon,
                  ),
                  childCount: dueSoon.length,
                ),
              ),
            ),
          ],

          // OK Section
          if (ok.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                theme,
                colorScheme,
                'Up to Date',
                Icons.check_circle_rounded,
                const Color(0xFF10B981),
                ok.length,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMaintenanceCard(
                    theme,
                    colorScheme,
                    ok[index],
                    MaintenanceStatus.ok,
                  ),
                  childCount: ok.length,
                ),
              ),
            ),
          ],

          // Empty state if no intervals
          if (schedule.intervals.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyState(theme, colorScheme),
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
                  'Maintenance',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Service schedule & reminders',
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
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.build_rounded,
              color: colorScheme.onTertiaryContainer,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    int overdueCount,
    int dueSoonCount,
    int okCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              theme,
              colorScheme,
              icon: Icons.warning_rounded,
              label: 'Overdue',
              count: overdueCount,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatusCard(
              theme,
              colorScheme,
              icon: Icons.schedule_rounded,
              label: 'Due Soon',
              count: dueSoonCount,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatusCard(
              theme,
              colorScheme,
              icon: Icons.check_circle_rounded,
              label: 'Up to Date',
              count: okCount,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(
    ThemeData theme,
    ColorScheme colorScheme,
    MaintenanceInterval interval,
    MaintenanceStatus status,
  ) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status, interval);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status == MaintenanceStatus.overdue
                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getServiceIcon(interval.serviceType),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        interval.serviceType,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (interval.nextDueMileage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatNumber(interval.nextDueMileage!)} mi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'due at',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (interval.intervalMiles != null || interval.lastPerformedDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (interval.intervalMiles != null) ...[
                      Icon(
                        Icons.repeat_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Every ${_formatNumber(interval.intervalMiles!)} mi',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (interval.intervalMiles != null && interval.lastPerformedDate != null)
                      const SizedBox(width: 16),
                    if (interval.lastPerformedDate != null) ...[
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last: ${_formatDate(interval.lastPerformedDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Mark Complete Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => _showMarkCompleteDialog(interval),
                style: FilledButton.styleFrom(
                  backgroundColor: status == MaintenanceStatus.ok
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  foregroundColor: status == MaintenanceStatus.ok
                      ? colorScheme.onSurfaceVariant
                      : const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status == MaintenanceStatus.ok ? 'Log Service' : 'Mark Complete',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkCompleteDialog(MaintenanceInterval interval) {
    final colorScheme = Theme.of(context).colorScheme;
    final mileageController = TextEditingController();
    final today = DateTime.now();
    DateTime selectedDate = today;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete Service',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          interval.serviceType,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mileage Input
              Text(
                'Current Mileage',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter current odometer reading',
                  prefixIcon: const Icon(Icons.speed_rounded),
                  suffixText: 'miles',
                ),
              ),
              const SizedBox(height: 20),

              // Date Selector
              Text(
                'Service Date',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: today,
                  );
                  if (date != null) {
                    setModalState(() {
                      selectedDate = date;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDateFull(selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _completeService(
                        interval,
                        mileageController.text,
                        selectedDate,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                      child: const Text('Complete Service'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeService(
    MaintenanceInterval interval,
    String mileageText,
    DateTime date,
  ) async {
    final mileage = int.tryParse(mileageText.replaceAll(',', ''));
    
    if (mileage == null || mileage <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid mileage'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    Navigator.pop(context); // Close the bottom sheet

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _apiService.recordService(
        widget.vin,
        interval.serviceType,
        date: date.toIso8601String().split('T')[0],
        mileage: mileage,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${interval.serviceType} marked as complete!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        // Refresh the data
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record service: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatDateFull(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.build_outlined,
              size: 40,
              color: colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Maintenance Schedule',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up maintenance intervals for your vehicle',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.overdue:
        return const Color(0xFFEF4444);
      case MaintenanceStatus.dueSoon:
        return const Color(0xFFF59E0B);
      case MaintenanceStatus.ok:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.overdue:
        return Icons.error_rounded;
      case MaintenanceStatus.dueSoon:
        return Icons.schedule_rounded;
      case MaintenanceStatus.ok:
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusText(MaintenanceStatus status, MaintenanceInterval interval) {
    switch (status) {
      case MaintenanceStatus.overdue:
        if (interval.milesUntilDue != null) {
          return '${_formatNumber(interval.milesUntilDue!.abs())} miles overdue';
        }
        return 'Overdue';
      case MaintenanceStatus.dueSoon:
        if (interval.milesUntilDue != null) {
          return '${_formatNumber(interval.milesUntilDue!)} miles until due';
        }
        return 'Due soon';
      case MaintenanceStatus.ok:
        if (interval.milesUntilDue != null) {
          return '${_formatNumber(interval.milesUntilDue!)} miles until due';
        }
        return 'Up to date';
      default:
        return 'Status unknown';
    }
  }

  IconData _getServiceIcon(String serviceType) {
    final lower = serviceType.toLowerCase();
    if (lower.contains('oil')) return Icons.opacity_rounded;
    if (lower.contains('transmission')) return Icons.settings_rounded;
    if (lower.contains('brake')) return Icons.disc_full_rounded;
    if (lower.contains('air') || lower.contains('filter')) return Icons.air_rounded;
    if (lower.contains('tire')) return Icons.tire_repair_rounded;
    if (lower.contains('coolant')) return Icons.water_drop_rounded;
    if (lower.contains('spark')) return Icons.electric_bolt_rounded;
    if (lower.contains('battery')) return Icons.battery_charging_full_rounded;
    return Icons.build_rounded;
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
