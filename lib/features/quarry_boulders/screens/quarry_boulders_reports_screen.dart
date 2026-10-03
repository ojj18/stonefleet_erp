import 'dart:typed_data';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../providers/quarry_boulder_provider.dart';
import 'package:provider/provider.dart';

class QuarryBouldersReportsScreen extends StatefulWidget {
  const QuarryBouldersReportsScreen({super.key});
  @override
  State<QuarryBouldersReportsScreen> createState() =>
      _QuarryBouldersReportsScreenState();
}

class _QuarryBouldersReportsScreenState
    extends State<QuarryBouldersReportsScreen> {
  String _period = 'Monthly';
  DateTime? _from;
  DateTime? _to;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final now = DateTime.now();
    DateTime? f, t;
    if (_period == 'Daily') {
      f = DateTime(now.year, now.month, now.day);
      t = f;
    } else if (_period == 'Weekly') {
      final d = now.weekday - 1;
      f = DateTime(now.year, now.month, now.day - d);
      t = now;
    } else if (_period == 'Monthly') {
      f = DateTime(now.year, now.month, 1);
      t = DateTime(now.year, now.month + 1, 0);
    } else if (_period == 'Yearly') {
      f = DateTime(now.year, 1, 1);
      t = DateTime(now.year, 12, 31);
    } else {
      f = _from;
      t = _to;
    }
    await context.read<QuarryBoulderProvider>().loadReports(
      fromDate: f,
      toDate: t,
    );
  }

  Future<void> _pick(bool from) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (from ? _from : _to) ?? DateTime.now(),
    );
    if (d == null) return;
    setState(() {
      if (from) {
        _from = d;
      } else {
        _to = d;
      }
      _period = 'Custom';
    });
    await _load();
  }

  String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  String _periodLabel() => _period == 'Custom' && _from != null && _to != null
      ? '${DateFormat('dd/MM/yyyy').format(_from!)} - ${DateFormat('dd/MM/yyyy').format(_to!)}'
      : AppLocalization.t(_period);
  @override
  Widget build(BuildContext context) => Scaffold(
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
                child: Consumer<QuarryBoulderProvider>(
                  builder: (_, p, _) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1350),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalization.t(
                                            'Quarry Boulders Reports',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppLocalization.t(
                                            'Daily, weekly, monthly and yearly trip/load summaries.',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF4E5867),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _exportExcel,
                                    icon: const Icon(Icons.table_view_outlined),
                                    label: Text(
                                      AppLocalization.t('Export Excel'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: _printPdf,
                                    icon: const Icon(Icons.print_outlined),
                                    label: Text(AppLocalization.t('Print')),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _filters(),
                              const SizedBox(height: 24),
                              _summary(p),
                              const SizedBox(height: 24),
                              _summaryTable(
                                AppLocalization.t('Driver-wise Summary'),
                                p.driverSummary,
                                'driver_name',
                              ),
                              const SizedBox(height: 20),
                              _summaryTable(
                                AppLocalization.t('Lorry-wise Summary'),
                                p.lorrySummary,
                                'registration_number',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _top() => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    color: Colors.white,
    child: const Row(
      children: [
        Icon(Icons.assessment_outlined),
        SizedBox(width: 10),
        Text(
          'StoneFleet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
  Widget _filters() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBECABC)),
    ),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _period,
            decoration: InputDecoration(
              labelText: AppLocalization.t('Report Type'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom']
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(AppLocalization.t(v)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _period = v);
              if (v != 'Custom') _load();
            },
          ),
        ),
        const SizedBox(width: 12),
        if (_period == 'Custom') ...[
          _dateBtn(AppLocalization.t('From Date'), _from, () => _pick(true)),
          const SizedBox(width: 12),
          _dateBtn(AppLocalization.t('To Date'), _to, () => _pick(false)),
        ],
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _load,
          child: Text(AppLocalization.t('Generate')),
        ),
      ],
    ),
  );
  Widget _dateBtn(String label, DateTime? d, VoidCallback tap) => SizedBox(
    width: 160,
    height: 56,
    child: OutlinedButton(
      onPressed: tap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(
            d == null
                ? AppLocalization.t('Select Date')
                : DateFormat('dd/MM/yyyy').format(d),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
  Widget _summary(QuarryBoulderProvider p) => Row(
    children: [
      _kpi(
        AppLocalization.t('Total Records'),
        '${p.summary.records}',
        Icons.receipt_long_outlined,
      ),
      const SizedBox(width: 14),
      _kpi(
        AppLocalization.t('Total Trips'),
        '${p.summary.trips}',
        Icons.local_shipping_outlined,
      ),
      const SizedBox(width: 14),
      _kpi(
        AppLocalization.t('Total Load'),
        _n(p.summary.load),
        Icons.scale_outlined,
      ),
      const SizedBox(width: 14),
      _kpi(
        AppLocalization.t('Drivers'),
        '${p.summary.drivers}',
        Icons.person_outline,
      ),
    ],
  );
  Widget _kpi(String t, String v, IconData i) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: Row(
        children: [
          Icon(i, color: const Color(0xFF00652C)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF68717D),
                  ),
                ),
                Text(
                  v,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _summaryTable(
    String title,
    List<Map<String, dynamic>> rows,
    String key,
  ) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBECABC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Text(AppLocalization.t('No report data available.')),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
              columns: [
                DataColumn(
                  label: Text(
                    key == 'driver_name'
                        ? AppLocalization.t('Driver Name')
                        : AppLocalization.t('Lorry Registration No'),
                  ),
                ),
                DataColumn(label: Text(AppLocalization.t('Records'))),
                DataColumn(label: Text(AppLocalization.t('Trip'))),
                DataColumn(label: Text(AppLocalization.t('Total Load'))),
              ],
              rows: rows
                  .map(
                    (r) => DataRow(
                      cells: [
                        DataCell(Text('${r[key]}')),
                        DataCell(Text('${r['records']}')),
                        DataCell(Text('${r['trips']}')),
                        DataCell(
                          Text(
                            _n((r['total_load'] as num).toDouble()),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );

  Future<void> _exportExcel() async {
    final p = context.read<QuarryBoulderProvider>();
    final excel = Excel.createExcel();
    final sheet = excel['Quarry Boulders'];
    sheet.appendRow([TextCellValue('Quarry Boulders Report')]);
    sheet.appendRow([TextCellValue('Period'), TextCellValue(_periodLabel())]);
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Lorry Registration No'),
      TextCellValue('Driver Name'),
      TextCellValue('Unit'),
      TextCellValue('Trip'),
      TextCellValue('Total Load'),
    ]);
    for (final t in p.trips) {
      sheet.appendRow([
        TextCellValue(
          DateFormat('dd/MM/yyyy').format(DateTime.parse(t.tripDate)),
        ),
        TextCellValue(t.registrationNumber),
        TextCellValue(t.driverName),
        DoubleCellValue(t.unit),
        IntCellValue(t.trips),
        DoubleCellValue(t.totalLoad),
      ]);
    }
    final bytes = excel.encode();
    if (bytes == null) return;
    final location = await getSaveLocation(
      suggestedName: 'quarry_boulders_report.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (location == null) return;
    await File(location.path).writeAsBytes(bytes, flush: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('Excel report saved successfully.')),
        ),
      );
    }
  }

  Future<Uint8List> _simplePdf(QuarryBoulderProvider p) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Quarry Boulders Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Period: ${_periodLabel()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Lorry', 'Driver', 'Unit', 'Trips', 'Load'],
            data: p.trips
                .map(
                  (t) => [
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(t.tripDate)),
                    t.registrationNumber,
                    t.driverName,
                    _n(t.unit),
                    '${t.trips}',
                    _n(t.totalLoad),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _printPdf() async {
    final bytes = await _simplePdf(context.read<QuarryBoulderProvider>());
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}
