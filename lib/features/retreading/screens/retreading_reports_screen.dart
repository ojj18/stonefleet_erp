import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../models/retreading_model.dart';
import '../providers/retreading_provider.dart';

class RetreadingReportsScreen extends StatefulWidget {
  const RetreadingReportsScreen({super.key});
  @override
  State<RetreadingReportsScreen> createState() =>
      _RetreadingReportsScreenState();
}

class _RetreadingReportsScreenState extends State<RetreadingReportsScreen> {
  String _period = 'Monthly';
  DateTime? _from;
  DateTime? _to;
  List<RetreadingRecord> _records = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final now = DateTime.now();
    DateTime? from, to;
    if (_period == 'Daily') {
      from = DateTime(now.year, now.month, now.day);
      to = from;
    } else if (_period == 'Weekly') {
      from = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      to = now;
    } else if (_period == 'Monthly') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month + 1, 0);
    } else if (_period == 'Yearly') {
      from = DateTime(now.year, 1, 1);
      to = DateTime(now.year, 12, 31);
    } else {
      from = _from;
      to = _to;
    }
    await context.read<RetreadingProvider>().load(fromDate: from, toDate: to);
    if (mounted) {
      setState(
        () => _records = List.of(context.read<RetreadingProvider>().records),
      );
    }
  }

  Future<void> _pick(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _from = d;
      } else {
        _to = d;
      }
      _period = 'Custom';
    });
    await _load();
  }

  String _date(String? v) => v == null || v.isEmpty
      ? '-'
      : DateFormat('dd/MM/yyyy').format(DateTime.parse(v));
  String _money(double v) => '₹${v.toStringAsFixed(2)}';

  List<CellValue> _excelRow(List<Object?> values) => values.map((value) {
    if (value == null) return TextCellValue('');
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value.toString());
  }).toList();

  Future<void> _exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Retreading Report'];
    sheet.appendRow(_excelRow(['Retreading Report']));
    sheet.appendRow(_excelRow(['Period', _periodLabel()]));
    sheet.appendRow(_excelRow([]));
    sheet.appendRow(
      _excelRow([
        'Sent Date',
        'Lorry Registration',
        'Tyre Brand',
        'Tyre Serial Number',
        'Tyre Size',
        'Retreading Company',
        'Return Date',
        'Status',
        'Retreading Cost',
        'Bill Number',
        'Guarantee',
        'Remarks',
      ]),
    );
    for (final r in _records) {
      sheet.appendRow(
        _excelRow([
          _date(r.sentDate),
          r.registrationNumber,
          r.tyreBrand,
          r.tyreSerialNumber,
          r.tyreSize,
          r.retreadingCompany,
          _date(r.returnDate),
          r.status == 'RETURNED' ? 'Returned' : 'At Retreading',
          r.retreadingCost,
          r.billNumber ?? '',
          r.guarantee ?? '',
          r.remarks ?? '',
        ]),
      );
    }
    final bytes = excel.encode();
    if (bytes == null) return;
    final location = await getSaveLocation(
      suggestedName: 'stonefleet_retreading_report.xlsx',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'Excel', extensions: ['xlsx']),
      ],
    );
    if (location == null) return;
    await File(location.path).writeAsBytes(bytes, flush: true);
    if (mounted) _snack(AppLocalization.t('Excel report saved successfully.'));
  }

  Future<void> _printPdf() async {
    final bytes = await _buildPdf();
    await Printing.layoutPdf(
      name: 'StoneFleet Retreading Report',
      onLayout: (_) async => bytes,
    );
  }

  Future<Uint8List> _buildPdf() async {
    final doc = pw.Document();
    final green = PdfColor.fromInt(0xFF00652C);
    final rows = _records
        .map(
          (r) => [
            _date(r.sentDate),
            r.registrationNumber,
            r.tyreSerialNumber,
            r.tyreSize,
            r.retreadingCompany,
            _date(r.returnDate),
            r.status == 'RETURNED' ? 'Returned' : 'At Retreading',
            _money(r.retreadingCost),
          ],
        )
        .toList();
    final total = _records.fold<double>(0, (s, r) => s + r.retreadingCost);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'StoneFleet',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: green,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Tyre Retreading Report',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Period: ${_periodLabel()}'),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (c) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${c.pageNumber}'),
        ),
        build: (_) => [
          pw.Row(
            children: [
              _box('Records', '${_records.length}', green),
              pw.SizedBox(width: 8),
              _box(
                'At Retreading',
                '${_records.where((r) => r.status == 'AT_RETREADING').length}',
                green,
              ),
              pw.SizedBox(width: 8),
              _box(
                'Returned',
                '${_records.where((r) => r.status == 'RETURNED').length}',
                green,
              ),
              pw.SizedBox(width: 8),
              _box('Total Cost', _money(total), green),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Sent Date',
              'Lorry',
              'Serial Number',
              'Size',
              'Company',
              'Return Date',
              'Status',
              'Cost',
            ],
            data: rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: green),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE1E5E9)),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _box(String label, String value, PdfColor green) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      color: PdfColor.fromInt(0xFFE8F5E9),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: green,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
        ],
      ),
    ),
  );

  String _periodLabel() => _period == 'Custom' && _from != null && _to != null
      ? '${DateFormat('dd/MM/yyyy').format(_from!)} - ${DateFormat('dd/MM/yyyy').format(_to!)}'
      : AppLocalization.t(_period);
  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 25,
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
                        constraints: const BoxConstraints(maxWidth: 1450),
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
                                        AppLocalization.t('Retreading Reports'),
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppLocalization.t(
                                          'Review retreading history, returned tyres and total retreading cost.',
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
                            _summary(),
                            const SizedBox(height: 24),
                            _table(),
                          ],
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
    color: Colors.white,
    child: const Row(
      children: [
        Text(
          'StoneFleet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Spacer(),
        Icon(Icons.notifications_outlined),
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
              labelText: AppLocalization.t('Report Period'),
              border: const OutlineInputBorder(),
            ),
            items: ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom']
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(AppLocalization.t(p)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _period = v);
              _load();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _dateButton(AppLocalization.t('From Date'), _from, true),
        ),
        const SizedBox(width: 16),
        Expanded(child: _dateButton(AppLocalization.t('To Date'), _to, false)),
      ],
    ),
  );
  Widget _dateButton(String label, DateTime? value, bool from) => InkWell(
    onTap: () => _pick(from),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value == null
            ? AppLocalization.t('Select Date')
            : DateFormat('dd/MM/yyyy').format(value),
      ),
    ),
  );
  Widget _summary() {
    final total = _records.fold<double>(0, (s, r) => s + r.retreadingCost);
    return Row(
      children: [
        _smallKpi(AppLocalization.t('Records'), '${_records.length}'),
        const SizedBox(width: 12),
        _smallKpi(
          AppLocalization.t('At Retreading'),
          '${_records.where((r) => r.status == 'AT_RETREADING').length}',
        ),
        const SizedBox(width: 12),
        _smallKpi(
          AppLocalization.t('Returned'),
          '${_records.where((r) => r.status == 'RETURNED').length}',
        ),
        const SizedBox(width: 12),
        _smallKpi(AppLocalization.t('Total Retreading Cost'), _money(total)),
      ],
    );
  }

  Widget _smallKpi(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF00652C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF68717D)),
          ),
        ],
      ),
    ),
  );
  Widget _table() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F2)),
          columns: [
            DataColumn(label: Text(AppLocalization.t('Sent Date'))),
            DataColumn(label: Text(AppLocalization.t('Lorry Registration No'))),
            DataColumn(label: Text(AppLocalization.t('Tyre Serial Number'))),
            DataColumn(label: Text(AppLocalization.t('Tyre Size'))),
            DataColumn(label: Text(AppLocalization.t('Retreading Company'))),
            DataColumn(label: Text(AppLocalization.t('Return Date'))),
            DataColumn(label: Text(AppLocalization.t('Status'))),
            DataColumn(label: Text(AppLocalization.t('Retreading Cost'))),
          ],
          rows: _records.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(_date(r.sentDate))),
                DataCell(Text(r.registrationNumber)),
                DataCell(Text(r.tyreSerialNumber)),
                DataCell(Text(r.tyreSize)),
                DataCell(Text(r.retreadingCompany)),
                DataCell(Text(_date(r.returnDate))),
                DataCell(
                  Text(
                    r.status == 'RETURNED'
                        ? AppLocalization.t('Returned')
                        : AppLocalization.t('At Retreading'),
                  ),
                ),
                DataCell(Text(_money(r.retreadingCost))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
