import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'vin_input_screen.dart';
import 'maintenance_screen.dart';
import 'repair_history_screen.dart';
import 'settings_screen.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String? _selectedVin;
  String? _selectedVehicleName;
  final ApiService _apiService = ApiService();
  List<VehicleSummaryItem> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await _apiService.getAllVehiclesSummary();
      setState(() {
        _vehicles = vehicles;
        if (vehicles.isNotEmpty && _selectedVin == null) {
          _selectedVin = vehicles.first.vin;
          _selectedVehicleName = vehicles.first.displayName;
        }
      });
    } catch (e) {
      // Handle error silently - home screen will show appropriate error
    }
  }

  void _onVehicleSelected(VehicleSummaryItem vehicle) {
    setState(() {
      _selectedVin = vehicle.vin;
      _selectedVehicleName = vehicle.displayName;
    });
    Navigator.pop(context);
  }

  void _showVehicleSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Text(
                      'Select Vehicle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VinInputScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add New'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Vehicle list
              Expanded(
                child: _vehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No vehicles yet',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          final isSelected = vehicle.vin == _selectedVin;

                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              vehicle.displayName,
                              style: TextStyle(
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatMileage(vehicle.currentMileage)} mi • ${vehicle.repairCount} repairs',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: colorScheme.primary,
                                  )
                                : null,
                            onTap: () => _onVehicleSelected(vehicle),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMileage(int mileage) {
    if (mileage >= 1000) {
      return '${(mileage / 1000).toStringAsFixed(1)}k';
    }
    return mileage.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          const VinInputScreen(),
          _selectedVin != null
              ? MaintenanceScreen(vin: _selectedVin!)
              : _buildSelectVehiclePrompt(colorScheme),
          _selectedVin != null
              ? RepairHistoryScreen(vin: _selectedVin!)
              : _buildSelectVehiclePrompt(colorScheme),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'VIN Lookup',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build_rounded),
            label: 'Service',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Repairs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 2 || _selectedIndex == 3) &&
              _vehicles.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showVehicleSelector,
              icon: const Icon(Icons.directions_car_rounded),
              label: Text(
                _selectedVehicleName ?? 'Select Vehicle',
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            )
          : null,
    );
  }

  Widget _buildSelectVehiclePrompt(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Vehicle Selected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a vehicle from Home or use VIN Lookup to add one',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => setState(() => _selectedIndex = 0),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

