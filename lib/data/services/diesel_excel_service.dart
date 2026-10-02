import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/diesel_models.dart';

class DieselExcelService {
  Future<String> exportReport({
    required List<DieselReportRow> rows,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final excel = Excel.createExcel();
    const sheetName = 'Diesel Report';
    final sheet = excel[sheetName];

    if (excel.tables.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Vehicle'),
      TextCellValue('Vehicle Type'),
      TextCellValue('Diesel (L)'),
      TextCellValue('Rate'),
      TextCellValue('Cost'),
    ]);

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(_formatDate(row.date)),
        TextCellValue(row.vehicleRegistration),
        TextCellValue(row.vehicleType),
        DoubleCellValue(row.litres),
        DoubleCellValue(row.rate),
        DoubleCellValue(row.cost),
      ]);
    }

    const widths = <int, double>{
      0: 15,
      1: 22,
      2: 18,
      3: 15,
      4: 15,
      5: 18,
    };
    for (final entry in widths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }

    final summarySheet = excel['Summary'];
    summarySheet.appendRow([TextCellValue('Diesel Report Summary')]);
    summarySheet.appendRow([TextCellValue('From'), TextCellValue(_formatDate(fromDate.toIso8601String()))]);
    summarySheet.appendRow([TextCellValue('To'), TextCellValue(_formatDate(toDate.toIso8601String()))]);
    summarySheet.appendRow([TextCellValue('Total Diesel Used (L)'), DoubleCellValue(rows.fold<double>(0, (s, r) => s + r.litres))]);
    summarySheet.appendRow([TextCellValue('Total Diesel Cost'), DoubleCellValue(rows.fold<double>(0, (s, r) => s + r.cost))]);

    final directory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory('${directory.path}/StoneFleet Reports');
    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final path = '${reportsDirectory.path}/diesel_report_$stamp.xlsx';
    final bytes = excel.save();
    if (bytes == null) throw Exception('Unable to create Diesel Excel file.');

    await File(path).writeAsBytes(bytes);
    return path;
  }

  String _formatDate(String value) {
    final d = DateTime.tryParse(value);
    if (d == null) return value;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
