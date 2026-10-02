import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/diesel_models.dart';
import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselFillingScreen extends StatefulWidget {
  const DieselFillingScreen({super.key});

  @override
  State<DieselFillingScreen> createState() => _DieselFillingScreenState();
}

class _DieselFillingScreenState extends State<DieselFillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _rate = TextEditingController();
  final _meter = TextEditingController();
  final _operator = TextEditingController();
  final _shift = TextEditingController();
  final _remarks = TextEditingController();

  DateTime date = DateTime.now();
  String vehicleType = 'Excavator';
  int? vehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<DieselProvider>();
      await p.loadVehicles();
      if (mounted && p.vehicles.isNotEmpty) {
        setState(() => vehicleId = p.vehicles.first.id);
      }
      await p.loadDashboard();
    });
  }

  @override
  void dispose() {
    for (final c in [_qty, _rate, _meter, _operator, _shift, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  double get totalCost =>
      (double.tryParse(_qty.text.trim()) ?? 0) *
      (double.tryParse(_rate.text.trim()) ?? 0);

  void _rebuild() => setState(() {});

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final p = context.read<DieselProvider>();
    DieselVehicleOption? vehicle;
    for (final item in p.vehicles) {
      if (item.id == vehicleId && item.type == vehicleType) {
        vehicle = item;
        break;
      }
    }
    if (vehicle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a vehicle.')));
      return;
    }

    await p.addFilling(
      fillingDate: dieselDate(date),
      vehicleType: vehicleType,
      vehicleId: vehicle.id,
      vehicleRegistration: vehicle.registrationNumber,
      quantityLitres: double.parse(_qty.text.trim()),
      rate: double.parse(_rate.text.trim()),
      meterReading: double.tryParse(_meter.text.trim()),
      operatorName: _operator.text,
      shift: _shift.text,
      remarks: _remarks.text,
    );

    if (!mounted) return;
    if (p.error == null) {
      _qty.clear();
      _rate.clear();
      _meter.clear();
      _operator.clear();
      _shift.clear();
      _remarks.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diesel filling saved successfully.')),
      );
      await p.loadDashboard();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(p.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DieselProvider>();
    final available = p.summary.currentStock;
    final remaining = available - (double.tryParse(_qty.text) ?? 0);

    return DieselShell(
      selectedIndex: 16,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DieselPageHeader(
              title: 'Diesel Filling',
              subtitle:
                  'Record diesel filled from the diesel lorry into a vehicle.',
            ),
            const SizedBox(height: 24),
            DieselCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DieselSectionTitle(
                      title: 'Filling Details',
                      icon: Icons.local_gas_station_outlined,
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (_, c) {
                        final w = (c.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(width: w, child: _dateField()),
                            SizedBox(
                              width: w,
                              child: _dropdown(
                                label: 'Vehicle Type',
                                value: vehicleType,
                                items: const ['Excavator', 'Transport'],
                                onChanged: (v) {
                                  setState(() {
                                    vehicleType = v!;
                                    final filtered = p.vehicles
                                        .where((x) => x.type == vehicleType)
                                        .toList();
                                    vehicleId = filtered.isEmpty
                                        ? null
                                        : filtered.first.id;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: w, child: _vehicleDropdown(p)),
                            SizedBox(
                              width: w,
                              child: _text(
                                _qty,
                                'Diesel Quantity (Litres)',
                                Icons.water_drop_outlined,
                                decimal: true,
                                onChanged: (_) => _rebuild(),
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: _text(
                                _rate,
                                'Diesel Rate',
                                Icons.currency_rupee_outlined,
                                decimal: true,
                                onChanged: (_) => _rebuild(),
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: _text(
                                _meter,
                                'Meter Reading (Optional)',
                                Icons.speed_outlined,
                                decimal: true,
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: _text(
                                _operator,
                                'Operator (Optional)',
                                Icons.person_outline,
                              ),
                            ),
                            SizedBox(
                              width: w,
                              child: _text(
                                _shift,
                                'Shift (Optional)',
                                Icons.schedule_outlined,
                              ),
                            ),
                            SizedBox(
                              width: c.maxWidth,
                              child: _text(
                                _remarks,
                                'Remarks (Optional)',
                                Icons.notes_outlined,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE1E5E9)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StockPreview(
                              'Available Stock',
                              '${dieselQty(available)} L',
                            ),
                          ),
                          Expanded(
                            child: _StockPreview(
                              'Filling Cost',
                              dieselMoney(totalCost),
                            ),
                          ),
                          Expanded(
                            child: _StockPreview(
                              'Remaining After Fill',
                              '${dieselQty(remaining)} L',
                              warning: remaining < 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: p.isLoading ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Filling'),
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
            const SizedBox(height: 24),
            DieselCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DieselSectionTitle(
                    title: 'Recent Filling History',
                    icon: Icons.history_outlined,
                  ),
                  const SizedBox(height: 16),
                  if (p.fillings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No diesel filling records yet.'),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Vehicle')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Rate')),
                          DataColumn(label: Text('Cost')),
                        ],
                        rows: p.fillings
                            .take(15)
                            .map(
                              (r) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(dieselDisplayDate(r.fillingDate)),
                                  ),
                                  DataCell(Text(r.vehicleRegistration)),
                                  DataCell(Text(r.vehicleType)),
                                  DataCell(
                                    Text('${dieselQty(r.quantityLitres)} L'),
                                  ),
                                  DataCell(Text(dieselMoney(r.rate))),
                                  DataCell(Text(dieselMoney(r.totalCost))),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField() => InkWell(
    onTap: () async {
      final d = await pickDieselDate(context, date);
      if (d != null) setState(() => date = d);
    },
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Date',
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      child: Text(dieselDisplayDate(dieselDate(date))),
    ),
  );

  Widget _vehicleDropdown(DieselProvider p) {
    final options = p.vehicles.where((v) => v.type == vehicleType).toList();
    return DropdownButtonFormField<int>(
      initialValue: options.any((v) => v.id == vehicleId) ? vehicleId : null,
      decoration: const InputDecoration(
        labelText: 'Vehicle',
        prefixIcon: Icon(Icons.directions_car_outlined),
      ),
      items: options
          .map(
            (v) => DropdownMenuItem(
              value: v.id,
              child: Text(v.registrationNumber),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => vehicleId = v),
      validator: (v) => v == null ? 'Select vehicle' : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: items
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: onChanged,
  );

  Widget _text(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool decimal = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    keyboardType: decimal
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    maxLines: maxLines,
    onChanged: onChanged,
    validator:
        label.startsWith('Diesel Quantity') || label.startsWith('Diesel Rate')
        ? (v) =>
              (double.tryParse(v?.trim() ?? '') == null ||
                  double.parse(v!.trim()) <= 0)
              ? 'Enter a valid value'
              : null
        : null,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );
}

class _StockPreview extends StatelessWidget {
  final String title;
  final String value;
  final bool warning;
  const _StockPreview(this.title, this.value, {this.warning = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 12, color: Color(0xFF68717D)),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: warning ? const Color(0xFFBA1A1A) : const Color(0xFF20242A),
        ),
      ),
    ],
  );
}
