import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/vin_decoder_service.dart';
import 'maintenance_screen.dart';
import 'repair_history_screen.dart';
import 'fuel_log_screen.dart';
import 'analytics_screen.dart';
import 'trip_list_screen.dart';
import 'mileage_screen.dart';
import 'add_vehicle_screen.dart';

class CarInfoScreen extends StatefulWidget {
  final String vin;

  const CarInfoScreen({super.key, required this.vin});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _vehicleData;
  VinDecodeResult? _nhtsaData;
  bool _isLoading = true;
  bool _isFromNhtsa = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fetchVehicleData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicleData() async {
    // First try local database
    try {
      final data = await _apiService.getVehicleByVinLegacy(widget.vin);
      if (data != null) {
        setState(() {
          _vehicleData = data;
          _isLoading = false;
          _isFromNhtsa = false;
        });
        _animationController.forward();
        return;
      }
    } catch (e) {
      // Local lookup failed, try NHTSA
    }

    // Try NHTSA VIN decoder
    try {
      final nhtsaResult = await VinDecoderService.decodeVin(widget.vin);
      if (nhtsaResult != null && nhtsaResult.isValid) {
        setState(() {
          _nhtsaData = nhtsaResult;
          _vehicleData = {
            'VIN': widget.vin,
            'Year': nhtsaResult.year,
            'Make': nhtsaResult.make,
            'Model': nhtsaResult.model,
            'Trim': nhtsaResult.trim,
            'engine_type': nhtsaResult.engineDescription,
            'body_class': nhtsaResult.bodyClass,
            'fuel_type': nhtsaResult.fuelType,
            'drive_type': nhtsaResult.driveType,
            'transmission': nhtsaResult.transmissionStyle,
            'plant_country': nhtsaResult.plantCountry,
          };
          _isLoading = false;
          _isFromNhtsa = true;
        });
        _animationController.forward();
        return;
      }
    } catch (e) {
      // NHTSA lookup also failed
    }

    // Neither worked
    setState(() {
      _isLoading = false;
      _errorMessage = 'Vehicle not found';
    });
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
              colorScheme.primaryContainer.withValues(alpha: 0.4),
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
            color: colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Loading vehicle data...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
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
                Icons.error_outline_rounded,
                size: 40,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'VIN: ${widget.vin}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: const Text('Try Another VIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    final year = _vehicleData?['Year']?.toString() ?? 'N/A';
    final make = _vehicleData?['Make'] ?? 'Unknown';
    final model = _vehicleData?['Model'] ?? 'Unknown';
    final trim = _vehicleData?['Trim'] ?? '';
    final engineType = _vehicleData?['engine_type'] ?? 'N/A';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.6),
                      colorScheme.primaryContainer.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 40,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$year $make',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$model ${trim.isNotEmpty ? trim : ""}'.trim(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // NHTSA Banner (if from external lookup)
                if (_isFromNhtsa) ...[
                  _buildNhtsaBanner(theme, colorScheme),
                  const SizedBox(height: 16),
                ],

                // VIN Card
                _buildInfoCard(
                  theme,
                  colorScheme,
                  title: 'Vehicle Identification',
                  icon: Icons.tag_rounded,
                  children: [
                    _buildInfoRow(theme, colorScheme, 'VIN', widget.vin),
                    _buildInfoRow(theme, colorScheme, 'Year', year),
                    _buildInfoRow(theme, colorScheme, 'Make', make),
                    _buildInfoRow(theme, colorScheme, 'Model', model),
                    if (trim.isNotEmpty)
                      _buildInfoRow(theme, colorScheme, 'Trim', trim),
                    _buildInfoRow(theme, colorScheme, 'Engine', engineType),
                    if (_vehicleData?['body_class'] != null)
                      _buildInfoRow(theme, colorScheme, 'Body', _vehicleData!['body_class']),
                    if (_vehicleData?['fuel_type'] != null)
                      _buildInfoRow(theme, colorScheme, 'Fuel', _vehicleData!['fuel_type']),
                    if (_vehicleData?['drive_type'] != null)
                      _buildInfoRow(theme, colorScheme, 'Drive', _vehicleData!['drive_type']),
                    if (_vehicleData?['plant_country'] != null)
                      _buildInfoRow(theme, colorScheme, 'Made in', _vehicleData!['plant_country']),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Actions (only show if vehicle is in garage)
                if (!_isFromNhtsa) ...[
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Show action cards only if vehicle is in garage
                if (!_isFromNhtsa) ...[
                  // Maintenance Button
                  _buildActionCard(
                    theme,
                    colorScheme,
                    icon: Icons.build_circle_rounded,
                    title: 'Maintenance Schedule',
                    subtitle: 'View service intervals & reminders',
                    iconBgColor: colorScheme.tertiaryContainer,
                    iconColor: colorScheme.onTertiaryContainer,
                    onTap: () => _navigateToScreen(
                      MaintenanceScreen(vin: widget.vin),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Repair History Button
                  _buildActionCard(
                    theme,
                    colorScheme,
                    icon: Icons.history_rounded,
                    title: 'Repair History',
                    subtitle: 'View past repairs & add new ones',
                    iconBgColor: colorScheme.secondaryContainer,
                    iconColor: colorScheme.onSecondaryContainer,
                    onTap: () => _navigateToScreen(
                      RepairHistoryScreen(vin: widget.vin),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fuel Log Button
                  _buildActionCard(
                    theme,
                    colorScheme,
                    icon: Icons.local_gas_station_rounded,
                    title: 'Fuel Log',
                    subtitle: 'Track fill-ups & fuel efficiency',
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _navigateToScreen(
                      FuelLogScreen(vin: widget.vin),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Analytics Button
                  _buildActionCard(
                    theme,
                    colorScheme,
                    icon: Icons.insights_rounded,
                    title: 'Analytics',
                    subtitle: 'Cost analysis & spending trends',
                    iconBgColor: colorScheme.primaryContainer,
                    iconColor: colorScheme.onPrimaryContainer,
                    onTap: () => _navigateToScreen(
                      AnalyticsScreen(vin: widget.vin),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trip Tracker Button
                  _buildActionCard(
                    theme,
                    colorScheme,
                    icon: Icons.route_rounded,
                    title: 'Trip Tracker',
                    subtitle: 'Log trips & track business mileage',
                    iconBgColor: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF3B82F6),
                    onTap: () => _navigateToScreen(
                      TripListScreen(vin: widget.vin),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mileage Tracker Button
                  _buildActionCard(
                    theme,
                    colorScheme,
                    icon: Icons.speed_rounded,
                    title: 'Mileage Tracker',
                    subtitle: 'Track odometer & driving stats',
                    iconBgColor: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF10B981),
                    onTap: () => _navigateToScreen(
                      MileageScreen(vin: widget.vin),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNhtsaBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.15),
            const Color(0xFF10B981).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Found via NHTSA',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'This vehicle is not in your garage yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addVehicleToGarage,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add to My Garage'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addVehicleToGarage() async {
    // Navigate to add vehicle screen with pre-filled data
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddVehicleScreenWithData(
          vin: widget.vin,
          year: _vehicleData?['Year']?.toString() ?? '',
          make: _vehicleData?['Make'] ?? '',
          model: _vehicleData?['Model'] ?? '',
          trim: _vehicleData?['Trim'] ?? '',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (result == true && mounted) {
      // Refresh data - vehicle should now be in garage
      _fetchVehicleData();
    }
  }

  Widget _buildInfoCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

