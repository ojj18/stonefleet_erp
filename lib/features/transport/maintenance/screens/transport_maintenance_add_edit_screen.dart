import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_config.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/ocr/transport_maintenance_ocr_model.dart';
import '../../../../data/models/transport_maintenance_model.dart';
import '../../../../data/models/transport_vehicle_model.dart';
import '../../../../data/services/ocr_service.dart';
import '../../../service_notification/providers/service_notification_provider.dart';
import '../../../transport/master/providers/transport_master_provider.dart';
import '../providers/transport_maintenance_provider.dart';

class TransportMaintenanceAddEditScreen extends StatefulWidget {
  final TransportMaintenanceModel? maintenance;

  const TransportMaintenanceAddEditScreen({super.key, this.maintenance});

  bool get isEdit => maintenance != null;

  @override
  State<TransportMaintenanceAddEditScreen> createState() =>
      _TransportMaintenanceAddEditScreenState();
}

class _TransportMaintenanceAddEditScreenState
    extends State<TransportMaintenanceAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _driverController = TextEditingController();

  final _startingKmController = TextEditingController();
  final _closingKmController = TextEditingController();

  final _numberOfLoadsController = TextEditingController();

  final _loadingSiteController = TextEditingController();
  final _unloadingSiteController = TextEditingController();

  final _dieselFilledController = TextEditingController();
  final _dieselRateController = TextEditingController();

  final _remarksController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  TransportModel? _selectedVehicle;

  double _totalKm = 0;
  double _dieselExpense = 0;
  double _dieselConsumptionPerKm = 0;
  double _dieselCostPerKm = 0;

  bool _initializing = true;
  bool _saving = false;

  TransportMaintenanceOcrModel? _ocrResult;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startingKmController.addListener(_calculateValues);
    _closingKmController.addListener(_calculateValues);
    _dieselFilledController.addListener(_calculateValues);
    _dieselRateController.addListener(_calculateValues);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      final transportProvider = context.read<TransportProvider>();

      if (transportProvider.vehicles.isEmpty) {
        await transportProvider.loadVehicles();
      }

      if (!widget.isEdit) {
        if (mounted) {
          setState(() {
            _initializing = false;
          });
        }

        return;
      }

      final record = widget.maintenance;

      if (record != null) {
        _driverController.text = record.driverName ?? '';

        _startingKmController.text = record.startingKm.toString();

        _closingKmController.text = record.closingKm.toString();

        _numberOfLoadsController.text = record.numberOfLoads.toString();

        _loadingSiteController.text = record.loadingSite ?? '';

        _unloadingSiteController.text = record.unloadingSite ?? '';

        _dieselFilledController.text = record.dieselFilled.toString();

        _dieselRateController.text = record.dieselRate.toString();

        _remarksController.text = record.remarks ?? '';

        _totalKm = record.totalKm;
        _dieselExpense = record.dieselExpense;

        // --------------------------------------------------------
        // Find selected vehicle
        // --------------------------------------------------------

        try {
          _selectedVehicle = transportProvider.vehicles.firstWhere(
            (vehicle) => vehicle.id == record.transportVehicleId,
          );
        } catch (_) {
          _selectedVehicle = null;
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Unable to initialize transport maintenance: $e');
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
    _driverController.dispose();

    _startingKmController.dispose();
    _closingKmController.dispose();

    _numberOfLoadsController.dispose();

    _loadingSiteController.dispose();
    _unloadingSiteController.dispose();

    _dieselFilledController.dispose();
    _dieselRateController.dispose();

    _remarksController.dispose();

    super.dispose();
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  void _calculateValues() {
    final startingKm = double.tryParse(_startingKmController.text.trim()) ?? 0;

    final closingKm = double.tryParse(_closingKmController.text.trim()) ?? 0;

    final dieselFilled =
        double.tryParse(_dieselFilledController.text.trim()) ?? 0;

    final dieselRate = double.tryParse(_dieselRateController.text.trim()) ?? 0;

    double totalKm = closingKm - startingKm;

    if (totalKm < 0) {
      totalKm = 0;
    }

    final dieselExpense = dieselFilled * dieselRate;

    double dieselConsumptionPerKm = 0;
    double dieselCostPerKm = 0;

    if (totalKm > 0 && dieselFilled > 0) {
      dieselConsumptionPerKm = dieselFilled / totalKm;

      dieselCostPerKm = dieselExpense / totalKm;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _totalKm = totalKm;
      _dieselExpense = dieselExpense;
      _dieselConsumptionPerKm = dieselConsumptionPerKm;
      _dieselCostPerKm = dieselCostPerKm;
    });
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

                        _buildDriverSection(),

                        const SizedBox(height: 20),

                        _buildKilometerSection(),

                        const SizedBox(height: 20),

                        _buildTripSection(),

                        const SizedBox(height: 20),

                        _buildDieselSection(),

                        const SizedBox(height: 20),

                        _buildRemarksSection(),

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
                widget.isEdit
                    ? 'Edit Transport Maintenance'
                    : 'Add Transport Maintenance',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF191C1E),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.isEdit
                    ? 'Update transport maintenance record.'
                    : 'Record daily transport vehicle operation and maintenance details.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF4E5867)),
              ),
            ],
          ),
        ),

        ElevatedButton.icon(
          onPressed: _extractSheetData,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Upload Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
            foregroundColor: Colors.white,
            minimumSize: const Size(170, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        const SizedBox(width: 12),
      ],
    );
  }

  // ============================================================
  // DRIVER & VEHICLE
  // ============================================================

  Widget _buildDriverSection() {
    return _sectionCard(
      title: 'Vehicle & Driver',
      icon: Icons.local_shipping_outlined,
      child: Row(
        children: [
          Expanded(child: _buildVehicleDropdown()),

          const SizedBox(width: 20),

          Expanded(
            child: _buildTextField(
              controller: _driverController,
              label: 'Driver Name',
              hint: 'Enter driver name',
              icon: Icons.person_outline,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VEHICLE DROPDOWN
  // ============================================================

  Widget _buildVehicleDropdown() {
    final provider = context.watch<TransportProvider>();

    return DropdownButtonFormField<TransportModel>(
      initialValue: _selectedVehicle,

      decoration: _inputDecoration(
        label: 'Vehicle',
        hint: 'Select vehicle',
        icon: Icons.local_shipping_outlined,
      ),

      items: provider.vehicles.map((vehicle) {
        return DropdownMenuItem<TransportModel>(
          value: vehicle,
          child: Text(
            _vehicleDisplayName(vehicle),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),

      onChanged: _saving
          ? null
          : (value) {
              setState(() {
                _selectedVehicle = value;
              });
            },

      validator: (value) {
        if (value == null || value.id == null) {
          return 'Select vehicle';
        }

        return null;
      },
    );
  }

  String _vehicleDisplayName(TransportModel vehicle) {
    final registration = vehicle.registrationNumber;

    final model = vehicle.modelName;

    if (model != null && model.trim().isNotEmpty) {
      return '$registration • $model';
    }

    return registration;
  }

  // ============================================================
  // KILOMETERS
  // ============================================================

  Widget _buildKilometerSection() {
    return _sectionCard(
      title: 'Kilometer Reading',
      icon: Icons.speed_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _startingKmController,
                  label: 'Starting KM',
                  hint: '12540.0',
                  icon: Icons.play_circle_outline,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildNumberField(
                  controller: _closingKmController,
                  label: 'Closing KM',
                  hint: '12680.0',
                  icon: Icons.stop_circle_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildCalculatedField(
                  label: 'Total KM',
                  value: _formatNumber(_totalKm),
                  icon: Icons.route_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TRIP / LOAD
  // ============================================================

  Widget _buildTripSection() {
    return _sectionCard(
      title: 'Trip & Load Details',
      icon: Icons.alt_route_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _numberOfLoadsController,
                  label: 'Number of Loads',
                  hint: '0',
                  icon: Icons.inventory_2_outlined,
                  decimal: false,
                ),
              ),

              const SizedBox(width: 20),

              const Expanded(child: SizedBox()),

              const Expanded(child: SizedBox()),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _loadingSiteController,
                  label: 'Loading Site',
                  hint: 'Enter loading location',
                  icon: Icons.upload_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildTextField(
                  controller: _unloadingSiteController,
                  label: 'Unloading Site',
                  hint: 'Enter unloading location',
                  icon: Icons.download_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIESEL
  // ============================================================

  Widget _buildDieselSection() {
    return _sectionCard(
      title: 'Diesel & Fuel',
      icon: Icons.local_gas_station_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _dieselFilledController,
                  label: 'Diesel Filled',
                  hint: '0.00',
                  icon: Icons.water_drop_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildNumberField(
                  controller: _dieselRateController,
                  label: 'Diesel Rate',
                  hint: '0.00',
                  icon: Icons.currency_rupee,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildCalculatedField(
                  label: 'Diesel Expense',
                  value: _formatCurrency(_dieselExpense),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildCalculatedField(
                  label: 'Diesel Consumption',
                  value: '${_dieselConsumptionPerKm.toStringAsFixed(2)} L/km',
                  icon: Icons.speed_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _buildCalculatedField(
                  label: 'Diesel Cost',
                  value: '${_formatCurrency(_dieselCostPerKm)}/km',
                  icon: Icons.currency_rupee,
                ),
              ),

              const SizedBox(width: 20),

              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REMARKS
  // ============================================================

  Widget _buildRemarksSection() {
    return _sectionCard(
      title: 'Remarks',
      icon: Icons.notes_outlined,
      child: TextFormField(
        controller: _remarksController,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          label: 'Remarks',
          hint: 'Enter additional notes or observations',
          icon: Icons.notes_outlined,
        ),
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
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          ),
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
          label: Text(
            widget.isEdit ? 'Update Maintenance' : 'Save Maintenance',
          ),
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

    if (_selectedVehicle == null || _selectedVehicle!.id == null) {
      _showError('Please select a vehicle.');
      return;
    }

    final startingKm = double.tryParse(_startingKmController.text.trim()) ?? 0;

    final closingKm = double.tryParse(_closingKmController.text.trim()) ?? 0;

    if (closingKm < startingKm) {
      _showError('Closing KM cannot be less than Starting KM.');
      return;
    }

    final numberOfLoads =
        int.tryParse(_numberOfLoadsController.text.trim()) ?? 0;

    final dieselFilled =
        double.tryParse(_dieselFilledController.text.trim()) ?? 0;

    final dieselRate = double.tryParse(_dieselRateController.text.trim()) ?? 0;

    final totalKm = closingKm - startingKm;

    final dieselExpense = dieselFilled * dieselRate;

    final now = DateTime.now().toIso8601String();

    final model = TransportMaintenanceModel(
      id: widget.maintenance?.id,

      transportVehicleId: _selectedVehicle!.id!,

      driverName: _driverController.text.trim().isEmpty
          ? null
          : _driverController.text.trim(),

      startingKm: startingKm,

      closingKm: closingKm,

      totalKm: totalKm,

      numberOfLoads: numberOfLoads,

      loadingSite: _loadingSiteController.text.trim().isEmpty
          ? null
          : _loadingSiteController.text.trim(),

      unloadingSite: _unloadingSiteController.text.trim().isEmpty
          ? null
          : _unloadingSiteController.text.trim(),

      dieselFilled: dieselFilled,

      dieselRate: dieselRate,

      dieselExpense: dieselExpense,

      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),

      createdAt: widget.maintenance?.createdAt ?? now,

      updatedAt: now,
    );

    setState(() {
      _saving = true;
    });

    final provider = context.read<TransportMaintenanceProvider>();

    bool success;

    if (widget.isEdit) {
      success = await provider.updateMaintenance(model);
    } else {
      success = await provider.addMaintenance(model);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Transport maintenance updated successfully.'
                : 'Transport maintenance added successfully.',
          ),
          backgroundColor: const Color(0xFF00652C),
        ),
      );

      Navigator.pop(context, true);
    } else {
      _showError(provider.error ?? 'Unable to save maintenance record.');
    }
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool decimal = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter $label';
        }

        final parsed = decimal
            ? double.tryParse(value.trim())
            : int.tryParse(value.trim());

        if (parsed == null) {
          return 'Enter a valid value';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CALCULATED FIELD
  // ============================================================

  Widget _buildCalculatedField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(
        label: label,
        icon: icon,
      ).copyWith(filled: true, fillColor: const Color(0xFFF1F7F3)),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF00652C),
        ),
      ),
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

      fillColor: const Color(0xFFF8F9FB),

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
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFBA1A1A),
      ),
    );
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  Future<void> _extractSheetData() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      final imageFile = await openFile(acceptedTypeGroups: [typeGroup]);

      if (imageFile == null || !mounted) {
        return;
      }

      final useImage = await _showUploadedSheetDialog(imageFile);

      if (!useImage || !mounted) {
        return;
      }

      // Show separate extracting popup.
      _showExtractingDialog();

      final ocrService = const OcrService();

      final result = await ocrService.extractTransportMaintenance(imageFile);

      if (!mounted) return;

      // Close extracting popup.
      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        _ocrResult = result;
      });

      await _showOcrResultDialog();
    } catch (e) {
      if (!mounted) return;

      // Close extracting popup if it is open.
      Navigator.of(context, rootNavigator: true).pop();

      _showError('Failed to extract transport maintenance data: $e');
    }
  }

  Future<bool> _showUploadedSheetDialog(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Uploaded Sheet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 600,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 550),
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Use Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
                foregroundColor: Colors.white,
                minimumSize: const Size(170, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showExtractingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text('Extracting Data'),
          content: SizedBox(
            width: 300,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 20),
                Text('Please wait...'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showOcrResultDialog() async {
    final result = _ocrResult;

    if (result == null || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Review Extracted Data',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ocrRow('Registration Number', result.registrationNumber),
                  _ocrRow('Driver Name', result.driverName),
                  _ocrRow('Starting KM', result.startingKm?.toString()),
                  _ocrRow('Closing KM', result.closingKm?.toString()),
                  _ocrRow('Number of Loads', result.numberOfLoads?.toString()),
                  _ocrRow('Loading Site', result.loadingSite),
                  _ocrRow('Unloading Site', result.unloadingSite),
                  _ocrRow('Diesel Filled', result.dieselFilled?.toString()),
                  _ocrRow('Diesel Rate', result.dieselRate?.toString()),
                  _ocrRow('Remarks', result.remarks),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyOcrResultToForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 48),
              ),
              child: const Text('Use These Values'),
            ),
          ],
        );
      },
    );
  }

  Widget _ocrRow(String label, String? value) {
    final displayValue = value == null || value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Text(':  '),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }

  void _applyOcrResultToForm() {
    final result = _ocrResult;

    if (result == null) {
      return;
    }

    // 1. Match vehicle by registration number.
    if (result.registrationNumber != null &&
        result.registrationNumber!.trim().isNotEmpty) {
      final extractedRegistration = _normalizeRegistrationNumber(
        result.registrationNumber!,
      );

      for (final vehicle in context.read<TransportProvider>().vehicles) {
        final dbRegistration = _normalizeRegistrationNumber(
          vehicle.registrationNumber,
        );

        if (dbRegistration == extractedRegistration) {
          _selectedVehicle = vehicle;
          break;
        }
      }
    }

    // 2. Driver
    if (result.driverName != null) {
      _driverController.text = result.driverName!;
    }

    // 3. Starting KM
    if (result.startingKm != null) {
      _startingKmController.text = result.startingKm!.toString();
    }

    // 4. Closing KM
    if (result.closingKm != null) {
      _closingKmController.text = result.closingKm!.toString();
    }

    // 5. Number of Loads
    if (result.numberOfLoads != null) {
      _numberOfLoadsController.text = result.numberOfLoads!.toString();
    }

    // 6. Loading Site
    if (result.loadingSite != null) {
      _loadingSiteController.text = result.loadingSite!;
    }

    // 7. Unloading Site
    if (result.unloadingSite != null) {
      _unloadingSiteController.text = result.unloadingSite!;
    }

    // 8. Diesel Filled
    if (result.dieselFilled != null) {
      _dieselFilledController.text = result.dieselFilled!.toString();
    }

    // 9. Diesel Rate
    if (result.dieselRate != null) {
      _dieselRateController.text = result.dieselRate!.toString();
    }

    // 10. Remarks
    if (result.remarks != null) {
      _remarksController.text = result.remarks!;
    }

    // Calculate:
    // Total KM
    // Diesel Expense
    // Diesel Consumption
    // Diesel Cost
    _calculateValues();

    setState(() {});
  }

  String _normalizeRegistrationNumber(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}
