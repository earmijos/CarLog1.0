import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ThemeController _themeController = ThemeController();
  AppSettings? _settings;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _apiService.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Use default settings if API fails
        _settings = AppSettings();
      });
      _animationController.forward();
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    try {
      await _apiService.setSetting(key, value);
    } catch (e) {
      // Silently fail - settings are local anyway
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
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(colorScheme)
              : _buildContent(theme, colorScheme),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: CircularProgressIndicator(
        color: colorScheme.primary,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: animation,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _buildHeader(theme, colorScheme),
          ),

          // Settings Groups
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsGroup(
                  theme,
                  colorScheme,
                  title: 'Units & Formats',
                  icon: Icons.straighten_rounded,
                  children: [
                    _buildDropdownTile(
                      theme,
                      colorScheme,
                      title: 'Distance Unit',
                      value: _settings?.distanceUnit ?? 'miles',
                      options: ['miles', 'kilometers'],
                      displayOptions: ['Miles', 'Kilometers'],
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings?.copyWith(distanceUnit: value);
                        });
                        _updateSetting('distance_unit', value);
                      },
                    ),
                    _buildDropdownTile(
                      theme,
                      colorScheme,
                      title: 'Fuel Unit',
                      value: _settings?.fuelUnit ?? 'gallons',
                      options: ['gallons', 'liters'],
                      displayOptions: ['Gallons', 'Liters'],
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings?.copyWith(fuelUnit: value);
                        });
                        _updateSetting('fuel_unit', value);
                      },
                    ),
                    _buildDropdownTile(
                      theme,
                      colorScheme,
                      title: 'Currency',
                      value: _settings?.currency ?? 'USD',
                      options: ['USD', 'EUR', 'GBP', 'CAD'],
                      displayOptions: [
                        'USD (\$)',
                        'EUR (€)',
                        'GBP (£)',
                        'CAD (CA\$)'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings?.copyWith(currency: value);
                        });
                        _updateSetting('currency', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsGroup(
                  theme,
                  colorScheme,
                  title: 'Appearance',
                  icon: Icons.palette_rounded,
                  children: [
                    _buildDropdownTile(
                      theme,
                      colorScheme,
                      title: 'Theme',
                      value: _themeController.themeModeString,
                      options: ['light', 'dark', 'system'],
                      displayOptions: ['Light', 'Dark', 'System'],
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings?.copyWith(theme: value);
                        });
                        // Use theme controller to actually change the theme
                        _themeController.setThemeMode(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsGroup(
                  theme,
                  colorScheme,
                  title: 'Notifications',
                  icon: Icons.notifications_rounded,
                  children: [
                    _buildSwitchTile(
                      theme,
                      colorScheme,
                      title: 'Enable Notifications',
                      subtitle: 'Maintenance reminders and alerts',
                      value: _settings?.notificationsEnabled ?? true,
                      onChanged: (value) {
                        setState(() {
                          _settings =
                              _settings?.copyWith(notificationsEnabled: value);
                        });
                        _updateSetting(
                            'notifications_enabled', value.toString());
                      },
                    ),
                    _buildDropdownTile(
                      theme,
                      colorScheme,
                      title: 'Maintenance Reminder',
                      value: (_settings?.maintenanceReminderMiles ?? 500)
                          .toString(),
                      options: ['250', '500', '1000', '2000'],
                      displayOptions: [
                        '250 miles before',
                        '500 miles before',
                        '1000 miles before',
                        '2000 miles before'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings?.copyWith(
                              maintenanceReminderMiles: int.parse(value));
                        });
                        _updateSetting('maintenance_reminder_miles', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsGroup(
                  theme,
                  colorScheme,
                  title: 'Defaults',
                  icon: Icons.tune_rounded,
                  children: [
                    _buildDropdownTile(
                      theme,
                      colorScheme,
                      title: 'Default Fuel Type',
                      value: _settings?.fuelGradeDefault ?? 'Regular',
                      options: [
                        'Regular',
                        'Mid-Grade',
                        'Premium',
                        'Diesel',
                        'E85'
                      ],
                      displayOptions: [
                        'Regular',
                        'Mid-Grade',
                        'Premium',
                        'Diesel',
                        'E85'
                      ],
                      onChanged: (value) {
                        setState(() {
                          _settings =
                              _settings?.copyWith(fuelGradeDefault: value);
                        });
                        _updateSetting('fuel_grade_default', value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsGroup(
                  theme,
                  colorScheme,
                  title: 'About',
                  icon: Icons.info_rounded,
                  children: [
                    _buildInfoTile(
                      theme,
                      colorScheme,
                      title: 'Version',
                      value: '1.0.0',
                    ),
                    _buildInfoTile(
                      theme,
                      colorScheme,
                      title: 'Build',
                      value: '2024.12.01',
                    ),
                    _buildActionTile(
                      theme,
                      colorScheme,
                      title: 'Privacy Policy',
                      icon: Icons.privacy_tip_outlined,
                      onTap: () => _showPrivacyPolicy(),
                    ),
                    _buildActionTile(
                      theme,
                      colorScheme,
                      title: 'Terms of Service',
                      icon: Icons.description_outlined,
                      onTap: () => _showTermsOfService(),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ]),
            ),
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.settings_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Customize your experience',
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildSettingsGroup(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
    required List<String> options,
    required List<String> displayOptions,
    required ValueChanged<String> onChanged,
  }) {
    final displayIndex = options.indexOf(value);
    final displayValue =
        displayIndex >= 0 ? displayOptions[displayIndex] : value;

    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      trailing: TextButton(
        onPressed: () => _showOptionsPicker(
          title: title,
          options: options,
          displayOptions: displayOptions,
          currentValue: value,
          onSelected: onChanged,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayValue,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: colorScheme.primary,
    );
  }

  Widget _buildInfoTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String value,
  }) {
    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  void _showOptionsPicker({
    required String title,
    required List<String> options,
    required List<String> displayOptions,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            for (int i = 0; i < options.length; i++)
              ListTile(
                title: Text(displayOptions[i]),
                trailing: options[i] == currentValue
                    ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelected(options[i]);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showInfoDialog(
      title: 'Privacy Policy',
      content:
          'CarLog respects your privacy. All your data is stored locally on your device and is never shared with third parties.',
    );
  }

  void _showTermsOfService() {
    _showInfoDialog(
      title: 'Terms of Service',
      content:
          'By using CarLog, you agree to use the app responsibly for tracking your vehicle maintenance and expenses.',
    );
  }

  void _showInfoDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

