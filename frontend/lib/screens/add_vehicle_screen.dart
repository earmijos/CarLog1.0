import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/vin_decoder_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _vinController = TextEditingController();
  final _yearController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _trimController = TextEditingController();
  final _mileageController = TextEditingController();
  final _colorController = TextEditingController();

  final ApiService _apiService = ApiService();
  late AnimationController _animationController;

  bool _isSubmitting = false;
  bool _isLookingUp = false;
  int _currentStep = 0;

  final List<String> _popularMakes = [
    'Toyota', 'Honda', 'Ford', 'Chevrolet', 'BMW', 'Mercedes-Benz',
    'Nissan', 'Hyundai', 'Kia', 'Volkswagen', 'Audi', 'Lexus',
    'Subaru', 'Mazda', 'Jeep', 'Tesla', 'Dodge', 'Ram',
  ];

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
    _vinController.dispose();
    _yearController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _trimController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _lookupVin() async {
    final vin = _vinController.text.trim().toUpperCase();
    if (vin.length != 17) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VIN must be 17 characters')),
      );
      return;
    }

    setState(() => _isLookingUp = true);

    try {
      // First, try the local database
      final vehicle = await _apiService.getVehicleByVinLegacy(vin);
      if (vehicle != null && mounted) {
        setState(() {
          _yearController.text = vehicle['Year']?.toString() ?? '';
          _makeController.text = vehicle['Make'] ?? '';
          _modelController.text = vehicle['Model'] ?? '';
          _trimController.text = vehicle['Trim'] ?? '';
          _currentStep = 1;
          _isLookingUp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Vehicle found in your garage!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        return;
      }
    } catch (e) {
      // Local lookup failed, try NHTSA
    }

    // Try NHTSA VIN decoder for real vehicle data
    try {
      final decoded = await VinDecoderService.decodeVin(vin);
      if (decoded != null && decoded.isValid && mounted) {
        setState(() {
          _yearController.text = decoded.year?.toString() ?? '';
          _makeController.text = decoded.make ?? '';
          _modelController.text = decoded.model ?? '';
          _trimController.text = decoded.trim ?? '';
          _currentStep = 1;
          _isLookingUp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Found: ${decoded.displayName}'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        return;
      }
    } catch (e) {
      // NHTSA lookup also failed
    }

    // Neither worked
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VIN not recognized. Please enter details manually.'),
        ),
      );
      setState(() {
        _currentStep = 1;
        _isLookingUp = false;
      });
    }
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final vehicle = Vehicle(
        vin: _vinController.text.trim().toUpperCase(),
        year: int.tryParse(_yearController.text) ?? DateTime.now().year,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        trim: _trimController.text.trim().isEmpty ? null : _trimController.text.trim(),
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        currentMileage: int.tryParse(_mileageController.text) ?? 0,
      );

      await _apiService.createVehicle(vehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('${vehicle.displayName} added!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
              colorScheme.tertiaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(theme, colorScheme),
                ),

                // Progress Indicator
                SliverToBoxAdapter(
                  child: _buildProgressIndicator(theme, colorScheme),
                ),

                // Step Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _currentStep == 0
                            ? _buildVinStep(theme, colorScheme)
                            : _buildDetailsStep(theme, colorScheme),
                      ),
                    ]),
                  ),
                ),
              ],
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
                  'Add Vehicle',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Add a new car to your garage',
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
              Icons.directions_car_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStepIndicator(
              theme,
              colorScheme,
              step: 1,
              label: 'VIN',
              isActive: _currentStep >= 0,
              isCompleted: _currentStep > 0,
            ),
          ),
          Container(
            width: 40,
            height: 2,
            color: _currentStep > 0
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
          Expanded(
            child: _buildStepIndicator(
              theme,
              colorScheme,
              step: 2,
              label: 'Details',
              isActive: _currentStep >= 1,
              isCompleted: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    ThemeData theme,
    ColorScheme colorScheme, {
    required int step,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? colorScheme.primary
                : isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check_rounded, color: colorScheme.onPrimary, size: 20)
                : Text(
                    '$step',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildVinStep(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('vin_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // VIN Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What is a VIN?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A 17-character code found on your dashboard or door frame that identifies your vehicle.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // VIN Input
        Text(
          'Vehicle Identification Number',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _vinController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 17,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.text,
          inputFormatters: [
            VinTextFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'Enter 17-character VIN',
            counterText: '${_vinController.text.length}/17',
            prefixIcon: Icon(Icons.tag_rounded, color: colorScheme.onSurfaceVariant),
            suffixIcon: _vinController.text.length == 17
                ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'VIN is required';
            }
            if (value.length != 17) {
              return 'VIN must be 17 characters';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),

        const SizedBox(height: 24),

        // Lookup Button
        FilledButton(
          onPressed: _isLookingUp || _vinController.text.length != 17
              ? null
              : _lookupVin,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _isLookingUp
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded),
                    SizedBox(width: 8),
                    Text('Look Up Vehicle'),
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // Skip Button
        Center(
          child: TextButton(
            onPressed: () {
              if (_vinController.text.length == 17) {
                setState(() => _currentStep = 1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid 17-character VIN')),
                );
              }
            },
            child: const Text('Skip lookup & enter manually'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('details_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Back to VIN step
        GestureDetector(
          onTap: () => setState(() => _currentStep = 0),
          child: Row(
            children: [
              Icon(Icons.arrow_back_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Edit VIN',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Year & Make Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: 'Year *',
                  hintText: '2024',
                  prefixIcon: Icon(Icons.calendar_today_rounded,
                      color: colorScheme.onSurfaceVariant),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _makeController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Make *',
                  hintText: 'Toyota',
                  prefixIcon: Icon(Icons.business_rounded,
                      color: colorScheme.onSurfaceVariant),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Make is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Popular Makes
        if (_makeController.text.isEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _popularMakes.take(9).map((make) {
              return GestureDetector(
                onTap: () {
                  setState(() => _makeController.text = make);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    make,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 16),

        // Model
        TextFormField(
          controller: _modelController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Model *',
            hintText: 'Camry',
            prefixIcon: Icon(Icons.directions_car_rounded,
                color: colorScheme.onSurfaceVariant),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Model is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Trim (optional)
        TextFormField(
          controller: _trimController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Trim (optional)',
            hintText: 'XLE, Sport, Limited, etc.',
            prefixIcon: Icon(Icons.style_rounded,
                color: colorScheme.onSurfaceVariant),
          ),
        ),

        const SizedBox(height: 16),

        // Mileage & Color Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _mileageController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Current Mileage',
                  hintText: '0',
                  prefixIcon: Icon(Icons.speed_rounded,
                      color: colorScheme.onSurfaceVariant),
                  suffixText: 'mi',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _colorController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Color (optional)',
                  hintText: 'Silver',
                  prefixIcon: Icon(Icons.palette_rounded,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Submit Button
        FilledButton(
          onPressed: _isSubmitting ? null : _submitVehicle,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: _isSubmitting
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded),
                    SizedBox(width: 8),
                    Text('Add Vehicle'),
                  ],
                ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }
}

/// Text formatter for VIN input - converts to uppercase and filters valid chars
class VinTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert to uppercase and keep only alphanumeric
    final upper = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    // Adjust selection if text was modified
    int selectionIndex = newValue.selection.baseOffset;
    if (selectionIndex > upper.length) {
      selectionIndex = upper.length;
    }
    
    return TextEditingValue(
      text: upper,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

/// Version of AddVehicleScreen with pre-filled data from NHTSA lookup
class AddVehicleScreenWithData extends StatefulWidget {
  final String vin;
  final String year;
  final String make;
  final String model;
  final String trim;

  const AddVehicleScreenWithData({
    super.key,
    required this.vin,
    required this.year,
    required this.make,
    required this.model,
    required this.trim,
  });

  @override
  State<AddVehicleScreenWithData> createState() => _AddVehicleScreenWithDataState();
}

class _AddVehicleScreenWithDataState extends State<AddVehicleScreenWithData> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileageController;
  late final TextEditingController _colorController;

  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mileageController = TextEditingController();
    _colorController = TextEditingController();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final vehicle = Vehicle(
        vin: widget.vin,
        year: int.tryParse(widget.year) ?? DateTime.now().year,
        make: widget.make,
        model: widget.model,
        trim: widget.trim.isEmpty ? null : widget.trim,
        color: _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        currentMileage: int.tryParse(_mileageController.text) ?? 0,
      );

      await _apiService.createVehicle(vehicle);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('${vehicle.displayName} added to garage!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    final displayName = '${widget.year} ${widget.make} ${widget.model}';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.15),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
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
                                'Add to Garage',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Complete vehicle details',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Vehicle Info Card (pre-filled, non-editable)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      if (widget.trim.isNotEmpty)
                                        Text(
                                          widget.trim,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tag_rounded,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.vin,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                        letterSpacing: 1,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Additional Details Section
                      Text(
                        'Additional Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optional information to help track your vehicle',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mileage
                      TextFormField(
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Current Mileage',
                          hintText: 'Enter odometer reading',
                          prefixIcon: Icon(Icons.speed_rounded,
                              color: colorScheme.onSurfaceVariant),
                          suffixText: 'miles',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Color
                      TextFormField(
                        controller: _colorController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Color (optional)',
                          hintText: 'e.g., Silver, Black, White',
                          prefixIcon: Icon(Icons.palette_rounded,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submitVehicle,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.garage_rounded),
                                  SizedBox(width: 8),
                                  Text('Add to My Garage'),
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
    );
  }
}

