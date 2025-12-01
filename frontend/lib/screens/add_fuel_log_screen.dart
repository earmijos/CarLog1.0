import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AddFuelLogScreen extends StatefulWidget {
  final String vin;

  const AddFuelLogScreen({super.key, required this.vin});

  @override
  State<AddFuelLogScreen> createState() => _AddFuelLogScreenState();
}

class _AddFuelLogScreenState extends State<AddFuelLogScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _gallonsController = TextEditingController();
  final _priceController = TextEditingController();
  final _odometerController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();

  final ApiService _apiService = ApiService();
  late AnimationController _animationController;

  String _selectedFuelType = 'Regular';
  bool _isFullTank = true;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gallonsController.dispose();
    _priceController.dispose();
    _odometerController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalCost {
    final gallons = double.tryParse(_gallonsController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return gallons * price;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitFuelLog() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final fuelLog = FuelLog(
        vin: widget.vin,
        gallons: double.parse(_gallonsController.text),
        pricePerGallon: double.parse(_priceController.text),
        totalCost: _totalCost,
        odometer: int.parse(_odometerController.text),
        date: _selectedDate.toIso8601String().split('T')[0],
        station: _stationController.text.isEmpty ? null : _stationController.text,
        fuelType: _selectedFuelType,
        fullTank: _isFullTank,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await _apiService.createFuelLog(fuelLog);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Fuel log added successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

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
          child: FadeTransition(
            opacity: animation,
            child: Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(theme, colorScheme),
                  ),

                  // Form Fields
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Gallons & Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _gallonsController,
                                label: 'Gallons',
                                hint: '0.00',
                                icon: Icons.water_drop_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,3}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final gallons = double.tryParse(value);
                                  if (gallons == null || gallons <= 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'Price/Gallon',
                                hint: '0.000',
                                icon: Icons.attach_money_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,3}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Total Cost Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.tertiary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Total Cost',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '\$${_totalCost.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Odometer
                        _buildTextField(
                          controller: _odometerController,
                          label: 'Odometer',
                          hint: 'Current mileage',
                          icon: Icons.speed_rounded,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Odometer reading is required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Date Picker
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(_selectedDate),
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
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

                        const SizedBox(height: 16),

                        // Fuel Type Selector
                        _buildSectionTitle(theme, colorScheme, 'Fuel Type'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: FuelTypes.all.map((type) {
                            final isSelected = _selectedFuelType == type;
                            return ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedFuelType = type);
                              },
                              selectedColor: colorScheme.primaryContainer,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Full Tank Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_gas_station_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Full Tank',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Required for accurate MPG calculation',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isFullTank,
                                onChanged: (value) {
                                  setState(() => _isFullTank = value);
                                },
                                activeTrackColor: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Station (optional)
                        _buildTextField(
                          controller: _stationController,
                          label: 'Gas Station',
                          hint: 'Optional',
                          icon: Icons.location_on_rounded,
                        ),

                        const SizedBox(height: 16),

                        // Notes (optional)
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          hint: 'Optional notes',
                          icon: Icons.note_rounded,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submitFuelLog,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.tertiary,
                            foregroundColor: colorScheme.onTertiary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onTertiary,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.local_gas_station_rounded),
                                    SizedBox(width: 8),
                                    Text('Save Fill-up'),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                Icons.close_rounded,
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
                  'Add Fill-up',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Record your fuel purchase',
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
              Icons.local_gas_station_rounded,
              color: colorScheme.onTertiaryContainer,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      ThemeData theme, ColorScheme colorScheme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

