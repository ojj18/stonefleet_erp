import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ReportExcelService {
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
