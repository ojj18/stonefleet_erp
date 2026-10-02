import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportService {
  static const _green = PdfColor.fromInt(0xFF00652C);
  static const _lightGreen = PdfColor.fromInt(0xFFE8F5E9);
  static const _border = PdfColor.fromInt(0xFFE1E5E9);
  static const _text = PdfColor.fromInt(0xFF20242A);
  static const _muted = PdfColor.fromInt(0xFF68717D);

  Future<Uint8List> buildMaintenanceServiceReport({
    required List<Map<String, dynamic>> records,
    required String reportType,
    required String equipmentType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final document = pw.Document();
    final title = '${_capitalize(reportType)} Report';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _header(
          title: title,
          filter: '${_capitalize(equipmentType)} equipment',
          fromDate: fromDate,
          toDate: toDate,
        ),
        footer: (context) => _footer(context),
        build: (_) => [
          _summary(
            total: records.length,
            label: reportType == 'service'
                ? 'Service Records'
                : 'Maintenance Records',
          ),
          pw.SizedBox(height: 18),
          _maintenanceServiceTable(records, reportType),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildComplianceReport({
    required List<Map<String, dynamic>> records,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _header(title: 'Compliance Report'),
        footer: (context) => _footer(context),
        build: (_) => [
          _complianceSummary(records),
          pw.SizedBox(height: 18),
          _complianceTable(records),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildInventoryReport({
    required List<Map<String, dynamic>> records,
    required String period,
    String? itemName,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final document = pw.Document();

    final purchasedQty = records.fold<double>(
      0,
      (sum, row) => sum + _toDouble(row['purchased_qty']),
    );
    final usedQty = records.fold<double>(
      0,
      (sum, row) => sum + _toDouble(row['used_qty']),
    );
    final remainingQty = records.fold<double>(
      0,
      (sum, row) => sum + _toDouble(row['remaining_qty']),
    );
    final purchaseCost = records.fold<double>(
      0,
      (sum, row) => sum + _toDouble(row['purchase_cost']),
    );

    final filter = [
      'Period: $period',
      if (itemName != null && itemName.trim().isNotEmpty)
        'Spare: ${itemName.trim()}',
    ].join('  |  ');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _header(
          title: 'Inventory Report',
          filter: filter,
          fromDate: fromDate,
          toDate: toDate,
        ),
        footer: (context) => _footer(context),
        build: (_) => [
          _inventorySummary(
            recordCount: records.length,
            purchasedQty: purchasedQty,
            usedQty: usedQty,
            remainingQty: remainingQty,
            purchaseCost: purchaseCost,
          ),
          pw.SizedBox(height: 18),
          _inventoryTable(records),
        ],
      ),
    );

    return document.save();
  }

  Future<Uint8List> buildQuarryBlastingReport({
    required List<Map<String, dynamic>> records,
    required Map<String, dynamic> summary,
    required String period,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final document = pw.Document();

    final bulletQty = _toDouble(summary['bulletQuantity']);
    final wire3mQty = _toDouble(summary['wire3mQuantity']);
    final wire4mQty = _toDouble(summary['wire4mQuantity']);
    final edQty = _toDouble(summary['edQuantity']);
    final bulletCost = _toDouble(summary['bulletCost']);
    final wire3mCost = _toDouble(summary['wire3mCost']);
    final wire4mCost = _toDouble(summary['wire4mCost']);
    final edCost = _toDouble(summary['edCost']);
    final totalCost = _toDouble(summary['totalCost']);
    final purchaseCount =
        (summary['purchaseCount'] as num?)?.toInt() ?? records.length;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => _header(
          title: 'Quarry Blasting Purchase Report',
          filter: 'Period: $period',
          fromDate: fromDate,
          toDate: toDate,
        ),
        footer: (context) => _footer(context),
        build: (_) => [
          _blastingSummary(
            purchaseCount: purchaseCount,
            bulletQty: bulletQty,
            wire3mQty: wire3mQty,
            wire4mQty: wire4mQty,
            edQty: edQty,
            totalCost: totalCost,
          ),
          pw.SizedBox(height: 16),
          _blastingPeriodSummary(
            bulletQty: bulletQty,
            bulletCost: bulletCost,
            wire3mQty: wire3mQty,
            wire3mCost: wire3mCost,
            wire4mQty: wire4mQty,
            wire4mCost: wire4mCost,
            edQty: edQty,
            edCost: edCost,
            totalCost: totalCost,
          ),
          pw.SizedBox(height: 16),
          _blastingTable(records),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _inventorySummary({
    required int recordCount,
    required double purchasedQty,
    required double usedQty,
    required double remainingQty,
    required double purchaseCost,
  }) {
    return pw.Row(
      children: [
        _summaryBox('Purchase Records', _number(recordCount)),
        pw.SizedBox(width: 8),
        _summaryBox('Purchased Qty', _number(purchasedQty)),
        pw.SizedBox(width: 8),
        _summaryBox('Used Qty', _number(usedQty)),
        pw.SizedBox(width: 8),
        _summaryBox('Remaining Qty', _number(remainingQty)),
        pw.SizedBox(width: 8),
        _summaryBox('Purchase Cost', _currency(purchaseCost)),
      ],
    );
  }

  pw.Widget _summaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _lightGreen,
          borderRadius: pw.BorderRadius.circular(7),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _green,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7.5, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _inventoryTable(List<Map<String, dynamic>> records) {
    final rows = records
        .map(
          (row) => [
            _value(row['item_name']),
            _value(row['unit']),
            _number(_toDouble(row['purchased_qty'])),
            _number(_toDouble(row['used_qty'])),
            _number(_toDouble(row['remaining_qty'])),
            _currency(row['purchase_cost']),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Spare Item',
        'Unit',
        'Purchased Qty',
        'Used Qty',
        'Remaining Qty',
        'Purchase Cost',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder.all(color: _border, width: .5),
    );
  }

  pw.Widget _blastingSummary({
    required int purchaseCount,
    required double bulletQty,
    required double wire3mQty,
    required double wire4mQty,
    required double edQty,
    required double totalCost,
  }) {
    return pw.Row(
      children: [
        _summaryBox('Purchase Records', '$purchaseCount'),
        pw.SizedBox(width: 7),
        _summaryBox('Bullet Qty', _number(bulletQty)),
        pw.SizedBox(width: 7),
        _summaryBox('3m Wire Qty', _number(wire3mQty)),
        pw.SizedBox(width: 7),
        _summaryBox('4m Wire Qty', _number(wire4mQty)),
        pw.SizedBox(width: 7),
        _summaryBox('ED Qty', _number(edQty)),
        pw.SizedBox(width: 7),
        _summaryBox('Total Cost', _currency(totalCost)),
      ],
    );
  }

  pw.Widget _blastingPeriodSummary({
    required double bulletQty,
    required double bulletCost,
    required double wire3mQty,
    required double wire3mCost,
    required double wire4mQty,
    required double wire4mCost,
    required double edQty,
    required double edCost,
    required double totalCost,
  }) {
    final rows = [
      ['Bullet', _number(bulletQty), _currency(bulletCost)],
      ['3m Wire', _number(wire3mQty), _currency(wire3mCost)],
      ['4m Wire', _number(wire4mQty), _currency(wire4mCost)],
      ['ED', _number(edQty), _currency(edCost)],
      ['Grand Total', '', _currency(totalCost)],
    ];

    return pw.TableHelper.fromTextArray(
      headers: const ['Item', 'Total Quantity', 'Total Cost'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      border: pw.TableBorder.all(color: _border, width: .5),
    );
  }

  pw.Widget _blastingTable(List<Map<String, dynamic>> records) {
    final rows = records
        .map(
          (row) => [
            _formatDateString(row['purchaseDate']?.toString()),
            _number(row['bulletQuantity']),
            _currency(row['bulletPrice']),
            _currency(row['bulletTotal']),
            _number(row['wire3mQuantity']),
            _currency(row['wire3mPrice']),
            _currency(row['wire3mTotal']),
            _number(row['wire4mQuantity']),
            _currency(row['wire4mPrice']),
            _currency(row['wire4mTotal']),
            _number(row['edQuantity']),
            _currency(row['edPrice']),
            _currency(row['edTotal']),
            _currency(row['totalCost']),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Date',
        'Bullet Qty',
        'Bullet Price',
        'Bullet Total',
        '3m Qty',
        '3m Price',
        '3m Total',
        '4m Qty',
        '4m Price',
        '4m Total',
        'ED Qty',
        'ED Price',
        'ED Total',
        'Grand Total',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 6.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 6.5, color: _text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      border: pw.TableBorder.all(color: _border, width: .5),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  pw.Widget _header({
    required String title,
    String? filter,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final range = _dateRange(fromDate, toDate);

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'StoneFleet ERP',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _green,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (filter != null)
                pw.Text(
                  filter,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
              if (range.isNotEmpty)
                pw.Text(
                  range,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
              pw.Text(
                'Generated: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _border, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'StoneFleet ERP',
            style: pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _summary({required int total, required String label}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightGreen,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            total.toString(),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: _green,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ],
      ),
    );
  }

  pw.Widget _maintenanceServiceTable(
    List<Map<String, dynamic>> records,
    String type,
  ) {
    final rows = records.map((record) {
      final date = type == 'service'
          ? record['service_date']?.toString() ?? '-'
          : record['created_at']?.toString() ?? '-';
      final detail = type == 'service'
          ? _number(record['current_hour_meter'] ?? record['current_km'])
          : _maintenanceDetails(record);
      final cost = type == 'service'
          ? _currency(record['item_cost'])
          : _currency(record['diesel_expense']);

      return [
        _value(record['equipment_type']),
        _value(record['registration_number'], fallback: 'Unknown'),
        _formatDateString(date),
        detail,
        cost,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Equipment',
        'Registration',
        'Date',
        'Details / Meter',
        'Cost',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      border: pw.TableBorder.all(color: _border, width: .5),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _complianceSummary(List<Map<String, dynamic>> records) {
    int count(String status) =>
        records.where((r) => r['overall_status'] == status).length;

    return pw.Row(
      children: [
        _summaryChip('Total', records.length.toString()),
        pw.SizedBox(width: 8),
        _summaryChip('Valid', count('Valid').toString()),
        pw.SizedBox(width: 8),
        _summaryChip('Due Soon', count('Due Soon').toString()),
        pw.SizedBox(width: 8),
        _summaryChip('Expired', count('Expired').toString()),
        pw.SizedBox(width: 8),
        _summaryChip('Not Configured', count('Not Configured').toString()),
      ],
    );
  }

  pw.Widget _summaryChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _lightGreen,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$value ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _green,
              ),
            ),
            pw.TextSpan(
              text: label,
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _complianceTable(List<Map<String, dynamic>> records) {
    final rows = records
        .map(
          (record) => [
            _value(record['equipment_type']),
            _value(record['registration_number'], fallback: 'Not Registered'),
            '${_value(record['manufacturer_name'])} / ${_value(record['model_name'])}',
            _formatDateString(record['insurance_expiry']?.toString()),
            _formatDateString(record['fc_expiry']?.toString()),
            _formatDateString(record['permit_expiry']?.toString()),
            _formatDateString(record['tax_expiry']?.toString()),
            _value(record['overall_status']),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Equipment',
        'Registration',
        'Manufacturer / Model',
        'Insurance',
        'FC',
        'Permit',
        'Tax',
        'Overall Status',
      ],
      data: rows,
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _green),
      cellStyle: const pw.TextStyle(fontSize: 7.5, color: _text),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      border: pw.TableBorder.all(color: _border, width: .5),
    );
  }

  String _maintenanceDetails(Map<String, dynamic> record) {
    final remarks = record['remarks']?.toString();
    if (remarks != null && remarks.trim().isNotEmpty) return remarks.trim();
    final loads = record['number_of_loads'];
    if (loads != null) return 'Loads: $loads';
    return '-';
  }

  String _value(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _number(dynamic value) {
    if (value == null) return '-';
    final number = double.tryParse(value.toString());
    if (number == null) return value.toString();
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(2);
  }

  String _currency(dynamic value) {
    if (value == null) return '₹0.00';
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return '₹${number.toStringAsFixed(2)}';
  }

  String _formatDateString(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _dateRange(DateTime? fromDate, DateTime? toDate) {
    if (fromDate == null && toDate == null) return '';
    if (fromDate != null && toDate != null) {
      return '${_formatDate(fromDate)} - ${_formatDate(toDate)}';
    }
    if (fromDate != null) return 'From ${_formatDate(fromDate)}';
    return 'To ${_formatDate(toDate!)}';
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateTime(DateTime date) =>
      '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
