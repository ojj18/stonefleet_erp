import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../../data/models/excavator_model.dart';
import '../../../../data/repositories/driver_repository.dart';
import '../../../../data/repositories/excavator_repository.dart';

FormFieldValidator<T>? _allowEmptyFieldValidator<T>(
  FormFieldValidator<T>? validator,
) {
  if (validator == null) return null;
  return (value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return null;
    }
    return validator(value);
  };
}

class ExcavatorDieselManagementScreen extends StatefulWidget {
  const ExcavatorDieselManagementScreen({super.key});

  @override
  State<ExcavatorDieselManagementScreen> createState() =>
      _ExcavatorDieselManagementScreenState();
}

class _ExcavatorDieselManagementScreenState
    extends State<ExcavatorDieselManagementScreen> {
  final _search = TextEditingController();
  final _driverRepository = DriverRepository();
  final _excavatorRepository = ExcavatorRepository();
  List<Map<String, Object?>> _records = [];
  List<String> _drivers = [];
  List<ExcavatorModel> _excavators = [];
  bool _loading = true;
  String _shift = 'All';
  String _driver = 'All';
  String _vehicle = 'All';
  String _period = 'Monthly';
  DateTime? _from;
  DateTime? _to;
  static const _green = Color(0xFF00652C);
  static const _bg = Color(0xFFF6F8F7);

  @override
  void initState() {
    super.initState();
    _setPeriodDates('Monthly', notify: false);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await Future.wait([
        db.query(
          'excavator_diesel_shifts',
          orderBy: 'shift_date DESC, id DESC',
        ),
        _driverRepository.getDrivers(),
        _excavatorRepository.getActive(),
      ]);
      if (!mounted) return;
      setState(() {
        _records = (results[0] as List<Map<String, Object?>>);
        _drivers = results[1] as List<String>;
        _excavators = results[2] as List<ExcavatorModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalization.t('Unable to load data')}: $e'),
        ),
      );
    }
  }

  List<Map<String, Object?>> get _filtered => _records.where((r) {
    final q = _search.text.trim().toLowerCase();
    final date = DateTime.tryParse('${r['shift_date'] ?? ''}');
    final matchesQuery =
        q.isEmpty ||
        [
          'excavator_number',
          'driver_name',
          'shift',
          'remarks',
        ].any((k) => '${r[k] ?? ''}'.toLowerCase().contains(q));
    final matchesShift = _shift == 'All' || r['shift'] == _shift;
    final matchesDriver = _driver == 'All' || r['driver_name'] == _driver;
    final matchesVehicle =
        _vehicle == 'All' || r['excavator_number'] == _vehicle;
    final matchesFrom =
        _from == null ||
        (date != null &&
            !date.isBefore(DateTime(_from!.year, _from!.month, _from!.day)));
    final matchesTo =
        _to == null ||
        (date != null &&
            !date.isAfter(DateTime(_to!.year, _to!.month, _to!.day)));
    return matchesQuery &&
        matchesShift &&
        matchesDriver &&
        matchesVehicle &&
        matchesFrom &&
        matchesTo;
  }).toList();

  double _sum(String key) => _filtered.fold<double>(
    0,
    (v, r) => v + ((r[key] as num?)?.toDouble() ?? 0),
  );

  String _fmtDate(Object? value) {
    final d = DateTime.tryParse('$value');
    return d == null ? '-' : DateFormat('dd/MM/yyyy').format(d);
  }

  String _num(Object? v, [int decimals = 2]) =>
      ((v as num?)?.toDouble() ?? 0).toStringAsFixed(decimals);

  void _setPeriodDates(String value, {bool notify = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end = today;
    switch (value) {
      case 'Daily':
        start = today;
        break;
      case 'Weekly':
        start = today.subtract(Duration(days: today.weekday - 1));
        break;
      case 'Yearly':
        start = DateTime(today.year, 1, 1);
        break;
      case 'Custom':
        start = _from ?? today;
        end = _to ?? today;
        break;
      case 'Monthly':
      default:
        start = DateTime(today.year, today.month, 1);
    }
    if (notify && mounted) {
      setState(() {
        _period = value;
        _from = start;
        _to = end;
      });
    } else {
      _period = value;
      _from = start;
      _to = end;
    }
  }

  Future<void> _chooseCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _from ?? now, end: _to ?? now),
    );
    if (range != null && mounted) {
      setState(() {
        _period = 'Custom';
        _from = range.start;
        _to = range.end;
      });
    }
  }

  Future<void> _addEntry({Map<String, Object?>? existing}) async {
    final formKey = GlobalKey<FormState>();
    final start = TextEditingController(
      text: existing == null ? '' : _num(existing['starting_meter']),
    );
    final end = TextEditingController(
      text: existing == null ? '' : _num(existing['closing_meter']),
    );
    final diesel = TextEditingController(
      text: existing == null ? '' : _num(existing['diesel_litres']),
    );
    final remarks = TextEditingController(
      text: '${existing?['remarks'] ?? ''}',
    );
    DateTime date =
        DateTime.tryParse('${existing?['shift_date'] ?? ''}') ?? DateTime.now();
    String shift = '${existing?['shift'] ?? 'Day'}';
    String? selectedVehicle = existing?['excavator_number']?.toString();
    String? selectedDriver = existing?['driver_name']?.toString();
    bool saving = false;
    double number(String s) => double.tryParse(s.trim()) ?? 0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final hours = (number(end.text) - number(start.text))
              .clamp(0, double.infinity)
              .toDouble();
          final lph = hours > 0 ? number(diesel.text) / hours : 0.0;
          InputDecoration decoration(String label, IconData icon) =>
              InputDecoration(
                labelText: AppLocalization.t(label),
                prefixIcon: Icon(icon, size: 19),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFD7E0DA)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              );
          Widget numberField(
            TextEditingController controller,
            String label,
            IconData icon, {
            required FormFieldValidator<String>? validator,
          }) => TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: decoration(label, icon),
            validator: _allowEmptyFieldValidator(validator),
            onChanged: (_) => setDialogState(() {}),
          );
          return AlertDialog(
            title: Text(
              AppLocalization.t(
                existing == null
                    ? 'Add Excavator Diesel Entry'
                    : 'Edit Excavator Diesel Entry',
              ),
            ),
            content: SizedBox(
              width: 680,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setDialogState(() => date = picked);
                                }
                              },
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                '${AppLocalization.t('Date')}: ${DateFormat('dd/MM/yyyy').format(date)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: shift,
                              decoration: decoration('Shift', Icons.schedule),
                              items: ['Day', 'Night']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(AppLocalization.t(s)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setDialogState(() => shift = v ?? 'Day'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedVehicle,
                              isExpanded: true,
                              decoration: decoration(
                                'Excavator Registration',
                                Icons.agriculture,
                              ),
                              items: _excavators
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.registrationNumber,
                                      child: Text(
                                        e.registrationNumber,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              validator: _allowEmptyFieldValidator(
                                ((v) => v == null || v.isEmpty
                                    ? AppLocalization.t('Required')
                                    : null),
                              ),
                              onChanged: (v) =>
                                  setDialogState(() => selectedVehicle = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedDriver,
                              isExpanded: true,
                              decoration: decoration(
                                'Driver Name',
                                Icons.person_outline,
                              ),
                              items: _drivers
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              validator: _allowEmptyFieldValidator(
                                ((v) => v == null || v.isEmpty
                                    ? AppLocalization.t('Required')
                                    : null),
                              ),
                              onChanged: (v) =>
                                  setDialogState(() => selectedDriver = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: numberField(
                              start,
                              'Starting Meter',
                              Icons.play_arrow,
                              validator: _allowEmptyFieldValidator(
                                ((v) =>
                                    v == null ||
                                        v.trim().isEmpty ||
                                        number(v) < 0
                                    ? AppLocalization.t('Enter a valid reading')
                                    : null),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: numberField(
                              end,
                              'Closing Meter',
                              Icons.stop,
                              validator: _allowEmptyFieldValidator(
                                ((v) =>
                                    v == null ||
                                        v.trim().isEmpty ||
                                        number(v) < number(start.text)
                                    ? AppLocalization.t(
                                        'Closing meter must be >= starting meter',
                                      )
                                    : null),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      numberField(
                        diesel,
                        'Diesel Used (L)',
                        Icons.local_gas_station,
                        validator: _allowEmptyFieldValidator(
                          ((v) => v == null || v.trim().isEmpty || number(v) < 0
                              ? AppLocalization.t('Enter a valid quantity')
                              : null),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Wrap(
                          spacing: 28,
                          runSpacing: 8,
                          children: [
                            Text(
                              '${AppLocalization.t('Meter Difference')}: ${hours.toStringAsFixed(2)} h',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _green,
                              ),
                            ),
                            Text(
                              '${AppLocalization.t('Diesel Consumption (L/H)')}: ${lph.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: remarks,
                        decoration: decoration('Remarks', Icons.notes),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: Text(AppLocalization.t('Cancel')),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: saving
                    ? null
                    : () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          final db = await DatabaseHelper.instance.database;
                          final values = <String, Object?>{
                            'shift_date': DateFormat('yyyy-MM-dd').format(date),
                            'excavator_number': selectedVehicle,
                            'driver_name': selectedDriver,
                            'shift': shift,
                            'starting_meter': number(start.text),
                            'closing_meter': number(end.text),
                            'meter_difference':
                                number(end.text) - number(start.text),
                            'diesel_litres': number(diesel.text),
                            'diesel_lph': lph,
                            'loads': 0,
                            'units': 0,
                            'remarks': remarks.text.trim(),
                          };
                          if (existing == null) {
                            values['created_at'] = DateTime.now()
                                .toIso8601String();
                            await db.insert('excavator_diesel_shifts', values);
                          } else {
                            await db.update(
                              'excavator_diesel_shifts',
                              values,
                              where: 'id = ?',
                              whereArgs: [existing['id']],
                            );
                          }
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          await _load();
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppLocalization.t('Save failed')}: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  AppLocalization.t(
                    existing == null ? 'Save Entry' : 'Update Entry',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    // Let the dialog route finish removing its EditableText dependents before
    // disposing controllers. Disposing immediately after showDialog returns can
    // race with the route's final widget teardown on some Flutter versions.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final c in [start, end, diesel, remarks]) {
      c.dispose();
    }
  }

  void _viewEntry(Map<String, Object?> row) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalization.t('Diesel Shift Details')),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailLine('Date', _fmtDate(row['shift_date'])),
              _detailLine('Excavator', '${row['excavator_number'] ?? '-'}'),
              _detailLine('Driver', '${row['driver_name'] ?? '-'}'),
              _detailLine('Shift', '${row['shift'] ?? '-'}'),
              _detailLine('Starting Meter', _num(row['starting_meter'])),
              _detailLine('Closing Meter', _num(row['closing_meter'])),
              _detailLine('Meter Hours', _num(row['meter_difference'])),
              _detailLine('Diesel Used (L)', _num(row['diesel_litres'])),
              _detailLine('Diesel Consumption (L/H)', _num(row['diesel_lph'])),
              _detailLine('Remarks', '${row['remarks'] ?? '-'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalization.t('Close')),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 175,
          child: Text(
            AppLocalization.t(label),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Future<void> _delete(Map<String, Object?> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(AppLocalization.t('Delete entry?')),
        content: Text(
          AppLocalization.t('This diesel shift record will be deleted.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    if (yes == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'excavator_diesel_shifts',
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      await _load();
    }
  }

  List<List<String>> _exportRows() => [
    [
      'Date',
      'Excavator',
      'Driver',
      'Shift',
      'Starting Meter',
      'Closing Meter',
      'Meter Hours',
      'Diesel Used (L)',
      'Diesel Consumption (L/H)',
      'Remarks',
    ],
    ..._filtered.map(
      (r) => [
        _fmtDate(r['shift_date']),
        '${r['excavator_number'] ?? ''}',
        '${r['driver_name'] ?? ''}',
        '${r['shift'] ?? ''}',
        _num(r['starting_meter']),
        _num(r['closing_meter']),
        _num(r['meter_difference']),
        _num(r['diesel_litres']),
        _num(r['diesel_lph']),
        '${r['remarks'] ?? ''}',
      ],
    ),
  ];

  Future<void> _exportExcel() async {
    if (_filtered.isEmpty) {
      _message('No records available for export.');
      return;
    }
    try {
      final book = Excel.createExcel();
      final sheet = book['Diesel Report'];
      for (final row in _exportRows()) {
        sheet.appendRow(row.map((v) => TextCellValue(v)).toList());
      }
      final bytes = book.save();
      if (bytes == null) throw Exception('Excel file could not be generated');
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}excavator_diesel_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx',
      );
      await file.writeAsBytes(bytes, flush: true);
      _message('${AppLocalization.t('Excel report saved: ')}${file.path}');
    } catch (e) {
      _message('${AppLocalization.t('Export failed: ')}$e');
    }
  }

  Future<void> _exportPdf({required bool print}) async {
    if (_filtered.isEmpty) {
      _message('No records available for export.');
      return;
    }
    final doc = pw.Document();
    final data = _exportRows();
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Excavator Diesel Management Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Period: ${_from == null ? 'All dates' : _fmtDate(_from!.toIso8601String())} - ${_to == null ? 'All dates' : _fmtDate(_to!.toIso8601String())}',
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: data.first,
            data: data.skip(1).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    final bytes = await doc.save();
    if (print) {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'excavator_diesel_report.pdf',
      );
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    final vehicleOptions =
        _excavators.map((e) => e.registrationNumber).toSet().toList()..sort();
    final driverOptions = _drivers.toSet().toList()..sort();
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 28,
            onMenuTap: (i) => handleMenuTap(i, context: context),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD7E0DA)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'MRA ERP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF46534A),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalization.t(
                                      'Excavator Diesel Management',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D2720),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppLocalization.t(
                                      'Track shift-wise excavator diesel usage and driver performance.',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF657169),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              onPressed: _addEntry,
                              icon: const Icon(Icons.add),
                              label: Text(AppLocalization.t('Add Entry')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = (constraints.maxWidth - 24) / 3;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _summary(
                                  width,
                                  Icons.receipt_long,
                                  AppLocalization.t('Shift Records'),
                                  '${rows.length}',
                                ),
                                _summary(
                                  width,
                                  Icons.local_gas_station,
                                  AppLocalization.t('Diesel Used'),
                                  '${_sum('diesel_litres').toStringAsFixed(2)} L',
                                ),
                                _summary(
                                  width,
                                  Icons.timer_outlined,
                                  AppLocalization.t('Meter Hours'),
                                  _sum('meter_difference').toStringAsFixed(2),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD7E0DA)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 230,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _driver,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: AppLocalization.t('Driver-wise'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: ['All', ...driverOptions]
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(
                                            v == 'All'
                                                ? AppLocalization.t(
                                                    'All Drivers',
                                                  )
                                                : v,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _driver = v ?? 'All'),
                                ),
                              ),
                              SizedBox(
                                width: 210,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _shift,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: AppLocalization.t('Shift-wise'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: ['All', 'Day', 'Night']
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(
                                            v == 'All'
                                                ? AppLocalization.t(
                                                    'All Shifts',
                                                  )
                                                : AppLocalization.t(v),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _shift = v ?? 'All'),
                                ),
                              ),
                              SizedBox(
                                width: 230,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _vehicle,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: AppLocalization.t(
                                      'Vehicle-wise',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items: ['All', ...vehicleOptions]
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(
                                            v == 'All'
                                                ? AppLocalization.t(
                                                    'All Vehicles',
                                                  )
                                                : v,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _vehicle = v ?? 'All'),
                                ),
                              ),
                              SizedBox(
                                width: 170,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _period,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: AppLocalization.t('Period'),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  items:
                                      [
                                            'Daily',
                                            'Weekly',
                                            'Monthly',
                                            'Yearly',
                                            'Custom',
                                          ]
                                          .map(
                                            (v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(AppLocalization.t(v)),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    if (v == 'Custom') {
                                      setState(() => _period = v);
                                      _chooseCustomRange();
                                    } else {
                                      _setPeriodDates(v);
                                    }
                                  },
                                ),
                              ),
                              if (_period == 'Custom')
                                OutlinedButton.icon(
                                  onPressed: _chooseCustomRange,
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    '${_fmtDate(_from?.toIso8601String())} - ${_fmtDate(_to?.toIso8601String())}',
                                  ),
                                ),
                              SizedBox(
                                width: 230,
                                child: TextField(
                                  controller: _search,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: AppLocalization.t(
                                      'Search excavator or driver',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _search.clear();
                                  _setPeriodDates('Monthly');
                                  setState(() {
                                    _driver = 'All';
                                    _shift = 'All';
                                    _vehicle = 'All';
                                  });
                                },
                                child: Text(AppLocalization.t('Clear')),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _exportExcel,
                              icon: const Icon(Icons.file_download_outlined),
                              label: Text(AppLocalization.t('Export Excel')),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _exportPdf(print: false),
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: Text(AppLocalization.t('Export PDF')),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _green,
                              ),
                              onPressed: () => _exportPdf(print: true),
                              icon: const Icon(Icons.print_outlined),
                              label: Text(AppLocalization.t('Print')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD7E0DA)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(40),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : rows.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      AppLocalization.t(
                                        'No diesel shift records yet',
                                      ),
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      const Color(0xFFF0F3F1),
                                    ),
                                    columns:
                                        [
                                              AppLocalization.t('Date'),
                                              AppLocalization.t('Excavator'),
                                              AppLocalization.t('Driver'),
                                              AppLocalization.t('Shift'),
                                              AppLocalization.t('Start'),
                                              AppLocalization.t('End'),
                                              AppLocalization.t('Hours'),
                                              AppLocalization.t('Diesel (L)'),
                                              AppLocalization.t('L/H'),
                                              AppLocalization.t('Remarks'),
                                              AppLocalization.t('Actions'),
                                            ]
                                            .map(
                                              (s) => DataColumn(
                                                label: Text(
                                                  s,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    rows: rows
                                        .map(
                                          (r) => DataRow(
                                            cells: [
                                              DataCell(
                                                Text(_fmtDate(r['shift_date'])),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${r['excavator_number'] ?? '-'}',
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${r['driver_name'] ?? '-'}',
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: r['shift'] == 'Day'
                                                        ? const Color(
                                                            0xFFEAF5ED,
                                                          )
                                                        : const Color(
                                                            0xFFEAF0FA,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${r['shift']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(_num(r['starting_meter'])),
                                              ),
                                              DataCell(
                                                Text(_num(r['closing_meter'])),
                                              ),
                                              DataCell(
                                                Text(
                                                  _num(r['meter_difference']),
                                                ),
                                              ),
                                              DataCell(
                                                Text(_num(r['diesel_litres'])),
                                              ),
                                              DataCell(
                                                Text(_num(r['diesel_lph'])),
                                              ),
                                              DataCell(
                                                Text(
                                                  '${r['remarks'] ?? '-'}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip:
                                                          AppLocalization.t(
                                                            'View',
                                                          ),
                                                      onPressed: () =>
                                                          _viewEntry(r),
                                                      icon: const Icon(
                                                        Icons
                                                            .visibility_outlined,
                                                        color: Color(
                                                          0xFF46534A,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip:
                                                          AppLocalization.t(
                                                            'Edit',
                                                          ),
                                                      onPressed: () =>
                                                          _addEntry(
                                                            existing: r,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.edit_outlined,
                                                        color: _green,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip:
                                                          AppLocalization.t(
                                                            'Delete',
                                                          ),
                                                      onPressed: () =>
                                                          _delete(r),
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Color(
                                                          0xFFB42318,
                                                        ),
                                                      ),
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
                        ),
                      ],
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

  Widget _summary(double width, IconData icon, String title, String value) =>
      SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD7E0DA)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF68756C),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
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
