import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quarry_blasting_purchase_model.dart';

class ReportExcelService {
  // --------------------------------------------------------
  // REPORT EXCEL
  // --------------------------------------------------------

  Future<String> exportReport({
    required List<Map<String, dynamic>> records,
    required String reportType,
    required String equipmentType,
  }) async {
    final excel = Excel.createExcel();

    final sheetName = reportType == 'service'
        ? 'Service Report'
        : 'Maintenance Report';

    final sheet = excel[sheetName];

    // Remove default sheet if necessary
    if (excel.tables.keys.contains('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    // ------------------------------------------------------------
    // HEADER
    // ------------------------------------------------------------

    sheet.appendRow([
      TextCellValue('Equipment'),
      TextCellValue('Registration'),
      TextCellValue('Date'),
      TextCellValue(reportType == 'service' ? 'Meter' : 'Details'),
      TextCellValue(reportType == 'service' ? 'Spare' : 'Operator / Driver'),
      TextCellValue(reportType == 'service' ? 'Quantity' : 'Loads'),
      TextCellValue(reportType == 'service' ? 'Item Cost' : 'Diesel Filled'),
      TextCellValue('Cost'),
      TextCellValue('Remarks'),
    ]);

    // ------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------

    for (final record in records) {
      final isService = reportType == 'service';

      final equipment = record['equipment_type']?.toString() ?? '';

      final registration = record['registration_number']?.toString() ?? '';

      final date = isService
          ? record['service_date']?.toString() ?? ''
          : record['created_at']?.toString() ?? '';

      final meter = isService
          ? record['current_hour_meter'] ?? record['current_km'] ?? ''
          : '';

      final person = isService
          ? record['spare_name']?.toString() ?? ''
          : record['operator_name']?.toString() ??
                record['driver_name']?.toString() ??
                '';

      final quantity = isService
          ? record['quantity'] ?? ''
          : record['number_of_loads'] ?? '';

      final extraCost = isService
          ? record['item_cost'] ?? ''
          : record['diesel_filled'] ?? '';

      final cost = isService
          ? record['item_cost'] ?? 0
          : record['diesel_expense'] ?? 0;

      final remarks = record['remarks']?.toString() ?? '';

      sheet.appendRow([
        TextCellValue(_capitalize(equipment)),
        TextCellValue(registration),
        TextCellValue(_formatDate(date)),
        _cellValue(meter),
        TextCellValue(person),
        _cellValue(quantity),
        _cellValue(extraCost),
        _cellValue(cost),
        TextCellValue(remarks),
      ]);
    }

    // ------------------------------------------------------------
    // COLUMN WIDTH
    // ------------------------------------------------------------

    final widths = <int, double>{
      0: 15,
      1: 18,
      2: 14,
      3: 18,
      4: 25,
      5: 12,
      6: 15,
      7: 15,
      8: 35,
    };

    for (final entry in widths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }

    // ------------------------------------------------------------
    // SAVE
    // ------------------------------------------------------------

    final directory = await getApplicationDocumentsDirectory();

    final reportsDirectory = Directory('${directory.path}/StoneFleet Reports');

    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final timestamp = _fileTimestamp();

    final fileName = '${reportType}_${equipmentType}_report_$timestamp.xlsx';

    final filePath = '${reportsDirectory.path}/$fileName';

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception('Unable to create Excel file.');
    }

    final file = File(filePath);

    await file.writeAsBytes(bytes);

    return filePath;
  }

  // --------------------------------------------------------
  // COMPLIANCE EXCEL
  // --------------------------------------------------------

  Future<String> exportComplianceReport({
    required List<Map<String, dynamic>> records,
  }) async {
    final excel = Excel.createExcel();

    const sheetName = 'Compliance Report';
    final sheet = excel[sheetName];

    // ------------------------------------------------------------
    // REMOVE DEFAULT SHEET
    // ------------------------------------------------------------

    if (excel.tables.keys.contains('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    // ------------------------------------------------------------
    // HEADER
    // ------------------------------------------------------------

    sheet.appendRow([
      TextCellValue('Equipment'),
      TextCellValue('Registration'),
      TextCellValue('Manufacturer'),
      TextCellValue('Model'),
      TextCellValue('Insurance'),
      TextCellValue('FC'),
      TextCellValue('Permit'),
      TextCellValue('Tax'),
      TextCellValue('Overall Status'),
    ]);

    // ------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------

    for (final record in records) {
      // Current data row index
      final rowIndex = sheet.maxRows;

      // Add row
      sheet.appendRow([
        TextCellValue(record['equipment_type']?.toString() ?? ''),
        TextCellValue(record['registration_number']?.toString() ?? ''),
        TextCellValue(record['manufacturer_name']?.toString() ?? ''),
        TextCellValue(record['model_name']?.toString() ?? ''),
        TextCellValue(_formatDateOrEmpty(record['insurance_expiry'])),
        TextCellValue(_formatDateOrEmpty(record['fc_expiry'])),
        TextCellValue(_formatDateOrEmpty(record['permit_expiry'])),
        TextCellValue(_formatDateOrEmpty(record['tax_expiry'])),
        TextCellValue(record['overall_status']?.toString() ?? ''),
      ]);

      // ----------------------------------------------------------
      // EXPIRY COLUMNS
      //
      // Excel column index:
      // 0 = Equipment
      // 1 = Registration
      // 2 = Manufacturer
      // 3 = Model
      // 4 = Insurance
      // 5 = FC
      // 6 = Permit
      // 7 = Tax
      // ----------------------------------------------------------

      final expiryColumns = <int, String?>{
        4: record['insurance_expiry']?.toString(),
        5: record['fc_expiry']?.toString(),
        6: record['permit_expiry']?.toString(),
        7: record['tax_expiry']?.toString(),
      };

      // ----------------------------------------------------------
      // APPLY RED BACKGROUND TO EXPIRED CELLS
      // ----------------------------------------------------------

      for (final entry in expiryColumns.entries) {
        final columnIndex = entry.key;
        final expiryValue = entry.value;

        if (_isExpired(expiryValue)) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: columnIndex,
              rowIndex: rowIndex,
            ),
          );

          cell.cellStyle = CellStyle(
            backgroundColorHex: ExcelColor.fromHexString('#FDECEC'),
            fontColorHex: ExcelColor.fromHexString('#BA1A1A'),
            bold: true,
          );
        }
      }
    }

    // ------------------------------------------------------------
    // COLUMN WIDTH
    // ------------------------------------------------------------

    final widths = <int, double>{
      0: 18,
      1: 20,
      2: 24,
      3: 24,
      4: 16,
      5: 16,
      6: 16,
      7: 16,
      8: 20,
    };

    for (final entry in widths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }

    // ------------------------------------------------------------
    // SAVE
    // ------------------------------------------------------------

    final directory = await getApplicationDocumentsDirectory();

    final reportsDirectory = Directory('${directory.path}/StoneFleet Reports');

    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final timestamp = _fileTimestamp();

    final fileName = 'compliance_report_$timestamp.xlsx';

    final filePath = '${reportsDirectory.path}/$fileName';

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception('Unable to create Compliance Excel file.');
    }

