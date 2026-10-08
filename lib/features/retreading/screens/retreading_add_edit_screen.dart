import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../data/models/transport_vehicle_model.dart';
import '../../service_notification/providers/service_notification_provider.dart';
import '../../transport/master/providers/transport_master_provider.dart';
import '../models/retreading_model.dart';
import '../providers/retreading_provider.dart';

class RetreadingAddEditScreen extends StatefulWidget {
  final RetreadingRecord? record;
  const RetreadingAddEditScreen({super.key, this.record});
  bool get isEdit => record != null;
  @override
  State<RetreadingAddEditScreen> createState() =>
      _RetreadingAddEditScreenState();
}

class _RetreadingAddEditScreenState extends State<RetreadingAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _serial = TextEditingController();
  final _size = TextEditingController();
  final _company = TextEditingController();
  final _remarks = TextEditingController();
  DateTime _sentDate = DateTime.now();
  DateTime? _returnDate;
  TransportModel? _vehicle;
  bool _saving = false;
  bool _returned = false;
  final _cost = TextEditingController(text: '0');
  final _bill = TextEditingController();
  String? _guarantee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TransportProvider>().loadActiveVehicles();
      if (widget.record != null) {
        final r = widget.record!;
        _brand.text = r.tyreBrand;
        _serial.text = r.tyreSerialNumber;
        _size.text = r.tyreSize;
        _company.text = r.retreadingCompany;
        _remarks.text = r.remarks ?? '';
        _sentDate = DateTime.parse(r.sentDate);
        _returned = r.status == 'RETURNED';
        _returnDate = r.returnDate == null
            ? null
            : DateTime.tryParse(r.returnDate!);
        _cost.text = r.retreadingCost.toStringAsFixed(2);
        _bill.text = r.billNumber ?? '';
        _guarantee = r.guarantee;
        if (mounted) {
          _vehicle = await context.read<TransportProvider>().getById(
            r.transportVehicleId,
          );
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _brand.dispose();
    _serial.dispose();
    _size.dispose();
    _company.dispose();
    _remarks.dispose();
    _cost.dispose();
    _bill.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool sent}) async {
    final current = sent ? _sentDate : (_returnDate ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: current,
    );
    if (d == null) return;
    setState(() {
      if (sent) {
        _sentDate = d;
      } else {
        _returnDate = d;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicle == null) return;
    if (_returned && _returnDate == null) {
      _snack(AppLocalization.t('Select return date'));
      return;
    }
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    if (_returned && cost < 0) {
      _snack(AppLocalization.t('Enter a valid retreading cost'));
      return;
    }
    setState(() => _saving = true);
    final p = context.read<RetreadingProvider>();
    bool ok;
    if (widget.isEdit) {
      final old = widget.record!;
      ok = await p.update(
        RetreadingRecord(
          id: old.id,
          transportVehicleId: _vehicle!.id!,
          registrationNumber: _vehicle!.registrationNumber,
          tyreBrand: _brand.text.trim(),
          tyreSerialNumber: _serial.text.trim(),
          tyreSize: _size.text.trim(),
          retreadingCompany: _company.text.trim(),
          sentDate: DateFormat('yyyy-MM-dd').format(_sentDate),
          status: _returned ? 'RETURNED' : 'AT_RETREADING',
          returnDate: _returned
              ? DateFormat('yyyy-MM-dd').format(_returnDate!)
              : null,
          retreadingCost: _returned ? cost : 0,
          billNumber: _returned ? _bill.text.trim() : null,
          guarantee: _returned ? _guarantee : null,
          remarks: _remarks.text.trim(),
          createdAt: old.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
    } else {
      ok = await p.save(
        transportVehicleId: _vehicle!.id!,
        registrationNumber: _vehicle!.registrationNumber,
        tyreBrand: _brand.text,
        tyreSerialNumber: _serial.text,
        tyreSize: _size.text,
        retreadingCompany: _company.text,
        sentDate: DateFormat('yyyy-MM-dd').format(_sentDate),
        remarks: _remarks.text,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _snack(
        AppLocalization.t(
          widget.isEdit
              ? 'Retreading record updated successfully.'
              : 'Tyre sent for retreading successfully.',
        ),
      );
      Navigator.pop(context);
    } else {
      _snack(AppLocalization.t(p.error ?? 'Unable to save retreading record.'));
    }
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 24,
            onMenuTap: (i) => handleMenuTap(i, context: context),
          ),
          Expanded(
            child: Column(
              children: [
                _top(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1050),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalization.t(
                                  widget.isEdit
                                      ? 'Edit Retreading Record'
                                      : 'Send Tyre for Retreading',
                                ),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalization.t(
                                  'Record each tyre by its serial number. A returned tyre keeps the same serial number and gets a new history entry for the next retreading cycle.',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF4E5867),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _card(),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: Text(AppLocalization.t('Cancel')),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton.icon(
                                    onPressed: _saving ? null : _save,
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(
                                      AppLocalization.t(
                                        widget.isEdit
                                            ? 'Update Record'
                                            : 'Save Retreading',
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF00652C),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _top() => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFBECABC))),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(width: 8),
        const Text(
          'StoneFleet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Consumer<ServiceNotificationProvider>(
          builder: (_, p, _) => IconButton(
            tooltip: AppLocalization.t('Service Notifications'),
            onPressed: () => handleMenuTap(7, context: context),
            icon: Badge(
              isLabelVisible: p.alertCount > 0,
              label: Text('${p.alertCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _card() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBECABC)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _vehicleField()),
            const SizedBox(width: 20),
            Expanded(child: _dateField()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _textField(
                _brand,
                AppLocalization.t('Tyre Brand'),
                Icons.tire_repair_outlined,
                requiredField: false,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _textField(
                _size,
                AppLocalization.t('Tyre Size'),
                Icons.straighten_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _textField(
                _serial,
                AppLocalization.t('Tyre Serial Number'),
                Icons.confirmation_number_outlined,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _textField(
                _company,
                AppLocalization.t('Retreading Company'),
                Icons.business_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalization.t('Tyre Returned')),
          subtitle: Text(
            AppLocalization.t(
              'Enable this when the tyre has come back from retreading.',
            ),
          ),
          value: _returned,
          onChanged: _saving ? null : (v) => setState(() => _returned = v),
        ),
        if (_returned) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _returnDateField()),
              const SizedBox(width: 20),
              Expanded(
                child: _textField(
                  _cost,
                  AppLocalization.t('Retreading Cost'),
                  Icons.currency_rupee_outlined,
                  keyboard: TextInputType.number,
                  requiredField: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _textField(
                  _bill,
                  AppLocalization.t('Bill Number'),
                  Icons.receipt_long_outlined,
                  requiredField: false,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _guaranteeField()),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _textField(
          _remarks,
          AppLocalization.t('Remarks'),
          Icons.notes_outlined,
          requiredField: false,
          maxLines: 3,
        ),
      ],
    ),
  );

  Widget _vehicleField() {
    final vehicles = context.read<TransportProvider>().vehicles;
    final selected = _vehicle == null
        ? null
        : vehicles.where((v) => v.id == _vehicle!.id).isEmpty
        ? _vehicle
        : vehicles.firstWhere((v) => v.id == _vehicle!.id);
    return DropdownButtonFormField<TransportModel>(
      initialValue: selected,
      isExpanded: true,
      decoration: _dec(
        AppLocalization.t('Lorry Registration No'),
        Icons.local_shipping_outlined,
      ),
      items: vehicles
          .map(
            (v) =>
                DropdownMenuItem(value: v, child: Text(v.registrationNumber)),
          )
          .toList(),
      onChanged: _saving ? null : (v) => setState(() => _vehicle = v),
      validator: (v) => v == null
          ? AppLocalization.t('Select lorry registration number')
          : null,
    );
  }

  Widget _dateField() => InkWell(
    onTap: _saving ? null : () => _pickDate(sent: true),
    child: InputDecorator(
      decoration: _dec(
        AppLocalization.t('Sent Date'),
        Icons.calendar_today_outlined,
      ),
      child: Text(DateFormat('dd/MM/yyyy').format(_sentDate)),
    ),
  );
  Widget _returnDateField() => InkWell(
    onTap: _saving ? null : () => _pickDate(sent: false),
    child: InputDecorator(
      decoration: _dec(
        AppLocalization.t('Return Date'),
        Icons.event_available_outlined,
      ),
      child: Text(
        _returnDate == null
            ? AppLocalization.t('Select Date')
            : DateFormat('dd/MM/yyyy').format(_returnDate!),
      ),
    ),
  );

  Widget _guaranteeField() => DropdownButtonFormField<String>(
    initialValue: _guarantee,
    decoration: _dec(AppLocalization.t('Guarantee'), Icons.verified_outlined),
    items: [
      DropdownMenuItem(
        value: 'Guarantee',
        child: Text(AppLocalization.t('Guarantee')),
      ),
      DropdownMenuItem(
        value: 'No Guarantee',
        child: Text(AppLocalization.t('No Guarantee')),
      ),
    ],
    onChanged: _saving ? null : (v) => setState(() => _guarantee = v),
  );

  Widget _textField(
    TextEditingController c,
    String label,
    IconData icon, {
    bool requiredField = true,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => TextFormField(
    controller: c,
    keyboardType: keyboard,
    maxLines: maxLines,
    decoration: _dec(label, icon),
    validator: requiredField
        ? (v) => (v == null || v.trim().isEmpty)
              ? '${AppLocalization.t('Enter')} $label'
              : null
        : null,
  );
  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.white,
  );
}
