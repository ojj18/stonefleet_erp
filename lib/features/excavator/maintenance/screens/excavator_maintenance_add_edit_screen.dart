import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/ocr/excavator_maintenance_ocr_model.dart';
import '../../../../data/models/excavator_model.dart';
import '../../../../data/models/excavator_maintenance_model.dart';

import '../../../../data/services/ocr_service.dart';
import '../../../service_notification/providers/service_notification_provider.dart';
import '../../master/providers/excavator_provider.dart';
import '../providers/excavator_maintenance_provider.dart';

class ExcavatorMaintenanceAddEditScreen extends StatefulWidget {
  final ExcavatorMaintenanceModel? maintenance;

  const ExcavatorMaintenanceAddEditScreen({super.key, this.maintenance});

  bool get isEdit => maintenance != null;

  @override
  State<ExcavatorMaintenanceAddEditScreen> createState() =>
      _ExcavatorMaintenanceAddEditScreenState();
}

class _ExcavatorMaintenanceAddEditScreenState
    extends State<ExcavatorMaintenanceAddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  ExcavatorModel? _selectedExcavator;

  // ------------------------------------------------------------
  // CONTROLLERS
  // ------------------------------------------------------------

  final _operatorController = TextEditingController();
  final _startingHourController = TextEditingController();
  final _closingHourController = TextEditingController();
  final _totalWorkingHourController = TextEditingController();

  final _bucketWorkingHourController = TextEditingController();
  final _breakerWorkingHourController = TextEditingController();
  final _totalRunningHourController = TextEditingController();

  final _numberOfLoadsController = TextEditingController();
  final _unitsController = TextEditingController();

  final _dieselFilledController = TextEditingController();
  final _dieselRateController = TextEditingController();
  final _dieselExpenseController = TextEditingController();

  final _remarksController = TextEditingController();

  final _dieselPerHourController = TextEditingController();
  final _dieselCostPerHourController = TextEditingController();

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  String? _selectedShift;

  bool _teethSetChanged = false;

  bool _isSaving = false;

  final List<String> _shifts = const ['Day', 'Night'];
  XFile? _selectedSheet;
  ExcavatorMaintenanceOcrModel? ocrResult;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadExistingData();

    _startingHourController.addListener(_calculateHours);
    _closingHourController.addListener(_calculateHours);

    _bucketWorkingHourController.addListener(_calculateRunningHour);
    _breakerWorkingHourController.addListener(_calculateRunningHour);

    _dieselFilledController.addListener(_calculateDiesel);
    _dieselRateController.addListener(_calculateDiesel);
  }

  // ------------------------------------------------------------
  // LOAD EDIT DATA
  // ------------------------------------------------------------

  void _loadExistingData() {
    final data = widget.maintenance;

    if (data == null) {
      return;
    }

    _operatorController.text = data.operatorName ?? '';

    _selectedShift = data.shift;

    _startingHourController.text = _formatNumber(data.startingHour);

    _closingHourController.text = _formatNumber(data.closingHour);

    _totalWorkingHourController.text = _formatNumber(data.totalWorkingHour);

    _bucketWorkingHourController.text = _formatNumber(data.bucketWorkingHour);

    _breakerWorkingHourController.text = _formatNumber(data.breakerWorkingHour);

    _totalRunningHourController.text = _formatNumber(data.totalRunningHour);

    _numberOfLoadsController.text = data.numberOfLoads.toString();

    _unitsController.text = _formatNumber(data.units);

    _dieselFilledController.text = _formatNumber(data.dieselFilled);

    _dieselRateController.text = _formatNumber(data.dieselRate);

    _dieselExpenseController.text = _formatNumber(data.dieselExpense);

    _teethSetChanged = data.teethSetChanged;

    _remarksController.text = data.remarks ?? '';
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _operatorController.dispose();

    _startingHourController.dispose();
    _closingHourController.dispose();
    _totalWorkingHourController.dispose();

    _bucketWorkingHourController.dispose();
    _breakerWorkingHourController.dispose();
    _totalRunningHourController.dispose();

    _numberOfLoadsController.dispose();
    _unitsController.dispose();

    _dieselFilledController.dispose();
    _dieselRateController.dispose();
    _dieselExpenseController.dispose();

    _remarksController.dispose();

    _dieselPerHourController.dispose();
    _dieselCostPerHourController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // CALCULATE WORKING HOURS
  // ------------------------------------------------------------

  void _calculateHours() {
    final starting = double.tryParse(_startingHourController.text.trim());

    final closing = double.tryParse(_closingHourController.text.trim());

    if (starting == null || closing == null) {
      _totalWorkingHourController.clear();
      return;
    }

    final total = closing - starting;

    if (total < 0) {
      _totalWorkingHourController.text = '0.00';
      return;
    }

    _totalWorkingHourController.text = total.toStringAsFixed(2);
  }

  // ------------------------------------------------------------
  // CALCULATE TOTAL RUNNING HOUR
  // Bucket Working Hour + Breaker Working Hour
  // ------------------------------------------------------------

  void _calculateRunningHour() {
    final bucket =
        double.tryParse(_bucketWorkingHourController.text.trim()) ?? 0;

    final breaker =
        double.tryParse(_breakerWorkingHourController.text.trim()) ?? 0;

    final total = bucket + breaker;

    _totalRunningHourController.text = total.toStringAsFixed(2);
  }

  // ------------------------------------------------------------
  // CALCULATE DIESEL EXPENSE
  // ------------------------------------------------------------

  void _calculateDiesel() {
    final diesel = double.tryParse(_dieselFilledController.text.trim());

    final rate = double.tryParse(_dieselRateController.text.trim());

    final starting = double.tryParse(_startingHourController.text.trim());

    final closing = double.tryParse(_closingHourController.text.trim());

    // Calculate diesel expense
    if (diesel != null && rate != null) {
      final expense = diesel * rate;

      _dieselExpenseController.text = expense.toStringAsFixed(2);
    } else {
      _dieselExpenseController.clear();
    }

    // Calculate total working hours
    if (starting == null || closing == null) {
      _dieselPerHourController.clear();
      _dieselCostPerHourController.clear();
      return;
    }

    final workingHours = closing - starting;

    if (workingHours <= 0 || diesel == null || diesel <= 0) {
      _dieselPerHourController.clear();
      _dieselCostPerHourController.clear();
      return;
    }

    // Diesel consumption per hour
    final dieselPerHour = diesel / workingHours;

    // Diesel cost per hour
    final dieselCostPerHour = (diesel * (rate ?? 0)) / workingHours;

    _dieselPerHourController.text = dieselPerHour.toStringAsFixed(2);

    if (rate != null) {
      _dieselCostPerHourController.text = dieselCostPerHour.toStringAsFixed(2);
    } else {
      _dieselCostPerHourController.clear();
    }
  }
  // ------------------------------------------------------------
  // UPLOAD IMAGE
  // ------------------------------------------------------------

  Future<void> _pickMaintenanceSheet() async {
    const XTypeGroup imageTypeGroup = XTypeGroup(
      label: 'Images',
      extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
    );

    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[imageTypeGroup],
      );

      if (file == null) {
        return;
      }

      setState(() {
        _selectedSheet = file;
      });

      if (!mounted) return;

      await _showSheetPreview();
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  // ------------------------------------------------------------
  // IMAGE PREVIEW
  // ------------------------------------------------------------

  Future<void> _showSheetPreview() async {
    final file = _selectedSheet;

    if (file == null || !mounted) {
      return;
    }

    final imageBytes = await file.readAsBytes();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Uploaded Sheet'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(imageBytes, fit: BoxFit.contain),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _selectedSheet = null;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);

                await _extractSheetData();
              },

              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_outlined),

              label: const Text('Use Image'),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
                foregroundColor: Colors.white,
                minimumSize: const Size(190, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EXTRACT IMAGE DATA
  // ------------------------------------------------------------

  Future<void> _extractSheetData() async {
    if (_selectedSheet == null) {
      return;
    }

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: SizedBox(
            width: 320,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Extracting Data...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Analyzing the uploaded sheet',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      const ocrService = OcrService();

      final result = await ocrService.extractExcavatorMaintenance(
        _selectedSheet!,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      setState(() {
        ocrResult = result;
      });

      await _showOcrResultDialog();

      debugPrint('========== OCR RESULT ==========');
      debugPrint('Registration: ${result.registrationNumber}');
      debugPrint('Operator: ${result.operatorName}');
      debugPrint('Shift: ${result.shift}');
      debugPrint('Starting Hour: ${result.startingHour}');
      debugPrint('Closing Hour: ${result.closingHour}');
      debugPrint('Bucket Working Hour: ${result.bucketWorkingHour}');
      debugPrint('Breaker Working Hour: ${result.breakerWorkingHour}');
      debugPrint('Number of Loads: ${result.numberOfLoads}');
      debugPrint('Number of Units: ${result.numberOfUnits}');
      debugPrint('Diesel Filled: ${result.dieselFilled}');
      debugPrint('Diesel Rate: ${result.dieselRate}');
      debugPrint('Teeth Set Changed: ${result.teethSetChanged}');
      debugPrint('Remarks: ${result.remarks}');
      debugPrint('================================');
    } catch (e) {
      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to extract data: $e')));
    }
  }

  // ------------------------------------------------------------
  // OCR RESULT DATA PREVIEW
  // ------------------------------------------------------------

  Future<void> _showOcrResultDialog() async {
    final result = ocrResult;

    if (result == null || !mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review Extracted Data'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ocrRow('Registration Number', result.registrationNumber),
                  _ocrRow('Operator Name', result.operatorName),
                  _ocrRow('Shift', result.shift),
                  _ocrRow('Starting Hour', result.startingHour?.toString()),
                  _ocrRow('Closing Hour', result.closingHour?.toString()),
                  _ocrRow(
                    'Bucket Working Hour',
                    result.bucketWorkingHour?.toString(),
                  ),
                  _ocrRow(
                    'Breaker Working Hour',
                    result.breakerWorkingHour?.toString(),
                  ),
                  _ocrRow('Number of Loads', result.numberOfLoads?.toString()),
                  _ocrRow('Units', result.numberOfUnits?.toString()),
                  _ocrRow('Diesel Filled', result.dieselFilled?.toString()),
                  _ocrRow('Diesel Rate', result.dieselRate?.toString()),
                  _ocrRow(
                    'Teeth Set Changed',
                    result.teethSetChanged == null
                        ? null
                        : result.teethSetChanged!
                        ? 'Yes'
                        : 'No',
                  ),
                  _ocrRow('Remarks', result.remarks),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyOcrResultToForm();
              },
              child: const Text('Use These Values'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // OCR RESULT DATA WIDGET
  // ------------------------------------------------------------

  Widget _ocrRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(flex: 3, child: Text(value ?? 'Not detected')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // APPLYING THE OCR DATA TO THE CONTROLLER
  // ------------------------------------------------------------

  void _applyOcrResultToForm() {
    final result = ocrResult;

    if (result == null) {
      return;
    }

    if (result.registrationNumber != null &&
        result.registrationNumber!.trim().isNotEmpty) {
      final extractedRegistration = _normalizeRegistrationNumber(
        result.registrationNumber!,
      );

      ExcavatorModel? matchedExcavator;

      for (final excavator in context.read<ExcavatorProvider>().excavators) {
        final dbRegistration = _normalizeRegistrationNumber(
          excavator.registrationNumber,
        );

        if (dbRegistration == extractedRegistration) {
          matchedExcavator = excavator;
          break;
        }
      }

      if (matchedExcavator != null) {
        setState(() {
          _selectedExcavator = matchedExcavator;
        });
      }
    }

    // ------------------------------------------------------------
    // BASIC DETAILS
    // ------------------------------------------------------------

    _operatorController.text = result.operatorName ?? '';

    if (result.shift != null && _shifts.contains(result.shift)) {
      _selectedShift = result.shift;
    }

    // ------------------------------------------------------------
    // WORKING HOURS
    // ------------------------------------------------------------

    if (result.startingHour != null) {
      _startingHourController.text = _formatNumber(result.startingHour!);
    }

    if (result.closingHour != null) {
      _closingHourController.text = _formatNumber(result.closingHour!);
    }

    if (result.bucketWorkingHour != null) {
      _bucketWorkingHourController.text = _formatNumber(
        result.bucketWorkingHour!,
      );
    }

    if (result.breakerWorkingHour != null) {
      _breakerWorkingHourController.text = _formatNumber(
        result.breakerWorkingHour!,
      );
    }

    // ------------------------------------------------------------
    // PRODUCTION
    // ------------------------------------------------------------

    if (result.numberOfLoads != null) {
      _numberOfLoadsController.text = result.numberOfLoads.toString();
    }

    if (result.numberOfUnits != null) {
      _unitsController.text = _formatNumber(result.numberOfUnits!.toDouble());
    }

    // ------------------------------------------------------------
    // DIESEL
    // ------------------------------------------------------------

    if (result.dieselFilled != null) {
      _dieselFilledController.text = _formatNumber(result.dieselFilled!);
    }

    if (result.dieselRate != null) {
      _dieselRateController.text = _formatNumber(result.dieselRate!);
    }

    // ------------------------------------------------------------
    // MAINTENANCE
    // ------------------------------------------------------------

    if (result.teethSetChanged != null) {
      _teethSetChanged = result.teethSetChanged!;
    }

    // ------------------------------------------------------------
    // REMARKS
    // ------------------------------------------------------------

    _remarksController.text = result.remarks ?? '';

    // ------------------------------------------------------------
    // RECALCULATE DERIVED VALUES
    // ------------------------------------------------------------

    _calculateHours();
    _calculateRunningHour();
    _calculateDiesel();

    setState(() {});
  }

  // ------------------------------------------------------------
  // HELPER METHOD TO NORMALIZE THE REGISTER NUMBER
  // ------------------------------------------------------------

  String _normalizeRegistrationNumber(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExcavator == null || _selectedExcavator!.id == null) {
      _showError('Please select an excavator.');
      return;
    }

    final startingHour =
        double.tryParse(_startingHourController.text.trim()) ?? 0;

    final closingHour =
        double.tryParse(_closingHourController.text.trim()) ?? 0;

    if (closingHour < startingHour) {
      _showError('Closing hour cannot be less than starting hour.');
      return;
    }

    final bucketWorkingHour =
        double.tryParse(_bucketWorkingHourController.text.trim()) ?? 0;

    final breakerWorkingHour =
        double.tryParse(_breakerWorkingHourController.text.trim()) ?? 0;

    final totalRunningHour = bucketWorkingHour + breakerWorkingHour;

    final dieselFilled =
        double.tryParse(_dieselFilledController.text.trim()) ?? 0;

    final dieselRate = double.tryParse(_dieselRateController.text.trim()) ?? 0;

    final dieselExpense = dieselFilled * dieselRate;

    final now = DateTime.now().toIso8601String();

    final model = ExcavatorMaintenanceModel(
      id: widget.maintenance?.id,

      excavatorId: _selectedExcavator!.id!,

      operatorName: _operatorController.text.trim().isEmpty
          ? null
          : _operatorController.text.trim(),

      shift: _selectedShift,

      startingHour: startingHour,

      closingHour: closingHour,

      totalWorkingHour: double.tryParse(_totalWorkingHourController.text) ?? 0,

      bucketWorkingHour: bucketWorkingHour,

      breakerWorkingHour: breakerWorkingHour,

      totalRunningHour: totalRunningHour,

      numberOfLoads: int.tryParse(_numberOfLoadsController.text) ?? 0,

      units: double.tryParse(_unitsController.text) ?? 0,

      dieselFilled: dieselFilled,

      dieselRate: dieselRate,

      dieselExpense: dieselExpense,

      teethSetChanged: _teethSetChanged,

      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),

      createdAt: widget.maintenance?.createdAt ?? now,

      updatedAt: widget.maintenance != null ? now : null,
    );

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<ExcavatorMaintenanceProvider>();

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
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Maintenance updated successfully.'
                : 'Maintenance added successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } else {
      _showError(provider.error ?? 'Something went wrong.');
    }
  }

  // ------------------------------------------------------------
  // ERROR
  // ------------------------------------------------------------

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------
  // NUMBER FORMAT
  // ------------------------------------------------------------

  String _formatNumber(double value) {
    return value.toStringAsFixed(2);
  }

  // ------------------------------------------------------------
  // VALIDATION
  // ------------------------------------------------------------

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }

    return null;
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),

      body: Row(
        children: [
          // _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1250),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPageHeader(),

                              const SizedBox(height: 24),

                              _buildExcavatorSection(),

                              const SizedBox(height: 20),

                              _buildOperationSection(),

                              const SizedBox(height: 20),

                              _buildWorkingHourSection(),

                              const SizedBox(height: 20),

                              _buildProductionSection(),

                              const SizedBox(height: 20),

                              _buildDieselSection(),

                              const SizedBox(height: 20),

                              _buildMaintenanceSection(),

                              const SizedBox(height: 28),

                              _buildActionButtons(),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SIDEBAR
  // ------------------------------------------------------------

  // Widget _buildSidebar() {
  //   return Container(
  //     width: 240,
  //     color: const Color(0xFF00652C),
  //     child: Column(
  //       children: [
  //         const SizedBox(height: 28),

  //         const Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 20),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.precision_manufacturing,
  //                 color: Colors.white,
  //                 size: 28,
  //               ),
  //               SizedBox(width: 12),
  //               Text(
  //                 'StoneFleet',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         const SizedBox(height: 35),

  //         _sidebarItem(Icons.dashboard_outlined, 'Dashboard', false),

  //         _sidebarItem(Icons.agriculture_outlined, 'Excavators', true),

  //         _sidebarItem(Icons.local_shipping_outlined, 'Transport', false),

  //         _sidebarItem(Icons.people_outline, 'Customers', false),

  //         _sidebarItem(Icons.receipt_long_outlined, 'Billing', false),

  //         const Spacer(),

  //         _sidebarItem(Icons.settings_outlined, 'Settings', false),

  //         const SizedBox(height: 20),
  //       ],
  //     ),
  //   );
  // }

  // Widget _sidebarItem(IconData icon, String title, bool selected) {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
  //     decoration: BoxDecoration(
  //       color: selected
  //           ? Colors.white.withValues(alpha: 0.15)
  //           : Colors.transparent,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: ListTile(
  //       dense: true,

  //       leading: Icon(icon, color: Colors.white),

  //       title: Text(
  //         title,
  //         style: const TextStyle(color: Colors.white, fontSize: 14),
  //       ),

  //       onTap: () {},
  //     ),
  //   );
  // }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // PAGE HEADER
  // ------------------------------------------------------------

  Widget _buildPageHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit ? 'Edit Maintenance' : 'Add Maintenance',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              widget.isEdit
                  ? 'Update excavator maintenance details'
                  : 'Record daily excavator maintenance details',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        Spacer(),
        ElevatedButton.icon(
          onPressed: _pickMaintenanceSheet,

          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.upload_file_outlined),

          label: Text('Upload Image'),

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
            foregroundColor: Colors.white,
            minimumSize: const Size(190, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // EXCAVATOR SECTION
  // ------------------------------------------------------------

  Widget _buildExcavatorSection() {
    return _sectionCard(
      title: 'Excavator Details',
      icon: Icons.agriculture_outlined,
      child: Consumer<ExcavatorProvider>(
        builder: (context, provider, child) {
          final excavators = provider.excavators;

          // Find existing excavator
          if (_selectedExcavator == null &&
              widget.maintenance != null &&
              widget.maintenance!.excavatorId != 0) {
            for (final excavator in excavators) {
              if (excavator.id == widget.maintenance!.excavatorId) {
                _selectedExcavator = excavator;
                break;
              }
            }
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<ExcavatorModel>(
                  initialValue: _selectedExcavator,

                  isExpanded: true,

                  decoration: _inputDecoration(
                    'Registration Number',
                    Icons.pin_outlined,
                  ),

                  validator: (_) {
                    if (_selectedExcavator == null) {
                      return 'Select excavator';
                    }

                    return null;
                  },

                  items: excavators.where((e) => e.id != null && e.status).map((
                    excavator,
                  ) {
                    return DropdownMenuItem<ExcavatorModel>(
                      value: excavator,

                      child: Text(excavator.registrationNumber),
                    );
                  }).toList(),

                  onChanged: (excavator) {
                    setState(() {
                      _selectedExcavator = excavator;
                    });
                  },
                ),
              ),

              const SizedBox(width: 20),

              Expanded(child: _buildSelectedExcavatorInfo()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedExcavatorInfo() {
    if (_selectedExcavator == null) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          'Select an excavator to view details',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      );
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF00652C),
            size: 20,
          ),

          const SizedBox(width: 10),

          Text(
            _selectedExcavator!.registrationNumber,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          if (_selectedExcavator!.manufacturerName != null) ...[
            const SizedBox(width: 10),

            Text(
              '${_selectedExcavator!.manufacturerName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // OPERATION SECTION
  // ------------------------------------------------------------

  Widget _buildOperationSection() {
    return _sectionCard(
      title: 'Operation Details',
      icon: Icons.person_outline,
      child: Row(
        children: [
          Expanded(
            child: _textField(
              controller: _operatorController,
              label: 'Operator Name',
              icon: Icons.person_outline,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedShift,

              decoration: _inputDecoration('Shift', Icons.schedule_outlined),

              items: _shifts
                  .map(
                    (shift) =>
                        DropdownMenuItem(value: shift, child: Text(shift)),
                  )
                  .toList(),

              onChanged: (value) {
                setState(() {
                  _selectedShift = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // WORKING HOURS
  // ------------------------------------------------------------

  Widget _buildWorkingHourSection() {
    return _sectionCard(
      title: 'Working Hours',
      icon: Icons.access_time_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _startingHourController,
                  label: 'Starting Hour',
                  icon: Icons.play_arrow_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _closingHourController,
                  label: 'Closing Hour',
                  icon: Icons.stop_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _totalWorkingHourController,
                  label: 'Total Working Hour',
                  icon: Icons.timer_outlined,
                  readOnly: true,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _totalRunningHourController,
                  label: 'Total Running Hour',
                  icon: Icons.speed_outlined,
                  readOnly: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _bucketWorkingHourController,
                  label: 'Bucket Working Hour',
                  icon: Icons.construction_outlined,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _breakerWorkingHourController,
                  label: 'Breaker Working Hour',
                  icon: Icons.handyman_outlined,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PRODUCTION
  // ------------------------------------------------------------

  Widget _buildProductionSection() {
    return _sectionCard(
      title: 'Production',
      icon: Icons.inventory_2_outlined,
      child: Row(
        children: [
          Expanded(
            child: _numberField(
              controller: _numberOfLoadsController,
              label: 'Number of Loads',
              icon: Icons.local_shipping_outlined,
              required: false,
            ),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: _numberField(
              controller: _unitsController,
              label: 'Units',
              icon: Icons.straighten_outlined,
              required: false,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DIESEL
  // ------------------------------------------------------------

  Widget _buildDieselSection() {
    return _sectionCard(
      title: 'Diesel & Fuel',
      icon: Icons.local_gas_station_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _dieselFilledController,
                  label: 'Diesel Filled (L)',
                  icon: Icons.local_gas_station_outlined,
                  required: false,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _dieselRateController,
                  label: 'Diesel Rate',
                  icon: Icons.currency_rupee,
                  required: false,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _dieselExpenseController,
                  label: 'Diesel Expense',
                  icon: Icons.payments_outlined,
                  readOnly: true,
                  required: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  controller: _dieselPerHourController,
                  label: 'Diesel Consumption (L/hr)',
                  icon: Icons.speed_outlined,
                  readOnly: true,
                  required: false,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: _numberField(
                  controller: _dieselCostPerHourController,
                  label: 'Diesel Cost (₹/hr)',
                  icon: Icons.currency_rupee,
                  readOnly: true,
                  required: false,
                ),
              ),

              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MAINTENANCE
  // ------------------------------------------------------------

  Widget _buildMaintenanceSection() {
    return _sectionCard(
      title: 'Maintenance',
      icon: Icons.build_outlined,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction_outlined, size: 20),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teeth Set Changed',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mark if the excavator teeth set was changed',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Switch(
                  value: _teethSetChanged,
                  onChanged: (value) {
                    setState(() {
                      _teethSetChanged = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _remarksController,
            maxLines: 4,
            decoration: _inputDecoration('Remarks', Icons.notes_outlined),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTION BUTTONS
  // ------------------------------------------------------------

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          style: OutlinedButton.styleFrom(minimumSize: const Size(120, 48)),
          child: const Text('Cancel'),
        ),

        const SizedBox(width: 14),

        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,

          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),

          label: Text(
            _isSaving
                ? 'Saving...'
                : widget.isEdit
                ? 'Update Maintenance'
                : 'Save Maintenance',
          ),

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
            foregroundColor: Colors.white,
            minimumSize: const Size(190, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION CARD
  // ------------------------------------------------------------

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
                  fontSize: 16,
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

  // ------------------------------------------------------------
  // TEXT FIELD
  // ------------------------------------------------------------

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: _inputDecoration(label, icon),
      validator: required ? _requiredValidator : null,
    );
  }

  // ------------------------------------------------------------
  // NUMBER FIELD
  // ------------------------------------------------------------

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label, icon),
      validator: required ? _numberValidator : null,
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,

      prefixIcon: Icon(icon, size: 20),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00652C), width: 1.5),
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }
}
