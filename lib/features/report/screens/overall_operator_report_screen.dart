import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../overall_operator_report_repository.dart';

class OverallOperatorReportScreen extends StatefulWidget {
  const OverallOperatorReportScreen({super.key});
  @override
  State<OverallOperatorReportScreen> createState() =>
      _OverallOperatorReportScreenState();
}

class _OverallOperatorReportScreenState
    extends State<OverallOperatorReportScreen> {
  final _repo = OverallOperatorReportRepository();
  final _money = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  String _period = 'Monthly';
  String? _operator;
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  List<String> _operators = [];
  List<Map<String, dynamic>> _rows = [];
  Map<String, double> _breakdown = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOperatorsAndReport();
  }

  Future<void> _loadOperatorsAndReport() async {
    setState(() => _loading = true);
    try {
      _operators = await _repo.getOperators();
      _rows = await _repo.getSettlement(
        fromDate: _from,
        toDate: _to,
        operatorName: _operator,
      );
      _breakdown = await _repo.getOperationalBreakdown(
        fromDate: _from,
        toDate: _to,
        operatorName: _operator,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setPeriod(String value) {
    final now = DateTime.now();
    setState(() {
      _period = value;
      switch (value) {
        case 'Daily':
          _from = DateTime(now.year, now.month, now.day);
          _to = now;
          break;
        case 'Weekly':
          _from = now.subtract(Duration(days: now.weekday - 1));
          _to = now;
          break;
        case 'Monthly':
          _from = DateTime(now.year, now.month, 1);
          _to = now;
          break;
        case 'Yearly':
          _from = DateTime(now.year, 1, 1);
          _to = now;
          break;
      }
    });
    _loadOperatorsAndReport();
  }

  Future<void> _pickDate(bool start) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      _period = 'Custom';
      if (start) {
        _from = selected;
      } else {
        _to = selected;
      }
    });
    await _loadOperatorsAndReport();
  }

  double _sum(String source) => _rows
      .where((r) => r['source'] == source)
      .fold<double>(0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));
  double get _padi => _sum('Quarry Blasting');
  double get _boulders => _sum('Quarry Boulders');
  double get _driller => _sum('Quarry Driller');
  double get _advance => -_sum('Advance');
  double get _materials => _sum('Blasting Materials');
  double get _diesel => _sum('Diesel Filling');
  double _b(String key) => _breakdown[key] ?? 0;
  String _qty(double value) => NumberFormat('#,##0.##').format(value);


  // As requested: Padi + advance + blasting materials + external-lorry diesel.
  double get _totalExpense => _padi + _advance + _materials + _diesel;
  double get _totalBoulderDriller => _boulders + _driller;
  double get _net => _totalBoulderDriller - _totalExpense;

  Future<void> _exportExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Operator Settlement'];
    excel.delete('Sheet1');
    sheet.appendRow(
      [
        'Date',
        'Operator',
        'Source',
        'Description',
        'Amount',
      ].map((e) => TextCellValue(e)).toList(),
    );
    for (final r in _rows) {
      sheet.appendRow([
        TextCellValue(r['date'].toString()),
        TextCellValue(r['operator'].toString()),
        TextCellValue(r['source'].toString()),
        TextCellValue(r['description'].toString()),
        DoubleCellValue((r['amount'] as num).toDouble()),
      ]);
    }
    void appendSummary(String label, double amount) {
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(label),
        DoubleCellValue(amount),
      ]);
    }
    appendSummary('Bullet Quantity', _b('bulletQuantity'));
    appendSummary('Bullet Price Total', _b('bulletCost'));
    appendSummary('3m Wire Quantity', _b('wire3mQuantity'));
    appendSummary('3m Wire Price Total', _b('wire3mCost'));
    appendSummary('4m Wire Quantity', _b('wire4mQuantity'));
    appendSummary('4m Wire Price Total', _b('wire4mCost'));
    appendSummary('ED Quantity', _b('edQuantity'));
    appendSummary('ED Price Total', _b('edCost'));
    appendSummary('Quarry Driller Total Feet', _b('drillerFeet'));
    appendSummary('Quarry Driller Total Amount', _b('drillerAmount'));
    appendSummary('Boulder Total Units', _b('boulderUnits'));
    appendSummary('Boulder Total Amount', _b('boulderCost'));
    appendSummary('Diesel Consumption Litres', _b('dieselLitres'));
    appendSummary('Diesel Consumption Amount', _b('dieselCost'));
    appendSummary('Total Expense (Padi + Advance + Materials + Diesel)', _totalExpense);
    appendSummary('Total Boulder & Driller', _totalBoulderDriller);
    appendSummary('Total Net Payable', _net);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/overall_operator_settlement_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Excel saved: ${file.path}')));
    }
  }

  Future<pw.Document> _buildPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Overall Operator Settlement Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Period: ${DateFormat('dd/MM/yyyy').format(_from)} - ${DateFormat('dd/MM/yyyy').format(_to)} | Operator: ${_operator ?? 'All Operators'}',
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Operator', 'Source', 'Details', 'Amount'],
            data: _rows
                .map(
                  (r) => [
                    r['date'].toString(),
                    r['operator'].toString(),
                    r['source'].toString(),
                    r['description'].toString(),
                    _money.format(r['amount']),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Bullet: ${_qty(_b('bulletQuantity'))} Qty | ${_money.format(_b('bulletCost'))}'),
          pw.Text('3m Wire: ${_qty(_b('wire3mQuantity'))} Qty | ${_money.format(_b('wire3mCost'))}'),
          pw.Text('4m Wire: ${_qty(_b('wire4mQuantity'))} Qty | ${_money.format(_b('wire4mCost'))}'),
          pw.Text('ED: ${_qty(_b('edQuantity'))} Qty | ${_money.format(_b('edCost'))}'),
          pw.Text('Quarry Driller: ${_qty(_b('drillerFeet'))} Feet | ${_money.format(_b('drillerAmount'))}'),
          pw.Text('Boulders: ${_qty(_b('boulderUnits'))} Units | ${_money.format(_b('boulderCost'))}'),
          pw.Text('Diesel Consumption: ${_qty(_b('dieselLitres'))} L | ${_money.format(_b('dieselCost'))}'),
          pw.SizedBox(height: 8),
          pw.Text('Total Expense (Padi + Advance + Blasting Materials + Diesel Consumption): ${_money.format(_totalExpense)}'),
          pw.Text('Total Boulder & Driller: ${_money.format(_totalBoulderDriller)}'),
          pw.Text(
            'Total Net Payable: ${_money.format(_net)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
    return doc;
  }

  Future<void> _exportPdf({bool print = false}) async {
    final doc = await _buildPdf();
    if (print) {
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } else {
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'overall_operator_settlement.pdf',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalization.t;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 29,
            onMenuTap: (i) => handleMenuTap(i, context: context),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'MRA ERP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(26),
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
                                          tr(
                                            'Overall Operator Settlement Report',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF202820),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          tr(
                                            'Compare earnings, advances and external-lorry diesel deductions.',
                                          ),
                                          style: const TextStyle(
                                            color: Color(0xFF68756D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _panel(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 180,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _period,
                                        decoration: _decoration('Period'),
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
                                                    child: Text(tr(v)),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (v) {
                                          if (v != null) _setPeriod(v);
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 210,
                                      child: DropdownButtonFormField<String?>(
                                        initialValue: _operator,
                                        decoration: _decoration('Operator'),
                                        items: [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text(tr('All Operators')),
                                          ),
                                          ..._operators.map(
                                            (v) => DropdownMenuItem<String?>(
                                              value: v,
                                              child: Text(v),
                                            ),
                                          ),
                                        ],
                                        onChanged: (v) {
                                          setState(() => _operator = v);
                                          _loadOperatorsAndReport();
                                        },
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _pickDate(true),
                                      icon: const Icon(Icons.calendar_month),
                                      label: Text(
                                        '${tr('From')}: ${DateFormat('dd/MM/yyyy').format(_from)}',
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _pickDate(false),
                                      icon: const Icon(Icons.calendar_month),
                                      label: Text(
                                        '${tr('To')}: ${DateFormat('dd/MM/yyyy').format(_to)}',
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _operator = null;
                                          _period = 'Monthly';
                                          final n = DateTime.now();
                                          _from = DateTime(n.year, n.month, 1);
                                          _to = n;
                                        });
                                        _loadOperatorsAndReport();
                                      },
                                      child: Text(tr('Clear')),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _quantityMetric(
                                    tr('Bullet'),
                                    _b('bulletQuantity'),
                                    tr('Qty'),
                                    _b('bulletCost'),
                                    Icons.circle_outlined,
                                  ),
                                  _quantityMetric(
                                    tr('3m Wire'),
                                    _b('wire3mQuantity'),
                                    tr('Qty'),
                                    _b('wire3mCost'),
                                    Icons.electrical_services_outlined,
                                  ),
                                  _quantityMetric(
                                    tr('4m Wire'),
                                    _b('wire4mQuantity'),
                                    tr('Qty'),
                                    _b('wire4mCost'),
                                    Icons.electrical_services_outlined,
                                  ),
                                  _quantityMetric(
                                    tr('ED'),
                                    _b('edQuantity'),
                                    tr('Qty'),
                                    _b('edCost'),
                                    Icons.electrical_services_outlined,
                                  ),
                                  _quantityMetric(
                                    tr('Diesel Consumption'),
                                    _b('dieselLitres'),
                                    'L',
                                    _b('dieselCost'),
                                    Icons.local_gas_station_outlined,
                                  ),
                                  _metric(
                                    tr('Blasting Padi'),
                                    _padi,
                                    Icons.payments_outlined,
                                  ),
                                  _quantityMetric(
                                    tr('Boulders'),
                                    _b('boulderUnits'),
                                    tr('Units'),
                                    _b('boulderCost'),
                                    Icons.local_shipping_outlined,
                                  ),
                                  _quantityMetric(
                                    tr('Quarry Driller'),
                                    _b('drillerFeet'),
                                    tr('Feet'),
                                    _b('drillerAmount'),
                                    Icons.construction_outlined,
                                  ),
                                  _metric(
                                    tr('Blasting Materials Cost'),
                                    _materials,
                                    Icons.inventory_2_outlined,
                                  ),
                                  _metric(
                                    tr('Advance Amount'),
                                    _advance,
                                    Icons.money_off,
                                  ),
                                  _metric(
                                    tr('Total Expense'),
                                    _totalExpense,
                                    Icons.calculate_outlined,
                                  ),
                                  _metric(
                                    tr('Total Boulder & Driller'),
                                    _totalBoulderDriller,
                                    Icons.summarize_outlined,
                                  ),
                                  _metric(
                                    tr('Total Net Payable'),
                                    _net,
                                    Icons.account_balance_wallet_outlined,
                                    strong: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _panel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('Settlement Summary'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _summaryLine(
                                      tr('Quarry Blasting - Padi'),
                                      _padi,
                                    ),
                                    _summaryLine(
                                      tr('Quarry Boulders - Total Value'),
                                      _boulders,
                                    ),
                                    _summaryLine(
                                      tr('Quarry Driller - Total Amount'),
                                      _driller,
                                    ),
                                    _summaryLine(
                                      tr('Blasting Materials Cost'),
                                      _materials,
                                    ),
                                    const Divider(),
                                    _summaryLine(
                                      tr('Total Expense (Padi + Advance + Materials + Diesel)'),
                                      _totalExpense,
                                      bold: true,
                                    ),
                                    _summaryLine(
                                      tr('Total Boulder & Driller'),
                                      _totalBoulderDriller,
                                      bold: true,
                                    ),
                                    const Divider(),
                                    _summaryLine(
                                      tr('Total Net Payable'),
                                      _net,
                                      bold: true,
                                      green: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _exportExcel,
                                    icon: const Icon(
                                      Icons.file_download_outlined,
                                    ),
                                    label: Text(tr('Export Excel')),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => _exportPdf(),
                                    icon: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                    ),
                                    label: Text(tr('Export PDF')),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _exportPdf(print: true),
                                    icon: const Icon(Icons.print_outlined),
                                    label: Text(tr('Print')),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _panel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('Transaction Details'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (_rows.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Center(
                                          child: Text(
                                            tr(
                                              'No records for the selected filters',
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns:
                                              [
                                                    tr('Date'),
                                                    tr('Operator'),
                                                    tr('Source'),
                                                    tr('Details'),
                                                    tr('Amount'),
                                                  ]
                                                  .map(
                                                    (v) => DataColumn(
                                                      label: Text(
                                                        v,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          rows: _rows
                                              .map(
                                                (r) => DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        _displayDate(
                                                          r['date'].toString(),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        r['operator']
                                                            .toString(),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        tr(
                                                          r['source']
                                                              .toString(),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        r['description']
                                                            .toString(),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _money.format(
                                                          r['amount'],
                                                        ),
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
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

  String _displayDate(String d) {
    final parsed = DateTime.tryParse(d);
    return parsed == null ? d : DateFormat('dd/MM/yyyy').format(parsed);
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: AppLocalization.t(label),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD7E2D9)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
  Widget _metric(
    String title,
    double value,
    IconData icon, {
    bool strong = false,
  }) => Container(
    width: 205,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: strong ? const Color(0xFF00652C) : const Color(0xFFD7E2D9),
      ),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F3E9),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF00652C)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF68756D)),
              ),
              const SizedBox(height: 5),
              Text(
                _money.format(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: strong
                      ? const Color(0xFF00652C)
                      : const Color(0xFF202820),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _quantityMetric(
    String title,
    double quantity,
    String unit,
    double amount,
    IconData icon,
  ) => Container(
    width: 205,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD7E2D9)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F3E9),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF00652C)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF68756D))),
              const SizedBox(height: 5),
              Text('${_qty(quantity)} $unit', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF202820))),
              const SizedBox(height: 3),
              Text(_money.format(amount), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202820))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _summaryLine(
    String label,
    double value, {
    bool bold = false,
    bool negative = false,
    bool green = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${negative ? '− ' : ''}${_money.format(value)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: green ? const Color(0xFF00652C) : null,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    ),
  );
}
