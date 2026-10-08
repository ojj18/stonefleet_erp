import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import '../../../data/models/diesel_models.dart';
import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselFillingScreen extends StatefulWidget {
  const DieselFillingScreen({super.key});
  @override
  State<DieselFillingScreen> createState() => _DieselFillingScreenState();
}

class _DieselFillingScreenState extends State<DieselFillingScreen> {
  int page = 0, rowsPerPage = 10;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<DieselProvider>();
      await p.loadVehicles();
      await p.loadDashboard();
      await p.loadFillingHistory();
    });
  }

  void resetPage() => setState(() => page = 0);
  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 21,
      child: Consumer<DieselProvider>(
        builder: (context, p, _) {
          final start = page * rowsPerPage;
          final end = (start + rowsPerPage).clamp(0, p.fillings.length);
          final rows = p.fillings.sublist(start, end);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DieselPageHeader(
                  title: AppLocalization.t('Diesel Filling'),
                  subtitle: AppLocalization.t(
                    'Record diesel filled from the diesel lorry into a vehicle.',
                  ),
                  action: FilledButton.icon(
                    onPressed: p.isLoading ? null : () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalization.t('Add Filling')),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00652C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DieselCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DieselSectionTitle(
                        title: AppLocalization.t('Recent Filling History'),
                        icon: Icons.history_outlined,
                      ),
                      const SizedBox(height: 16),
                      if (rows.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              AppLocalization.t(
                                'No diesel filling records yet.',
                              ),
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Text(AppLocalization.t('Date')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Vehicle')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Type')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Quantity')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Rate')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Cost')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('ACTION')),
                              ),
                            ],
                            rows: rows
                                .map(
                                  (r) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(dieselDisplayDate(r.fillingDate)),
                                      ),
                                      DataCell(Text(r.vehicleRegistration)),
                                      DataCell(
                                        Text(AppLocalization.t(r.vehicleType)),
                                      ),
                                      DataCell(
                                        Text(
                                          '${dieselQty(r.quantityLitres)} L',
                                        ),
                                      ),
                                      DataCell(Text(dieselMoney(r.rate))),
                                      DataCell(Text(dieselMoney(r.totalCost))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: AppLocalization.t(
                                                'View',
                                              ),
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () => _view(r),
                                            ),
                                            IconButton(
                                              tooltip: AppLocalization.t(
                                                'Edit',
                                              ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _openForm(existing: r),
                                            ),
                                            IconButton(
                                              tooltip: AppLocalization.t(
                                                'Delete',
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                              ),
                                              onPressed: () => _delete(r),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      if (p.fillings.isNotEmpty)
                        _Pager(
                          total: p.fillings.length,
                          page: page,
                          rowsPerPage: rowsPerPage,
                          onPage: (v) => setState(() => page = v),
                          onRows: (v) {
                            setState(() {
                              rowsPerPage = v;
                              page = 0;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm({DieselFillingRow? existing}) async {
    final p = context.read<DieselProvider>();
    await showDialog(
      context: context,
      builder: (_) => _FillingDialog(provider: p, existing: existing),
    );
    if (mounted) {
      await p.loadFillingHistory();
      setState(() => page = 0);
    }
  }

  Future<void> _delete(DieselFillingRow r) async {
    final p = context.read<DieselProvider>();
    if (!await _confirm(
      AppLocalization.t('Delete Diesel Filling?'),
      AppLocalization.t(
        'This diesel filling record will be permanently deleted.',
      ),
    )) {
      return;
    }
    await p.deleteFilling(r.id);
    if (mounted && p.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalization.t(p.error!))));
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final v = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    return v ?? false;
  }

  void _view(DieselFillingRow r) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(AppLocalization.t('Diesel Filling Details')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _d('Date', dieselDisplayDate(r.fillingDate)),
          _d('Vehicle', r.vehicleRegistration),
          _d('Type', AppLocalization.t(r.vehicleType)),
          _d('Quantity', '${dieselQty(r.quantityLitres)} L'),
          _d('Rate', dieselMoney(r.rate)),
          _d('Total Cost', dieselMoney(r.totalCost)),
          _d('Meter Reading', r.meterReading?.toString() ?? '-'),
          _d('Operator', r.operatorName ?? '-'),
          _d('Shift', r.shift ?? '-'),
          _d('Remarks', r.remarks ?? '-'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalization.t('Close')),
        ),
      ],
    ),
  );
  Widget _d(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            AppLocalization.t(k),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

class _FillingDialog extends StatefulWidget {
  final DieselProvider provider;
  final DieselFillingRow? existing;
  const _FillingDialog({required this.provider, this.existing});
  @override
  State<_FillingDialog> createState() => _FillingDialogState();
}

class _FillingDialogState extends State<_FillingDialog> {
  final key = GlobalKey<FormState>();
  late DateTime date;
  late String type;
  int? vehicleId;
  late TextEditingController qty, rate, meter, operator, shift, remarks;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    date = e == null
        ? DateTime.now()
        : DateTime.tryParse(e.fillingDate) ?? DateTime.now();
    type = e?.vehicleType ?? 'Excavator';
    vehicleId = e?.vehicleId;
    qty = TextEditingController(
      text: e == null ? '' : e.quantityLitres.toString(),
    );
    rate = TextEditingController(text: e == null ? '' : e.rate.toString());
    meter = TextEditingController(text: e?.meterReading?.toString() ?? '');
    operator = TextEditingController(text: e?.operatorName ?? '');
    shift = TextEditingController(text: e?.shift ?? '');
    remarks = TextEditingController(text: e?.remarks ?? '');
  }

  @override
  void dispose() {
    for (final c in [qty, rate, meter, operator, shift, remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    DieselVehicleOption? v;
    for (final x in widget.provider.vehicles) {
      if (x.type == type && x.id == vehicleId) {
        v = x;
        break;
      }
    }
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.t('Select vehicle'))),
      );
      return;
    }
    try {
      if (widget.existing == null) {
        await widget.provider.addFilling(
          fillingDate: dieselDate(date),
          vehicleType: type,
          vehicleId: v.id,
          vehicleRegistration: v.registrationNumber,
          quantityLitres: double.parse(qty.text),
          rate: double.parse(rate.text),
          meterReading: double.tryParse(meter.text),
          operatorName: operator.text,
          shift: shift.text,
          remarks: remarks.text,
        );
      } else {
        await widget.provider.updateFilling(
          id: widget.existing!.id,
          fillingDate: dieselDate(date),
          vehicleType: type,
          vehicleId: v.id,
          vehicleRegistration: v.registrationNumber,
          quantityLitres: double.parse(qty.text),
          rate: double.parse(rate.text),
          meterReading: double.tryParse(meter.text),
          operatorName: operator.text,
          shift: shift.text,
          remarks: remarks.text,
        );
      }
      if (widget.provider.error != null) throw Exception(widget.provider.error);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.t(e.toString().replaceFirst('Exception: ', '')),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.provider.vehicles
        .where((v) => v.type == type)
        .toList();
    return AlertDialog(
      title: Text(
        AppLocalization.t(
          widget.existing == null ? 'Add Filling' : 'Edit Diesel Filling',
        ),
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: key,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 292,
                  child: InkWell(
                    onTap: () async {
                      final d = await pickDieselDate(context, date);
                      if (d != null) setState(() => date = d);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalization.t('Date'),
                      ),
                      child: Text(dieselDisplayDate(dieselDate(date))),
                    ),
                  ),
                ),
                SizedBox(
                  width: 292,
                  child: DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Vehicle Type'),
                    ),
                    items: const ['Excavator', 'Transport']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        type = v!;
                        vehicleId = null;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 292,
                  child: DropdownButtonFormField<int>(
                    initialValue: options.any((x) => x.id == vehicleId)
                        ? vehicleId
                        : null,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Vehicle'),
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
                    validator: (v) =>
                        v == null ? AppLocalization.t('Select vehicle') : null,
                  ),
                ),
                _field(qty, 'Diesel Quantity (Litres)', true),
                _field(rate, 'Diesel Rate', true),
                _field(meter, 'Meter Reading (Optional)', true),
                _field(operator, 'Operator (Optional)', false),
                _field(shift, 'Shift (Optional)', false),
                SizedBox(
                  width: 600,
                  child: _field(remarks, 'Remarks (Optional)', false, 2),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalization.t('Cancel')),
        ),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.save_outlined),
          label: Text(
            AppLocalization.t(
              widget.existing == null ? 'Save Filling' : 'Update Filling',
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00652C),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    bool num, [
    int lines = 1,
  ]) => SizedBox(
    width: 292,
    child: TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: num
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      validator: (v) {
        if (label.startsWith('Diesel Quantity') || label == 'Diesel Rate') {
          final n = double.tryParse(v?.trim() ?? '');
          if (n == null || n <= 0) {
            return AppLocalization.t('Enter a valid value');
          }
        }
        return null;
      },
      decoration: InputDecoration(labelText: AppLocalization.t(label)),
    ),
  );
}

class _Pager extends StatelessWidget {
  final int total, page, rowsPerPage;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onRows;
  const _Pager({
    required this.total,
    required this.page,
    required this.rowsPerPage,
    required this.onPage,
    required this.onRows,
  });
  @override
  Widget build(BuildContext context) {
    final pages = (total / rowsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Text('${AppLocalization.t('Rows per page')}: '),
          DropdownButton<int>(
            value: rowsPerPage,
            items: const [10, 25, 50, 100]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(),
            onChanged: (v) {
              if (v != null) onRows(v);
            },
          ),
          const Spacer(),
          Text(
            '${AppLocalization.t('Showing')} ${total == 0 ? 0 : page * rowsPerPage + 1}-${(page + 1) * rowsPerPage > total ? total : (page + 1) * rowsPerPage} ${AppLocalization.t('of')} $total',
          ),
          IconButton(
            onPressed: page > 0 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${page + 1} / ${pages == 0 ? 1 : pages}'),
          IconButton(
            onPressed: page < pages - 1 ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
