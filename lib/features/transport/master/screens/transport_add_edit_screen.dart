import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/transport_vehicle_model.dart';
import '../providers/transport_master_provider.dart';

class TransportAddEditScreen extends StatefulWidget {
  final int? vehicleId;

  const TransportAddEditScreen({super.key, this.vehicleId});

  bool get isEdit => vehicleId != null;

  @override
  State<TransportAddEditScreen> createState() => _TransportAddEditScreenState();
}

class _TransportAddEditScreenState extends State<TransportAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _registrationController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _emissionController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  DateTime? _insuranceExpiry;
  DateTime? _fcExpiry;
  DateTime? _permitExpiry;
  DateTime? _taxExpiry;

  bool _status = true;

  bool _registrationExists = false;
  bool _registrationChecking = false;
  bool _registrationChecked = false;

  bool _initializing = true;
  bool _saving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    if (!widget.isEdit) {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }

      return;
    }

    final provider = context.read<TransportProvider>();

    try {
      final vehicle = await provider.getById(widget.vehicleId!);

      if (vehicle != null && mounted) {
        _registrationController.text = vehicle.registrationNumber;

        _manufacturerController.text = vehicle.manufacturerName ?? '';

        _modelController.text = vehicle.modelName ?? '';

        _yearController.text = vehicle.manufacturingYear?.toString() ?? '';

        _emissionController.text = vehicle.emissionStandard ?? '';

        _insuranceExpiry = _parseDate(vehicle.insuranceExpiry);

        _fcExpiry = _parseDate(vehicle.fcExpiry);

        _permitExpiry = _parseDate(vehicle.permitExpiry);

        _taxExpiry = _parseDate(vehicle.taxExpiry);

        _status = vehicle.status;
      }
    } catch (e) {
      if (mounted) {
        _showError('Unable to load vehicle: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _registrationController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _emissionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00652C)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),

      body: Column(
        children: [
          _buildTopBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),

                  child: Form(
                    key: _formKey,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        _buildHeader(),

                        const SizedBox(height: 24),

                        _buildVehicleDetailsSection(),

                        const SizedBox(height: 20),

                        _buildComplianceSection(),

                        const SizedBox(height: 20),

                        _buildStatusSection(),

                        const SizedBox(height: 28),

                        _buildBottomActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Container(
      height: 64,

      padding: const EdgeInsets.symmetric(horizontal: 24),

      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(bottom: BorderSide(color: Color(0xFFBECABC))),
      ),

      child: Row(
        children: [
          IconButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.arrow_back),
          ),

          const SizedBox(width: 8),

          const Text(
            'StoneFleet ERP Manager',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.notifications_outlined),
          // ),
          const SizedBox(width: 8),

          const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person_outline, color: Color(0xFF00652C)),
          ),

          const SizedBox(width: 8),

          const Text('Admin', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                widget.isEdit
                    ? 'Edit Transport Vehicle'
                    : 'Add Transport Vehicle',

                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.isEdit
                    ? 'Update transport vehicle details.'
                    : 'Register a new transport vehicle in the fleet.',

                style: const TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(context);
                },
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Cancel'),
        ),
      ],
    );
  }

  // ============================================================
  // VEHICLE DETAILS
  // ============================================================

  Widget _buildVehicleDetailsSection() {
    return _sectionCard(
      title: 'Vehicle Details',
      icon: Icons.local_shipping_outlined,

      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildRegistrationField()),

              const SizedBox(width: 20),

              Expanded(child: _buildYearField()),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildManufacturerField()),

              const SizedBox(width: 20),

              Expanded(child: _buildModelField()),
            ],
          ),

          const SizedBox(height: 20),

          _buildEmissionField(),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRATION
  // ============================================================

  Widget _buildRegistrationField() {
    return TextFormField(
      controller: _registrationController,

      enabled: !_saving,

      textCapitalization: TextCapitalization.characters,

      onChanged: (_) {
        if (_registrationExists || _registrationChecked) {
          setState(() {
            _registrationExists = false;
            _registrationChecked = false;
          });
        }
      },

      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 -]')),
        UpperCaseTextFormatter(),
      ],
      onFieldSubmitted: (_) {
        _checkRegistration();
      },

      decoration:
          _inputDecoration(
            label: 'Registration Number',
            hint: 'TN 38 AB 1234',
            icon: Icons.badge_outlined,
          ).copyWith(
            suffixIcon: _registrationChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),

                    child: SizedBox(
                      width: 18,
                      height: 18,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00652C),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Check registration',

                    icon: Icon(
                      _registrationExists
                          ? Icons.error_outline
                          : _registrationChecked
                          ? Icons.check_circle_outline
                          : Icons.search,

                      color: _registrationExists
                          ? const Color(0xFFBA1A1A)
                          : _registrationChecked
                          ? const Color(0xFF00652C)
                          : null,
                    ),

                    onPressed: _checkRegistration,
                  ),
          ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter registration number';
        }

        if (_registrationExists) {
          return 'Registration number already exists';
        }

        return null;
      },
    );
  }

  // ============================================================
  // MANUFACTURER
  // ============================================================

  Widget _buildManufacturerField() {
    return TextFormField(
      controller: _manufacturerController,

      enabled: !_saving,

      textCapitalization: TextCapitalization.words,

      decoration: _inputDecoration(
        label: 'Manufacturer',
        hint: 'Example: Tata',
        icon: Icons.factory_outlined,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter manufacturer';
        }

        return null;
      },
    );
  }

  // ============================================================
  // MODEL
  // ============================================================

  Widget _buildModelField() {
    return TextFormField(
      controller: _modelController,

      enabled: !_saving,

      textCapitalization: TextCapitalization.words,

      decoration: _inputDecoration(
        label: 'Vehicle Model',
        hint: 'Example: Prima',
        icon: Icons.local_shipping_outlined,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter vehicle model';
        }

        return null;
      },
    );
  }

  // ============================================================
  // YEAR
  // ============================================================

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,

      enabled: !_saving,

      keyboardType: TextInputType.number,

      decoration: _inputDecoration(
        label: 'Manufacturing Year',
        hint: '2024',
        icon: Icons.calendar_today_outlined,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter manufacturing year';
        }

        final year = int.tryParse(value.trim());

        if (year == null) {
          return 'Enter a valid year';
        }

        if (year < 1900 || year > DateTime.now().year) {
          return 'Enter a valid year';
        }

        return null;
      },
    );
  }

  // ============================================================
  // EMISSION
  // ============================================================

  Widget _buildEmissionField() {
    return TextFormField(
      controller: _emissionController,

      enabled: !_saving,

      textCapitalization: TextCapitalization.characters,

      decoration: _inputDecoration(
        label: 'Emission Standard',
        hint: 'Example: BS6',
        icon: Icons.eco_outlined,
      ),
    );
  }

  // ============================================================
  // COMPLIANCE
  // ============================================================

  Widget _buildComplianceSection() {
    return _sectionCard(
      title: 'Compliance Documents',
      icon: Icons.description_outlined,

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Insurance Expiry',
                  value: _insuranceExpiry,
                  onChanged: (date) {
                    setState(() {
                      _insuranceExpiry = date;
                    });
                  },
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildDateField(
                  label: 'FC Expiry',
                  value: _fcExpiry,
                  onChanged: (date) {
                    setState(() {
                      _fcExpiry = date;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Permit Expiry',
                  value: _permitExpiry,
                  onChanged: (date) {
                    setState(() {
                      _permitExpiry = date;
                    });
                  },
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildDateField(
                  label: 'Tax Expiry',
                  value: _taxExpiry,
                  onChanged: (date) {
                    setState(() {
                      _taxExpiry = date;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: _saving
          ? null
          : () async {
              final now = DateTime.now();

              final selected = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (selected != null) {
                onChanged(selected);
              }
            },

      borderRadius: BorderRadius.circular(10),

      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          icon: Icons.calendar_month_outlined,
        ),

        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Select date' : _formatDate(value),

                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? const Color(0xFF68717D)
                      : const Color(0xFF191C1E),
                ),
              ),
            ),

            if (value != null)
              IconButton(
                tooltip: 'Clear date',

                icon: const Icon(Icons.clear, size: 18),

                onPressed: _saving
                    ? null
                    : () {
                        onChanged(null);
                      },
              )
            else
              const Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: Color(0xFF68736A),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusSection() {
    return _sectionCard(
      title: 'Status',
      icon: Icons.toggle_on_outlined,

      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,

        title: const Text(
          'Active Vehicle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Text(
          _status
              ? 'This vehicle is currently active.'
              : 'This vehicle is currently inactive.',
        ),

        value: _status,

        activeThumbColor: const Color(0xFF00652C),

        onChanged: _saving
            ? null
            : (value) {
                setState(() {
                  _status = value;
                });
              },
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,

      children: [
        OutlinedButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(context);
                },

          child: const Text('Cancel'),
        ),

        const SizedBox(width: 12),

        FilledButton.icon(
          onPressed: _saving ? null : _save,

          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),

          label: Text(widget.isEdit ? 'Update Vehicle' : 'Save Vehicle'),

          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),

            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final registration = _normalizeRegistration(_registrationController.text);

    if (registration.isEmpty) {
      _showError('Enter registration number.');
      return;
    }

    // ==========================================================
    // FINAL DUPLICATE CHECK
    // ==========================================================

    final provider = context.read<TransportProvider>();

    // If your provider has registrationExists(),
    // this block can be enabled.
    //
    // final exists = await provider.registrationExists(
    //   registration,
    //   excludeId: widget.vehicleId,
    // );
    //
    // if (!mounted) return;
    //
    // if (exists) {
    //   setState(() {
    //     _registrationExists = true;
    //     _registrationChecked = true;
    //   });
    //
    //   await _showAlreadyExistsDialog(registration);
    //   return;
    // }

    setState(() {
      _saving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final vehicle = TransportModel(
        id: widget.vehicleId,

        registrationNumber: registration,

        manufacturerName: _manufacturerController.text.trim(),

        modelName: _modelController.text.trim(),

        manufacturingYear: int.tryParse(_yearController.text.trim()),

        emissionStandard: _emissionController.text.trim().isEmpty
            ? null
            : _emissionController.text.trim(),

        insuranceExpiry: _formatDatabaseDate(_insuranceExpiry),

        fcExpiry: _formatDatabaseDate(_fcExpiry),

        permitExpiry: _formatDatabaseDate(_permitExpiry),

        taxExpiry: _formatDatabaseDate(_taxExpiry),

        status: _status,

        createdAt: widget.isEdit ? await _getOriginalCreatedAt(provider) : now,

        updatedAt: now,
      );

      final bool success;

      if (widget.isEdit) {
        success = await provider.updateVehicle(vehicle);
      } else {
        success = await provider.addVehicle(vehicle);
      }

      if (!mounted) return;

      if (success) {
        _showSuccess(
          widget.isEdit
              ? 'Transport vehicle updated successfully.'
              : 'Transport vehicle added successfully.',
        );

        Navigator.pop(context, true);
      } else {
        _showError(provider.error ?? 'Unable to save transport vehicle.');
      }
    } catch (e) {
      if (!mounted) return;

      _showError('Unable to save vehicle: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // ORIGINAL CREATED DATE
  // ============================================================

  Future<String> _getOriginalCreatedAt(TransportProvider provider) async {
    if (widget.vehicleId == null) {
      return DateTime.now().toIso8601String();
    }

    final existing = await provider.getById(widget.vehicleId!);

    return existing?.createdAt ?? DateTime.now().toIso8601String();
  }

  // ============================================================
  // CHECK REGISTRATION
  // ============================================================

  Future<void> _checkRegistration() async {
    if (_registrationChecking) {
      return;
    }

    final registration = _normalizeRegistration(_registrationController.text);

    if (registration.isEmpty) {
      _showError('Enter registration number first.');
      return;
    }

    setState(() {
      _registrationChecking = true;
      _registrationExists = false;
      _registrationChecked = false;
    });

    try {
      /*
       * Add registrationExists() to TransportProvider
       * if you want the same instant duplicate-check
       * behaviour as Excavator.
       */

      final exists = await _registrationExistsInList(registration);

      if (!mounted) return;

      setState(() {
        _registrationChecking = false;

        _registrationExists = exists;

        _registrationChecked = true;
      });

      if (exists) {
        await _showAlreadyExistsDialog(registration);
      } else {
        _showSuccess('Registration number is available.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _registrationChecking = false;

        _registrationChecked = false;
      });

      _showError('Unable to check registration: $e');
    }
  }

  // ============================================================
  // REGISTRATION EXISTS
  // ============================================================

  Future<bool> _registrationExistsInList(String registration) async {
    final provider = context.read<TransportProvider>();

    final vehicles = provider.vehicles;

    return vehicles.any(
      (vehicle) =>
          vehicle.id != widget.vehicleId &&
          _normalizeRegistration(vehicle.registrationNumber) == registration,
    );
  }

  // ============================================================
  // ALREADY EXISTS
  // ============================================================

  Future<void> _showAlreadyExistsDialog(String registration) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),

              SizedBox(width: 10),

              Text('Vehicle Already Exists'),
            ],
          ),

          content: Text(
            'The registration number '
            '$registration is already registered '
            'in StoneFleet.',
          ),

          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },

              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
              ),

              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: const Color(0xFFE1E5E9)),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),

                  borderRadius: BorderRadius.circular(8),
                ),

                child: Icon(icon, color: const Color(0xFF00652C), size: 20),
              ),

              const SizedBox(width: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(icon, size: 20),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xFFD8DDE3)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xFFD8DDE3)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xFF00652C), width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),

        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String? _formatDatabaseDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _normalizeRegistration(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00652C),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }
}

// ================================================================
// UPPER CASE FORMATTER
// ================================================================

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
