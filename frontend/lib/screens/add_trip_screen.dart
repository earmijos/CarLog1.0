import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AddTripScreen extends StatefulWidget {
  final String vin;

  const AddTripScreen({super.key, required this.vin});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _startMileageController = TextEditingController();
  final _endMileageController = TextEditingController();
  final _notesController = TextEditingController();

  final ApiService _apiService = ApiService();
  late AnimationController _animationController;

  String _selectedPurpose = 'Commute';
  bool _isBusiness = false;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  bool _useManualDistance = false;
  final _manualDistanceController = TextEditingController();

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
    _startLocationController.dispose();
    _endLocationController.dispose();
    _startMileageController.dispose();
    _endMileageController.dispose();
    _notesController.dispose();
    _manualDistanceController.dispose();
    super.dispose();
  }

  double? get _calculatedDistance {
    if (_useManualDistance) {
      return double.tryParse(_manualDistanceController.text);
    }
    final start = int.tryParse(_startMileageController.text);
    final end = int.tryParse(_endMileageController.text);
    if (start != null && end != null && end > start) {
      return (end - start).toDouble();
    }
    return null;
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

  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_calculatedDistance == null || _calculatedDistance! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter valid distance'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final trip = Trip(
        vin: widget.vin,
        startLocation: _startLocationController.text.isEmpty
            ? null
            : _startLocationController.text,
        endLocation: _endLocationController.text.isEmpty
            ? null
            : _endLocationController.text,
        startMileage: int.tryParse(_startMileageController.text),
        endMileage: int.tryParse(_endMileageController.text),
        distance: _calculatedDistance,
        date: _selectedDate.toIso8601String().split('T')[0],
        purpose: _selectedPurpose,
        isBusiness: _isBusiness,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await _apiService.createTrip(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Trip logged successfully!'),
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
              const Color(0xFF3B82F6).withValues(alpha: 0.15),
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
                        // Trip Type Toggle
                        _buildTripTypeToggle(theme, colorScheme),

                        const SizedBox(height: 24),

                        // Locations Section
                        _buildSectionTitle(theme, colorScheme, 'Route', Icons.route_rounded),
                        const SizedBox(height: 12),

                        _buildLocationField(
                          controller: _startLocationController,
                          label: 'Start Location',
                          hint: 'e.g., Home, Office',
                          icon: Icons.trip_origin_rounded,
                          iconColor: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 12),

                        _buildLocationField(
                          controller: _endLocationController,
                          label: 'End Location',
                          hint: 'e.g., Client Office, Airport',
                          icon: Icons.location_on_rounded,
                          iconColor: const Color(0xFFEF4444),
                        ),

                        const SizedBox(height: 24),

                        // Distance Section
                        _buildSectionTitle(theme, colorScheme, 'Distance', Icons.straighten_rounded),
                        const SizedBox(height: 12),

                        // Toggle between manual distance and odometer
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _useManualDistance = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_useManualDistance
                                          ? const Color(0xFF3B82F6)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Odometer',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: !_useManualDistance
                                            ? Colors.white
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: !_useManualDistance
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _useManualDistance = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _useManualDistance
                                          ? const Color(0xFF3B82F6)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Manual',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        color: _useManualDistance
                                            ? Colors.white
                                            : colorScheme.onSurfaceVariant,
                                        fontWeight: _useManualDistance
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_useManualDistance)
                          _buildTextField(
                            controller: _manualDistanceController,
                            label: 'Distance (miles)',
                            hint: '0.0',
                            icon: Icons.straighten_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                            ],
                            onChanged: (_) => setState(() {}),
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _startMileageController,
                                  label: 'Start Odometer',
                                  hint: 'Start miles',
                                  icon: Icons.play_circle_outline_rounded,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _endMileageController,
                                  label: 'End Odometer',
                                  hint: 'End miles',
                                  icon: Icons.stop_circle_outlined,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 12),

                        // Distance Display
                        if (_calculatedDistance != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.directions_rounded,
                                  color: Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Trip Distance',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF1E3A5F),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_calculatedDistance!.toStringAsFixed(1)} miles',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

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

                        const SizedBox(height: 24),

                        // Purpose Selector
                        _buildSectionTitle(theme, colorScheme, 'Purpose', Icons.category_rounded),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: TripPurposes.all.map((purpose) {
                            final isSelected = _selectedPurpose == purpose;
                            return ChoiceChip(
                              label: Text(purpose),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedPurpose = purpose;
                                  // Auto-set business flag for business purpose
                                  if (purpose == 'Business') {
                                    _isBusiness = true;
                                  }
                                });
                              },
                              selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : colorScheme.onSurfaceVariant,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Notes (optional)
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          hint: 'Optional notes about this trip',
                          icon: Icons.note_rounded,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 32),

                        // Submit Button
                        FilledButton(
                          onPressed: _isSubmitting ? null : _submitTrip,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    Icon(Icons.add_road_rounded),
                                    SizedBox(width: 8),
                                    Text('Log Trip'),
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
                  'Log Trip',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Record your journey',
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
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: Color(0xFF3B82F6),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBusiness = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !_isBusiness
                      ? const Color(0xFF8B5CF6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: !_isBusiness
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Personal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: !_isBusiness
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            !_isBusiness ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isBusiness = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isBusiness
                      ? const Color(0xFF10B981)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_center_rounded,
                      size: 20,
                      color: _isBusiness
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Business',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _isBusiness
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            _isBusiness ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: iconColor),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
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

