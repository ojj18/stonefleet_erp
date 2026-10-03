import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../data/models/transport_vehicle_model.dart';
import '../../service_notification/providers/service_notification_provider.dart';
import '../../transport/master/providers/transport_master_provider.dart';
import '../models/quarry_boulder_trip_model.dart';
import '../providers/quarry_boulder_provider.dart';

class QuarryBouldersTripAddEditScreen extends StatefulWidget {
  final QuarryBoulderTrip? trip;
  const QuarryBouldersTripAddEditScreen({super.key, this.trip});
  bool get isEdit => trip != null;
  @override
  State<QuarryBouldersTripAddEditScreen> createState() =>
      _QuarryBouldersTripAddEditScreenState();
}

class _QuarryBouldersTripAddEditScreenState
    extends State<QuarryBouldersTripAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _driver = TextEditingController();
  final _trip = TextEditingController();
  DateTime _date = DateTime.now();
  TransportModel? _vehicle;
  String? _selectedRegistration;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TransportProvider>().loadActiveVehicles();
      if (widget.trip != null) {
        final t = widget.trip!;
        _date = DateTime.parse(t.tripDate);
        _driver.text = t.driverName;
        _trip.text = '${t.trips}';
        if (mounted) {
          _vehicle = await context
              .read<TransportProvider>()
              .getByRegistrationNumber(t.registrationNumber);
        }
        _selectedRegistration =
            _vehicle?.registrationNumber ?? t.registrationNumber;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _driver.dispose();
    _trip.dispose();
    super.dispose();
  }

  double get _unit => _vehicle?.unit ?? 0;
  double get _load => (int.tryParse(_trip.text.trim()) ?? 0) * _unit;
  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_vehicle == null || _unit <= 0) {
      _snack(
        AppLocalization.t(
          'Selected lorry does not have a unit configured. Please ask an administrator to configure the unit in Transport Master.',
        ),
      );
      return;
    }
    final count = int.tryParse(_trip.text.trim());
    if (count == null || count <= 0) {
      return;
    }
    setState(() => _saving = true);
    final p = context.read<QuarryBoulderProvider>();
    final ok = widget.isEdit
        ? await p.updateTrip(
            id: widget.trip!.id!,
            tripDate: DateFormat('yyyy-MM-dd').format(_date),
            transportVehicleId: _vehicle!.id!,
            registrationNumber: _vehicle!.registrationNumber,
            driverName: _driver.text,
            unit: _unit,
            tripsCount: count,
          )
        : await p.saveTrip(
            tripDate: DateFormat('yyyy-MM-dd').format(_date),
            transportVehicleId: _vehicle!.id!,
            registrationNumber: _vehicle!.registrationNumber,
            driverName: _driver.text,
            unit: _unit,
            tripsCount: count,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _snack(
        AppLocalization.t(
          widget.isEdit
              ? 'Trip updated successfully.'
              : 'Trip saved successfully.',
        ),
      );
      Navigator.pop(context);
    } else {
      _snack(AppLocalization.t(p.error ?? 'Unable to save trip.'));
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
            selectedIndex: 18,
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
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalization.t(
                                  widget.isEdit
                                      ? 'Edit Quarry Boulders Trip'
                                      : 'Add Quarry Boulders Trip',
                                ),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalization.t(
                                  'Load is calculated automatically as Trip × Unit.',
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
                                            ? 'Update Trip'
                                            : 'Save Trip',
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
          builder: (_, p, _) {
            return IconButton(
              tooltip: AppLocalization.t('Service Notifications'),
              onPressed: () => handleMenuTap(7, context: context),
              icon: Badge(
                isLabelVisible: p.alertCount > 0,
                label: Text('${p.alertCount}'),
                child: const Icon(Icons.notifications_outlined),
              ),
            );
          },
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
            Expanded(child: _dateField()),
            const SizedBox(width: 20),
            Expanded(child: _lorryField()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _driverField()),
            const SizedBox(width: 20),
            Expanded(child: _unitField()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _tripField()),
            const SizedBox(width: 20),
            Expanded(child: _loadField()),
          ],
        ),
      ],
    ),
  );
  Widget _dateField() => InkWell(
    onTap: _saving
        ? null
        : () async {
            final d = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDate: _date,
            );
            if (d != null) setState(() => _date = d);
          },
    child: InputDecorator(
      decoration: _dec(
        AppLocalization.t('Date'),
        Icons.calendar_today_outlined,
      ),
      child: Text(DateFormat('dd/MM/yyyy').format(_date)),
    ),
  );
  Widget _lorryField() {
    final vehicles = context.read<TransportProvider>().vehicles;
    final registrations = vehicles
        .map((v) => v.registrationNumber.trim())
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
    final validSelectedRegistration =
        _selectedRegistration != null &&
            registrations.contains(_selectedRegistration)
        ? _selectedRegistration
        : null;
    return DropdownButtonFormField<String>(
      initialValue: validSelectedRegistration,
      decoration: _dec(
        AppLocalization.t('Lorry Registration No'),
        Icons.local_shipping_outlined,
      ),
      items: registrations
          .map(
            (registration) => DropdownMenuItem<String>(
              value: registration,
              child: Text(registration),
            ),
          )
          .toList(),
      onChanged: _saving
          ? null
          : (registration) {
              TransportModel? selected;
              for (final vehicle in vehicles) {
                if (vehicle.registrationNumber.trim() == registration) {
                  selected = vehicle;
                  break;
                }
              }
              setState(() {
                _selectedRegistration = registration;
                _vehicle = selected;
              });
            },
      validator: (id) => id == null
          ? AppLocalization.t('Select lorry registration number')
          : null,
    );
  }

  Widget _driverField() => TextFormField(
    controller: _driver,
    enabled: !_saving,
    textCapitalization: TextCapitalization.words,
    decoration: _dec(AppLocalization.t('Driver Name'), Icons.person_outline),
    validator: (v) => v == null || v.trim().isEmpty
        ? AppLocalization.t('Enter driver name')
        : null,
  );
  Widget _unitField() => InputDecorator(
    decoration: _dec(AppLocalization.t('Unit'), Icons.scale_outlined),
    child: Text(
      _vehicle == null
          ? '—'
          : (_unit <= 0 ? AppLocalization.t('Not configured') : _num(_unit)),
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: _unit <= 0 ? const Color(0xFFBA1A1A) : null,
      ),
    ),
  );
  Widget _tripField() => TextFormField(
    controller: _trip,
    enabled: !_saving,
    keyboardType: TextInputType.number,
    onChanged: (_) => setState(() {}),
    decoration: _dec(AppLocalization.t('Trip'), Icons.repeat),
    validator: (v) {
      final n = int.tryParse((v ?? '').trim());
      return n == null || n <= 0
          ? AppLocalization.t('Enter valid trip count')
          : null;
    },
  );
  Widget _loadField() => InputDecorator(
    decoration: _dec(AppLocalization.t('Total Load'), Icons.scale_outlined),
    child: Text(
      _vehicle == null ? '—' : _num(_load),
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF00652C),
      ),
    ),
  );
  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
