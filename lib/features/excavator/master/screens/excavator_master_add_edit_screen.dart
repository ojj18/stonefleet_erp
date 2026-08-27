import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/excavator_model.dart';
import '../../../../data/models/excavator_master_model.dart';

import '../providers/excavator_provider.dart';
import '../providers/excavator_master_provider.dart';

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

  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------

  final _registrationController = TextEditingController();
  final _yearController = TextEditingController();

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  int? _selectedManufacturerId;
  int? _selectedModelId;

  DateTime? _insuranceExpiry;
  DateTime? _fcExpiry;
  DateTime? _permitExpiry;
  DateTime? _taxExpiry;

  bool _status = true;

  bool _initializing = true;
  bool _saving = false;

  bool _registrationChecking = false;
  bool _registrationExists = false;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final modelProvider = context.read<ExcavatorMasterProvider>();

    final excavatorProvider = context.read<ExcavatorProvider>();

    try {
      // Load all excavator models initially.
      await modelProvider.loadModels();

      // ----------------------------------------------------------
      // EDIT MODE
      // ----------------------------------------------------------

      if (widget.isEdit) {
        final excavator = await excavatorProvider.getById(widget.excavatorId!);

        if (excavator != null && mounted) {
          _registrationController.text = excavator.registrationNumber;

          _yearController.text = excavator.manufacturingYear?.toString() ?? '';

          _selectedManufacturerId = excavator.manufacturerId;

          _selectedModelId = excavator.modelId;

          _status = excavator.status;

          _insuranceExpiry = _parseDate(excavator.insuranceExpiry);

          _fcExpiry = _parseDate(excavator.fcExpiry);

          _permitExpiry = _parseDate(excavator.permitExpiry);

          _taxExpiry = _parseDate(excavator.taxExpiry);

          // Load models for the selected manufacturer.
          await modelProvider.loadByManufacturer(excavator.manufacturerId);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _registrationController.dispose();
    _yearController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
            onPressed: () {
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
          onPressed: () {
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
          Row(
            children: [
              Expanded(child: _buildManufacturerDropdown()),
              const SizedBox(width: 20),
              Expanded(child: _buildModelDropdown()),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildRegistrationField()),
              const SizedBox(width: 20),
              Expanded(child: _buildYearField()),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MANUFACTURER
  // ============================================================

  Widget _buildManufacturerDropdown() {
    final provider = context.watch<ExcavatorMasterProvider>();

    final manufacturers = _getUniqueManufacturers(provider.models);

    return DropdownButtonFormField<int>(
      initialValue: _selectedManufacturerId,
      decoration: _inputDecoration(
        label: 'Manufacturer',
        icon: Icons.factory_outlined,
      ),
      hint: const Text('Select manufacturer'),
      items: manufacturers.map((model) {
        return DropdownMenuItem<int>(
          value: model.manufacturerId,
          child: Text('Manufacturer #${model.manufacturerId}'),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Select manufacturer';
        }

        return null;
      },
      onChanged: (value) async {
        if (value == null) return;

        setState(() {
          _selectedManufacturerId = value;
          _selectedModelId = null;
        });

        await context.read<ExcavatorMasterProvider>().loadByManufacturer(value);
      },
    );
  }

  // ============================================================
  // MODEL
  // ============================================================

  Widget _buildModelDropdown() {
    final provider = context.watch<ExcavatorMasterProvider>();

    return DropdownButtonFormField<int>(
      initialValue: _selectedModelId,
      decoration: _inputDecoration(
        label: 'Excavator Model',
        icon: Icons.construction_outlined,
      ),
      hint: Text(
        _selectedManufacturerId == null
            ? 'Select manufacturer first'
            : 'Select model',
      ),
      items: provider.models.map((model) {
        return DropdownMenuItem<int>(
          value: model.id,
          child: Text(model.modelName),
        );
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Select excavator model';
        }

        return null;
      },
      onChanged: _selectedManufacturerId == null
          ? null
          : (value) {
              setState(() {
                _selectedModelId = value;
              });
            },
    );
  }

  // ============================================================
  // REGISTRATION
  // ============================================================

  Widget _buildRegistrationField() {
    return TextFormField(
      controller: _registrationController,

      textCapitalization: TextCapitalization.characters,

      onChanged: (_) {
        if (_registrationExists) {
          setState(() {
            _registrationExists = false;
          });
        }
      },

      onFieldSubmitted: (_) {
        _checkRegistrationNumber();
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
                    icon: const Icon(Icons.search),
                    onPressed: _checkRegistrationNumber,
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
  // CHECK REGISTRATION
  // ============================================================

  Future<void> _checkRegistrationNumber() async {
    final registration = _registrationController.text.trim().toUpperCase();

    if (registration.isEmpty) {
      return;
    }

    setState(() {
      _registrationChecking = true;
      _registrationExists = false;
    });

    final exists = await context.read<ExcavatorProvider>().registrationExists(
      registration,
      excludeId: widget.excavatorId,
    );

    if (!mounted) return;

    setState(() {
      _registrationChecking = false;
      _registrationExists = exists;
    });

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This registration number already exists.'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
    }
  }

  // ============================================================
  // YEAR
  // ============================================================

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,

      keyboardType: TextInputType.number,

      decoration: _inputDecoration(
        label: 'Manufacturing Year',
        hint: '2024',
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
      onTap: () async {
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

        child: Text(
          value == null ? 'Select date' : _formatDate(value),
          style: TextStyle(
            color: value == null
                ? const Color(0xFF6F7A6E)
                : const Color(0xFF191C1E),
          ),
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

        onChanged: (value) {
          setState(() {
            _status = value;
          });
        },
      ),
    );
  }

  // ============================================================
  // SAVE BUTTONS
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

    final registration = _registrationController.text.trim().toUpperCase();
    final provider = context.read<ExcavatorProvider>();

    // Always check one more time before saving.
    final exists = await provider.registrationExists(
      registration,
      excludeId: widget.excavatorId,
    );

    if (exists) {
      if (!mounted) return;

      setState(() {
        _registrationExists = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration number already exists.'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );

      return;
    }

    if (_selectedManufacturerId == null || _selectedModelId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final now = DateTime.now().toIso8601String();

    final excavator = ExcavatorModel(
      id: widget.excavatorId,

      registrationNumber: registration,

      manufacturerId: _selectedManufacturerId!,

      modelId: _selectedModelId!,

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

    setState(() {
      _saving = false;
    });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Unable to save excavator.'),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
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
  // UNIQUE MANUFACTURERS
  // ============================================================

  List<ExcavatorMasterModel> _getUniqueManufacturers(
    List<ExcavatorMasterModel> models,
  ) {
    final ids = <int>{};

    final result = <ExcavatorMasterModel>[];

    for (final model in models) {
      if (ids.add(model.manufacturerId)) {
        result.add(model);
      }
    }

    return result;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String? _formatDatabaseDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '${value.year}-$month-$day';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