    final file = File(filePath);

    await file.writeAsBytes(bytes);

    return filePath;
  }

  Future<String> exportInventoryReport({
    required List<Map<String, dynamic>> records,
    required String period,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Inventory Report';
    final sheet = excel[sheetName];
    if (excel.tables.keys.contains('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('Spare Item'),
      TextCellValue('Unit'),
      TextCellValue('Purchased Qty'),
      TextCellValue('Used Qty'),
      TextCellValue('Remaining Qty'),
      TextCellValue('Purchase Cost'),
    ]);

    for (final record in records) {
      sheet.appendRow([
        TextCellValue(record['item_name']?.toString() ?? ''),
        TextCellValue(record['unit']?.toString() ?? ''),
        _cellValue(record['purchased_qty'] ?? 0),
        _cellValue(record['used_qty'] ?? 0),
        _cellValue(record['remaining_qty'] ?? 0),
        _cellValue(record['purchase_cost'] ?? 0),
      ]);
    }

    const widths = <int, double>{0: 30, 1: 12, 2: 18, 3: 15, 4: 18, 5: 18};
    for (final entry in widths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }

    final directory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory('${directory.path}/StoneFleet Reports');
    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final timestamp = _fileTimestamp();
    final filePath = '${reportsDirectory.path}/inventory_${period.toLowerCase()}_$timestamp.xlsx';
    final bytes = excel.save();
    if (bytes == null) throw Exception('Unable to create Inventory Excel file.');
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  Future<String> exportQuarryBlastingReport({
    required List<QuarryBlastingPurchase> records,
    required String period,
    required QuarryPurchaseSummary summary,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Blasting Purchase Report';
    final sheet = excel[sheetName];

    if (excel.tables.keys.contains('Sheet1') && sheetName != 'Sheet1') {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Operator'),
      TextCellValue('Salary'),
      TextCellValue('Bullet Qty'),
      TextCellValue('Bullet Unit Price'),
      TextCellValue('Bullet Total'),
      TextCellValue('3m Wire Qty'),
      TextCellValue('3m Wire Unit Price'),
      TextCellValue('3m Wire Total'),
      TextCellValue('4m Wire Qty'),
      TextCellValue('4m Wire Unit Price'),
      TextCellValue('4m Wire Total'),
      TextCellValue('ED Qty'),
      TextCellValue('ED Unit Price'),
      TextCellValue('ED Total'),
      TextCellValue('Grand Total'),
    ]);

    for (final record in records) {
      sheet.appendRow([
        TextCellValue(_formatDate(record.purchaseDate)),
        TextCellValue(record.operatorName),
        _cellValue(record.salary),
        _cellValue(record.bulletQuantity),
        _cellValue(record.bulletPrice),
        _cellValue(record.bulletTotal),
        _cellValue(record.wire3mQuantity),
        _cellValue(record.wire3mPrice),
        _cellValue(record.wire3mTotal),
        _cellValue(record.wire4mQuantity),
        _cellValue(record.wire4mPrice),
        _cellValue(record.wire4mTotal),
        _cellValue(record.edQuantity),
        _cellValue(record.edPrice),
        _cellValue(record.edTotal),
        _cellValue(record.totalCost),
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Period Summary')]);
    sheet.appendRow([TextCellValue('Item'), TextCellValue('Total Quantity'), TextCellValue('Total Cost')]);
    sheet.appendRow([TextCellValue('Bullet'), _cellValue(summary.bulletQuantity), _cellValue(summary.bulletCost)]);
    sheet.appendRow([TextCellValue('3m Wire'), _cellValue(summary.wire3mQuantity), _cellValue(summary.wire3mCost)]);
    sheet.appendRow([TextCellValue('4m Wire'), _cellValue(summary.wire4mQuantity), _cellValue(summary.wire4mCost)]);
    sheet.appendRow([TextCellValue('ED'), _cellValue(summary.edQuantity), _cellValue(summary.edCost)]);
    sheet.appendRow([TextCellValue('Grand Total Cost'), TextCellValue(''), _cellValue(summary.totalCost)]);

    const widths = <int, double>{
      0: 14,
      1: 14,
      2: 18,
      3: 16,
      4: 15,
      5: 19,
      6: 17,
      7: 15,
      8: 19,
      9: 17,
      10: 12,
      11: 17,
      12: 15,
      13: 17,
    };

    for (final entry in widths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }

    final directory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory('${directory.path}/StoneFleet Reports');
    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final timestamp = _fileTimestamp();
    final filePath = '${reportsDirectory.path}/quarry_blasting_${period.toLowerCase().replaceAll(' ', '_')}_$timestamp.xlsx';
    final bytes = excel.save();
    if (bytes == null) throw Exception('Unable to create Quarry Blasting Excel file.');
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  bool _isExpired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return false;
    }

    final today = DateTime.now();

    final todayOnly = DateTime(today.year, today.month, today.day);

    final expiryOnly = DateTime(date.year, date.month, date.day);

    return expiryOnly.isBefore(todayOnly);
  }

  String _formatDateOrEmpty(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();

    if (text.isEmpty) return '';

    return _formatDate(text);
  }

  CellValue _cellValue(dynamic value) {
    if (value == null) {
      return TextCellValue('');
    }

    if (value is int) {
      return IntCellValue(value);
    }

    if (value is double) {
      return DoubleCellValue(value);
    }

    if (value is num) {
      return DoubleCellValue(value.toDouble());
    }

    return TextCellValue(value.toString());
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1);
  }

  String _fileTimestamp() {
    final now = DateTime.now();

    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
