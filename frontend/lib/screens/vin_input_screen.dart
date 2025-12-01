import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'car_info_screen.dart';
import '../services/vin_decoder_service.dart';

class VinInputScreen extends StatefulWidget {
  const VinInputScreen({super.key});

  @override
  State<VinInputScreen> createState() => _VinInputScreenState();
}

class _VinInputScreenState extends State<VinInputScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _vinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // VIN decode state
  VinDecodeResult? _decodeResult;
  bool _isDecoding = false;
  String? _decodeError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Listen to VIN input changes
    _vinController.addListener(_onVinChanged);
  }

  @override
  void dispose() {
    _vinController.removeListener(_onVinChanged);
    _vinController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onVinChanged() {
    final vin = _vinController.text.trim().toUpperCase();
    
    // Clear previous result if VIN is incomplete
    if (vin.length != 17) {
      if (_decodeResult != null || _decodeError != null) {
        setState(() {
          _decodeResult = null;
          _decodeError = null;
        });
      }
      return;
    }

    // Decode VIN when it reaches 17 characters
    _decodeVin(vin);
  }

  Future<void> _decodeVin(String vin) async {
    setState(() {
      _isDecoding = true;
      _decodeError = null;
    });

    try {
      final result = await VinDecoderService.decodeVin(vin);
      
      if (mounted) {
        setState(() {
          _decodeResult = result;
          _isDecoding = false;
          if (result == null) {
            _decodeError = 'Could not decode VIN';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDecoding = false;
          _decodeError = 'Network error - check connection';
        });
      }
    }
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final vin = _vinController.text.trim().toUpperCase();
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CarInfoScreen(vin: vin),
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
  }

  String? _validateVin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a VIN';
    }
    if (value.trim().length != 17) {
      return 'VIN must be exactly 17 characters';
    }
    return null;
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
              colorScheme.surface,
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.3),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            size: 50,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'CarLog',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Track your vehicle maintenance & repairs',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // VIN Input Card
                        Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
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
                                            'Enter Vehicle VIN',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '17-character Vehicle Identification Number',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // NHTSA badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 12,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'NHTSA',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _vinController,
                                  validator: _validateVin,
                                  maxLength: 17,
                                  textCapitalization: TextCapitalization.characters,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    UpperCaseTextFormatter(),
                                  ],
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 1HGCM82633A004352',
                                    hintStyle: TextStyle(
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      letterSpacing: 1,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.tag_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    suffixIcon: _isDecoding
                                        ? Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          )
                                        : _decodeResult != null
                                            ? Icon(
                                                Icons.check_circle_rounded,
                                                color: const Color(0xFF10B981),
                                              )
                                            : null,
                                    filled: true,
                                    fillColor: colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.error,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.error,
                                        width: 2,
                                      ),
                                    ),
                                    counterText: '',
                                  ),
                                  onFieldSubmitted: (_) => _onSubmit(),
                                ),

                                // Vehicle Info Preview
                                if (_decodeResult != null) ...[
                                  const SizedBox(height: 16),
                                  _buildVehiclePreview(theme, colorScheme),
                                ],

                                // Error message
                                if (_decodeError != null && !_isDecoding) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _decodeError!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Search Button
                        FilledButton(
                          onPressed: _onSubmit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_rounded, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Look Up Vehicle',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info text
                        Text(
                          'VIN decoded via NHTSA (National Highway Traffic Safety Administration)',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehiclePreview(ThemeData theme, ColorScheme colorScheme) {
    final result = _decodeResult!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Found!',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      result.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Details grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (result.bodyClass != null)
                _buildDetailChip(theme, colorScheme, Icons.category_rounded, result.bodyClass!),
              if (result.engineDescription != null)
                _buildDetailChip(theme, colorScheme, Icons.settings_rounded, result.engineDescription!),
              if (result.fuelType != null)
                _buildDetailChip(theme, colorScheme, Icons.local_gas_station_rounded, result.fuelType!),
              if (result.driveType != null)
                _buildDetailChip(theme, colorScheme, Icons.swap_horiz_rounded, result.driveType!),
              if (result.transmissionStyle != null)
                _buildDetailChip(theme, colorScheme, Icons.speed_rounded, result.transmissionStyle!),
              if (result.plantCountry != null)
                _buildDetailChip(theme, colorScheme, Icons.flag_rounded, 'Made in ${result.plantCountry}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom text formatter to convert input to uppercase and filter valid VIN chars
class UpperCaseTextFormatter extends TextInputFormatter {
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
