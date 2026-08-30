import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/excavator_model.dart';
import '../../../../data/models/vehicle_rc_response.dart';

import '../providers/excavator_provider.dart';

class ExcavatorMasterAddEditScreen extends StatefulWidget {
  final int? excavatorId;

  const ExcavatorMasterAddEditScreen({super.key, this.excavatorId});

  bool get isEdit => excavatorId != null;

  @override
  State<ExcavatorMasterAddEditScreen> createState() =>
      _ExcavatorMasterAddEditScreenState();
}

class _ExcavatorMasterAddEditScreenState
    extends State<ExcavatorMasterAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _registrationController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

  // ============================================================
  // DATE STATE
  // ============================================================

  DateTime? _insuranceExpiry;
  DateTime? _fcExpiry;
  DateTime? _permitExpiry;
  DateTime? _taxExpiry;

  // ============================================================
  // STATE
  // ============================================================

  bool _status = true;

  bool _initializing = true;
  bool _saving = false;

  bool _registrationChecking = false;
  bool _registrationExists = false;

  bool _vehicleLookupLoading = false;
  bool _vehicleLookupCompleted = false;

  String? _vehicleLookupMessage;

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

  Future<void> _initialize() async {
    final provider = context.read<ExcavatorProvider>();

    try {
      // ----------------------------------------------------------
      // EDIT MODE
      // ----------------------------------------------------------

      if (widget.isEdit) {
        final excavator = await provider.getById(widget.excavatorId!);

        if (excavator != null && mounted) {
          _registrationController.text = excavator.registrationNumber;

          _manufacturerController.text = excavator.manufacturerName ?? '';

          _modelController.text = excavator.modelName ?? '';

          _yearController.text = excavator.manufacturingYear?.toString() ?? '';

          _insuranceExpiry = _parseDate(excavator.insuranceExpiry);

          _fcExpiry = _parseDate(excavator.fcExpiry);

          _permitExpiry = _parseDate(excavator.permitExpiry);

          _taxExpiry = _parseDate(excavator.taxExpiry);

          _status = excavator.status;

          _vehicleLookupCompleted = true;
          _vehicleLookupMessage = 'Vehicle details loaded from StoneFleet.';
        }
      }
    } catch (e) {
      if (mounted) {
        _vehicleLookupMessage = 'Unable to load excavator details: $e';
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

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
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

                        _buildMachineDetails(),

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

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),

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
                widget.isEdit ? 'Edit Excavator' : 'Add Excavator',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.isEdit
                    ? 'Update registered excavator details.'
                    : 'Register a new excavator in the fleet.',
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
  // MACHINE DETAILS
  // ============================================================

  Widget _buildMachineDetails() {
    return _sectionCard(
      title: 'Machine Details',
      icon: Icons.precision_manufacturing_outlined,
      child: Column(
        children: [
          // ------------------------------------------------------
          // REGISTRATION + SEARCH
          // ------------------------------------------------------
          Row(
            children: [
              Expanded(flex: 2, child: _buildRegistrationField()),

              const SizedBox(width: 20),

              Expanded(child: _buildYearField()),
            ],
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------
          // MANUFACTURER + MODEL
          // ------------------------------------------------------
          Row(
            children: [
              Expanded(child: _buildManufacturerField()),

              const SizedBox(width: 20),

              Expanded(child: _buildModelField()),
            ],
          ),

          // ------------------------------------------------------
          // LOOKUP STATUS
          // ------------------------------------------------------
          if (_vehicleLookupMessage != null) ...[
            const SizedBox(height: 14),
            _buildLookupStatus(),
          ],
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

      textCapitalization: TextCapitalization.characters,

      enabled: !_vehicleLookupLoading && !widget.isEdit,

      onChanged: (_) {
        if (_registrationExists || _vehicleLookupCompleted) {
          setState(() {
            _registrationExists = false;
            _vehicleLookupCompleted = false;
            _vehicleLookupMessage = null;

            // Clear API data when registration changes.
            if (!widget.isEdit) {
              _manufacturerController.clear();
              _modelController.clear();
              _yearController.clear();

              _insuranceExpiry = null;
              _fcExpiry = null;
              _permitExpiry = null;
              _taxExpiry = null;
            }
          });
        }
      },

      onFieldSubmitted: (_) {
        if (!widget.isEdit) {
          _lookupRegistration();
        }
      },

      decoration:
          _inputDecoration(
            label: 'Registration Number',
            hint: 'TN 38 AB 1234',
            icon: Icons.badge_outlined,
          ).copyWith(
            suffixIcon: _registrationChecking || _vehicleLookupLoading
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
                    tooltip: 'Fetch vehicle details',
                    icon: const Icon(Icons.search),
                    onPressed: widget.isEdit ? null : _lookupRegistration,
                  ),
            errorText: _registrationExists
                ? 'Registration number already exists'
                : null,
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

      readOnly: true,

      decoration:
          _inputDecoration(
            label: 'Manufacturer',
            hint: 'Auto populated from RC',
            icon: Icons.factory_outlined,
          ).copyWith(
            suffixIcon: _vehicleLookupCompleted
                ? const Icon(Icons.verified, color: Color(0xFF00652C))
                : null,
          ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Manufacturer details not available';
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

      readOnly: true,

      decoration:
          _inputDecoration(
            label: 'Excavator Model',
            hint: 'Auto populated from RC',
            icon: Icons.construction_outlined,
          ).copyWith(
            suffixIcon: _vehicleLookupCompleted
                ? const Icon(Icons.verified, color: Color(0xFF00652C))
                : null,
          ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Model details not available';
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

      keyboardType: TextInputType.number,

      readOnly: true,

      decoration: _inputDecoration(
        label: 'Manufacturing Year',
        hint: 'Auto populated from RC',
        icon: Icons.calendar_today_outlined,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }

        final year = int.tryParse(value.trim());

        if (year == null) {
          return 'Enter a valid year';
        }

        if (year < 1950 || year > DateTime.now().year) {
          return 'Enter a valid year';
        }

        return null;
      },
    );
  }

  // ============================================================
  // VEHICLE LOOKUP
  // ============================================================

  Future<void> _lookupRegistration() async {
    final registration = _normalizeRegistration(_registrationController.text);

    if (registration.isEmpty) {
      _showError('Enter registration number first.');

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _registrationChecking = true;
      _vehicleLookupLoading = false;
      _registrationExists = false;
      _vehicleLookupCompleted = false;
      _vehicleLookupMessage = null;
    });

    final provider = context.read<ExcavatorProvider>();

    try {
      // ==========================================================
      // STEP 1
      // CHECK LOCAL SQLITE FIRST
      // ==========================================================

      final exists = await provider.registrationExists(
        registration,
        excludeId: widget.excavatorId,
      );

      if (!mounted) return;

      setState(() {
        _registrationChecking = false;
        _registrationExists = exists;
      });

      // ----------------------------------------------------------
      // DUPLICATE
      // ----------------------------------------------------------

      if (exists) {
        await _showAlreadyExistsDialog(registration);

        return;
      }

      // ==========================================================
      // STEP 2
      // CALL WAY2API
      // ==========================================================

      setState(() {
        _vehicleLookupLoading = true;
        _vehicleLookupMessage = 'Fetching vehicle details...';
      });

      final VehicleRcModel? vehicle = await provider.lookupVehicle(
        registration,
      );

      if (!mounted) return;

      if (vehicle == null) {
        setState(() {
          _vehicleLookupLoading = false;
          _vehicleLookupMessage =
              provider.error ?? 'Unable to fetch vehicle details.';
        });

        return;
      }

      // ==========================================================
      // STEP 3
      // POPULATE FORM
      // ==========================================================

      _populateVehicleData(vehicle);

      if (!mounted) return;

      setState(() {
        _vehicleLookupLoading = false;
        _vehicleLookupCompleted = true;

        _vehicleLookupMessage = 'Vehicle details fetched successfully.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle details fetched successfully.'),
          backgroundColor: Color(0xFF00652C),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _registrationChecking = false;
        _vehicleLookupLoading = false;
        _vehicleLookupMessage = 'Vehicle lookup failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _registrationChecking = false;
        });
      }
    }
  }

  // ============================================================
  // POPULATE VEHICLE DATA
  // ============================================================

  void _populateVehicleData(VehicleRcModel vehicle) {
    final manufacturingYear = _extractYear(vehicle.manufacturingDate);

    final insuranceDate = _parseDate(vehicle.insuranceExpiry);

    final fcDate = _parseDate(vehicle.fitnessExpiry);

    final permitDate = _parseDate(vehicle.permitExpiry);

    final taxDate = _parseDate(vehicle.taxExpiry);

    setState(() {
      // ----------------------------------------------------------
      // REGISTRATION
      // ----------------------------------------------------------

      _registrationController.text = _normalizeRegistration(
        vehicle.registrationNumber,
      );

      // ----------------------------------------------------------
      // MANUFACTURER
      // ----------------------------------------------------------

      _manufacturerController.text = vehicle.manufacturer ?? '';

      // ----------------------------------------------------------
      // MODEL
      // ----------------------------------------------------------

      _modelController.text = vehicle.model ?? '';

      // ----------------------------------------------------------
      // MANUFACTURING YEAR
      // ----------------------------------------------------------

      _yearController.text = manufacturingYear?.toString() ?? '';

      // ----------------------------------------------------------
      // DOCUMENT EXPIRY
      // ----------------------------------------------------------

      _insuranceExpiry = insuranceDate;
      _fcExpiry = fcDate;
      _permitExpiry = permitDate;
      _taxExpiry = taxDate;
    });
  }

  // ============================================================
  // ALREADY EXISTS POPUP
  // ============================================================

  Future<void> _showAlreadyExistsDialog(String registration) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
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
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // LOOKUP STATUS
  // ============================================================

  Widget _buildLookupStatus() {
    final success = _vehicleLookupCompleted;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      decoration: BoxDecoration(
        color: success ? const Color(0xFFE8F5E9) : const Color(0xFFFFF4E5),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(
          color: success ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
        ),
      ),

      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.info_outline,

            size: 20,

            color: success ? const Color(0xFF00652C) : const Color(0xFF9A6700),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _vehicleLookupMessage ?? '',
              style: TextStyle(
                fontSize: 13,

                color: success
                    ? const Color(0xFF00652C)
                    : const Color(0xFF7A4F00),

                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLIANCE
  // ============================================================

  Widget _buildComplianceSection() {
    return _sectionCard(
      title: 'Vehicle Compliance',
      icon: Icons.verified_user_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'Insurance Expiry',
                  value: _insuranceExpiry,
                  onChanged: (value) {
                    setState(() {
                      _insuranceExpiry = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _dateField(
                  label: 'FC Expiry',
                  value: _fcExpiry,
                  onChanged: (value) {
                    setState(() {
                      _fcExpiry = value;
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
                child: _dateField(
                  label: 'Permit Expiry',
                  value: _permitExpiry,
                  onChanged: (value) {
                    setState(() {
                      _permitExpiry = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _dateField(
                  label: 'Tax Expiry',
                  value: _taxExpiry,
                  onChanged: (value) {
                    setState(() {
                      _taxExpiry = value;
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

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: _vehicleLookupLoading
          ? null
          : () async {
              final selected = await showDatePicker(
                context: context,

                initialDate: value ?? DateTime.now(),

                firstDate: DateTime(2000),

                lastDate: DateTime(2100),
              );

              if (selected != null) {
                onChanged(selected);
              }
            },

      child: InputDecorator(
        decoration: _inputDecoration(label: label, icon: Icons.event_outlined),

        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Select date' : _formatDate(value),

                style: TextStyle(
                  color: value == null
                      ? const Color(0xFF6F7A6E)
                      : const Color(0xFF191C1E),
                ),
              ),
            ),

            if (value != null)
              IconButton(
                tooltip: 'Clear',

                icon: const Icon(Icons.clear, size: 18),

                onPressed: _vehicleLookupLoading
                    ? null
                    : () {
                        onChanged(null);
                      },
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
          'Active Excavator',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Text(
          _status
              ? 'This excavator is currently active.'
              : 'This excavator is currently inactive.',
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

          label: Text(widget.isEdit ? 'Update Excavator' : 'Save Excavator'),

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final registration = _normalizeRegistration(_registrationController.text);

    if (registration.isEmpty) {
      _showError('Enter registration number.');

      return;
    }

    final manufacturer = _manufacturerController.text.trim();

    final model = _modelController.text.trim();

    // ----------------------------------------------------------
    // NEW VEHICLE MUST HAVE API DATA
    // ----------------------------------------------------------

    if (!widget.isEdit) {
      if (!_vehicleLookupCompleted) {
        _showError(
          'Please search the registration number '
          'and fetch vehicle details first.',
        );

        return;
      }
    }

    if (manufacturer.isEmpty) {
      _showError('Manufacturer details are not available.');

      return;
    }

    if (model.isEmpty) {
      _showError('Vehicle model details are not available.');

      return;
    }

    final provider = context.read<ExcavatorProvider>();

    // ==========================================================
    // FINAL DUPLICATE CHECK
    // ==========================================================

    final exists = await provider.registrationExists(
      registration,
      excludeId: widget.excavatorId,
    );

    if (!mounted) return;

    if (exists) {
      setState(() {
        _registrationExists = true;
      });

      await _showAlreadyExistsDialog(registration);

      return;
    }

    // ==========================================================
    // SAVE
    // ==========================================================

    setState(() {
      _saving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final excavator = ExcavatorModel(
        id: widget.excavatorId,

        registrationNumber: registration,

        manufacturerName: manufacturer,

        modelName: model,

        manufacturingYear: int.tryParse(_yearController.text.trim()),

        status: _status,

        insuranceExpiry: _formatDatabaseDate(_insuranceExpiry),

        fcExpiry: _formatDatabaseDate(_fcExpiry),

        permitExpiry: _formatDatabaseDate(_permitExpiry),

        taxExpiry: _formatDatabaseDate(_taxExpiry),

        createdAt: now,

        updatedAt: now,
      );

      final bool success;

      if (widget.isEdit) {
        success = await provider.updateExcavator(excavator);
      } else {
        success = await provider.addExcavator(excavator);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Excavator updated successfully.'
                  : 'Excavator added successfully.',
            ),
            backgroundColor: const Color(0xFF00652C),
          ),
        );

        Navigator.pop(context, true);
      } else {
        _showError(provider.error ?? 'Unable to save excavator.');
      }
    } catch (e) {
      if (!mounted) return;

      _showError('Unable to save excavator: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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

        border: Border.all(color: const Color(0xFFBECABC)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF00652C)),

              const SizedBox(width: 8),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: icon == null ? null : Icon(icon),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),

        borderSide: const BorderSide(color: Color(0xFFBECABC)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),

        borderSide: const BorderSide(color: Color(0xFFBECABC)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),

        borderSide: const BorderSide(color: Color(0xFF00652C), width: 2),
      ),
    );
  }

  // ============================================================
  // NORMALIZE REGISTRATION
  // ============================================================

  String _normalizeRegistration(String value) {
    return value.replaceAll(' ', '').replaceAll('-', '').trim().toUpperCase();
  }

  // ============================================================
  // EXTRACT YEAR
  // ============================================================

  int? _extractYear(String? manufacturingDate) {
    if (manufacturingDate == null || manufacturingDate.isEmpty) {
      return null;
    }

    final match = RegExp(r'(19|20)\d{2}').firstMatch(manufacturingDate);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(0)!);
  }

  // ============================================================
  // DATE PARSE
  // ============================================================

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  // ============================================================
  // DATABASE DATE
  // ============================================================

  String? _formatDatabaseDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  // ============================================================
  // DISPLAY DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }
}
