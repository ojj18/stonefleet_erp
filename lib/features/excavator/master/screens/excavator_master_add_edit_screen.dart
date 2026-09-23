import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_config.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/excavator_model.dart';

import '../../../../data/services/way2api_service.dart';
import '../../../service_notification/providers/service_notification_provider.dart';
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
  // FOCUS
  // ============================================================

  final _registrationFocusNode = FocusNode();

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

  bool _registrationChecked = false;
  bool _rcVerifying = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _registrationFocusNode.addListener(_handleRegistrationFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    final provider = context.read<ExcavatorProvider>();

    try {
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
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Unable to load excavator details: $e');
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
  // REGISTRATION FOCUS
  // ============================================================

  void _handleRegistrationFocusChange() {
    if (!_registrationFocusNode.hasFocus &&
        !widget.isEdit &&
        _registrationController.text.trim().isNotEmpty &&
        !_registrationChecked) {
      _checkRegistration();
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

    _registrationFocusNode.removeListener(_handleRegistrationFocusChange);

    _registrationFocusNode.dispose();

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
            AppConfig.appName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const Spacer(),

          // IconButton(
          //   onPressed: () {},
          //   icon: const Icon(Icons.notifications_outlined),
          // ),
          const SizedBox(width: 8),
          // ======================================================
          // SERVICE NOTIFICATION
          // ======================================================
          Consumer<ServiceNotificationProvider>(
            builder: (context, notificationProvider, _) {
              final alertCount = notificationProvider.alertCount;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Service Notifications',
                    onPressed: () {
                      handleMenuTap(7, context: context);
                    },
                    icon: const Icon(Icons.notifications_outlined, size: 23),
                  ),

                  // Badge
                  if (alertCount > 0)
                    Positioned(
                      right: 5,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD93025),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            alertCount > 99 ? '99+' : '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
          // REGISTRATION
          // ------------------------------------------------------
          _buildRegistrationField(),

          const SizedBox(height: 10),

          _buildVerifyRcButton(),

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

          const SizedBox(height: 20),

          // ------------------------------------------------------
          // YEAR
          // ------------------------------------------------------
          _buildYearField(),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRATION NUMBER
  // ============================================================

  Widget _buildRegistrationField() {
    return TextFormField(
      controller: _registrationController,
      focusNode: _registrationFocusNode,

      enabled: !_saving && !widget.isEdit,

      textCapitalization: TextCapitalization.characters,

      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 -]')),
        UpperCaseTextFormatter(),
      ],

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
                : widget.isEdit
                ? const Icon(Icons.lock_outline, size: 20)
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

      onChanged: (_) {
        if (_registrationExists || _registrationChecked) {
          setState(() {
            _registrationExists = false;
            _registrationChecked = false;
          });
        }
      },

      onFieldSubmitted: (_) {
        _checkRegistration();
      },

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
  // VERIFY RC DETAILS
  // ============================================================

  Widget _buildVerifyRcButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: _saving || _rcVerifying ? null : _verifyRc,
        icon: _rcVerifying
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00652C),
                ),
              )
            : const Icon(Icons.verified_outlined, size: 18),
        label: Text(_rcVerifying ? 'Verifying RC...' : 'Verify RC Details'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00652C),
          side: const BorderSide(color: Color(0xFF00652C)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ),
    );
  }

  Future<void> _verifyRc() async {
    if (_rcVerifying) return;

    final registration = _normalizeRegistration(_registrationController.text);

    if (registration.isEmpty) {
      _showError('Enter registration number first.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _rcVerifying = true;
    });

    try {
      final rc = await Way2ApiService().getVehicleDetails(registration);

      if (!mounted) return;

      setState(() {
        if (rc.manufacturer != null && rc.manufacturer!.trim().isNotEmpty) {
          _manufacturerController.text = rc.manufacturer!.trim();
        }

        if (rc.model != null && rc.model!.trim().isNotEmpty) {
          _modelController.text = rc.model!.trim();
        }

        if (rc.manufacturingDate != null &&
            rc.manufacturingDate!.trim().isNotEmpty) {
          final year = _extractYear(rc.manufacturingDate!);
          if (year != null) {
            _yearController.text = year.toString();
          }
        }

        final insuranceDate = _parseWay2Date(rc.insuranceExpiry);
        if (insuranceDate != null) {
          _insuranceExpiry = insuranceDate;
        }

        final fitnessDate = _parseWay2Date(rc.fitnessExpiry);
        if (fitnessDate != null) {
          _fcExpiry = fitnessDate;
        }

        final permitDate = _parseWay2Date(rc.permitExpiry);
        if (permitDate != null) {
          _permitExpiry = permitDate;
        }

        final taxDate = _parseWay2Date(rc.taxExpiry);
        if (taxDate != null) {
          _taxExpiry = taxDate;
        }

        _registrationController.text = registration;
      });

      _showSuccess('RC verified successfully. Details auto-filled.');
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to verify RC: ${_cleanWay2Error(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _rcVerifying = false;
        });
      }
    }
  }

  int? _extractYear(String value) {
    final match = RegExp(r'(19|20)\d{2}').firstMatch(value);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }

  DateTime? _parseWay2Date(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final text = value.trim();

    final isoDate = DateTime.tryParse(text);
    if (isoDate != null) {
      return isoDate;
    }

    final parts = text.split(RegExp(r'[/-]'));

    if (parts.length == 3) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      final third = int.tryParse(parts[2]);

      if (first != null && second != null && third != null) {
        if (first > 31) {
          return DateTime(first, second, third);
        }

        return DateTime(third, second, first);
      }
    }

    return null;
  }

  String _cleanWay2Error(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
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

    FocusScope.of(context).unfocus();

    setState(() {
      _registrationChecking = true;
      _registrationExists = false;
      _registrationChecked = false;
    });

    try {
      final provider = context.read<ExcavatorProvider>();

      final exists = await provider.registrationExists(
        registration,
        excludeId: widget.excavatorId,
      );

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
  // MANUFACTURER
  // ============================================================

  Widget _buildManufacturerField() {
    return TextFormField(
      controller: _manufacturerController,

      enabled: !_saving,

      textCapitalization: TextCapitalization.words,

      decoration: _inputDecoration(
        label: 'Manufacturer',
        hint: 'Example: Tata Hitachi',
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
        label: 'Excavator Model',
        hint: 'Example: EX 210',
        icon: Icons.construction_outlined,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter excavator model';
        }

        return null;
      },
    );
  }

  // ============================================================
  // MANUFACTURING YEAR
  // ============================================================

  Widget _buildYearField() {
    return TextFormField(
      controller: _yearController,

      enabled: !_saving,

      keyboardType: TextInputType.number,

      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],

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

        final currentYear = DateTime.now().year;

        if (year < 1950 || year > currentYear) {
          return 'Enter a valid year';
        }

        return null;
      },
    );
  }

  // ============================================================
  // COMPLIANCE SECTION
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
                  icon: Icons.shield_outlined,
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
                  icon: Icons.fact_check_outlined,
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
                  icon: Icons.assignment_outlined,
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
                  icon: Icons.receipt_long_outlined,
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
    required IconData icon,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),

      onTap: _saving
          ? null
          : () async {
              final selected = await showDatePicker(
                context: context,

                initialDate: value ?? DateTime.now(),

                firstDate: DateTime(2000),

                lastDate: DateTime(2100),

                helpText: 'Select $label',
              );

              if (selected != null) {
                onChanged(selected);
              }
            },

      child: InputDecorator(
        decoration: _inputDecoration(label: label, icon: icon),

        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'Select date' : _formatDate(value),

                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? const Color(0xFF6F7A6E)
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final registration = _normalizeRegistration(_registrationController.text);

    if (registration.isEmpty) {
      _showError('Enter registration number.');
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
        _registrationChecked = true;
      });

      await _showAlreadyExistsDialog(registration);

      return;
    }

    // ==========================================================
    // START SAVING
    // ==========================================================

    setState(() {
      _saving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final excavator = ExcavatorModel(
        id: widget.excavatorId,

        registrationNumber: registration,

        manufacturerName: _manufacturerController.text.trim(),

        modelName: _modelController.text.trim(),

        manufacturingYear: int.tryParse(_yearController.text.trim()),

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
        success = await provider.updateExcavator(excavator);
      } else {
        success = await provider.addExcavator(excavator);
      }

      if (!mounted) return;

      if (success) {
        _showSuccess(
          widget.isEdit
              ? 'Excavator updated successfully.'
              : 'Excavator added successfully.',
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
  // ORIGINAL CREATED DATE
  // ============================================================

  Future<String> _getOriginalCreatedAt(ExcavatorProvider provider) async {
    if (widget.excavatorId == null) {
      return DateTime.now().toIso8601String();
    }

    final existing = await provider.getById(widget.excavatorId!);

    return existing?.createdAt ?? DateTime.now().toIso8601String();
  }

  // ============================================================
  // ALREADY EXISTS DIALOG
  // ============================================================

  Future<void> _showAlreadyExistsDialog(String registration) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,

      barrierDismissible: false,

      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFBA1A1A),
                size: 28,
              ),

              SizedBox(width: 10),

              Expanded(child: Text('Vehicle Already Exists')),
            ],
          ),

          content: Text(
            'The registration number '
            '$registration is already registered '
            'in StoneFleet.',
          ),

          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
              ),

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

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

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

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),

        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),

        borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 2),
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
  // DATE PARSE
  // ============================================================

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.trim());
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
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: const Color(0xFF00652C),

          behavior: SnackBarBehavior.floating,

          margin: const EdgeInsets.all(20),

          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: const Color(0xFFBA1A1A),

          behavior: SnackBarBehavior.floating,

          margin: const EdgeInsets.all(20),

          duration: const Duration(seconds: 3),
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
