import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/diesel_models.dart';

class DieselPdfService {
  Future<Uint8List> buildReport({
    required List<DieselReportRow> rows,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final doc = pw.Document();
    final litres = rows.fold<double>(0, (s, r) => s + r.litres);
    final cost = rows.fold<double>(0, (s, r) => s + r.cost);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (_) => pw.Row(
          children: [
            pw.Text(
              'StoneFleet ERP',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Spacer(),
            pw.Text('Diesel Report'),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${ctx.pageNumber}'),
        ),
        build: (_) => [
          pw.SizedBox(height: 12),
          pw.Text('Period: ${_d(fromDate)} - ${_d(toDate)}'),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _kpi('Diesel Used', '${litres.toStringAsFixed(2)} L'),
              pw.SizedBox(width: 12),
              _kpi('Total Cost', '₹ ${cost.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Vehicle', 'Type', 'Diesel (L)', 'Rate', 'Cost'],
            data: rows
                .map(
                  (r) => [
                    _d(DateTime.tryParse(r.date) ?? DateTime.now()),
                    r.vehicleRegistration,
                    r.vehicleType,
                    r.litres.toStringAsFixed(2),
                    '₹ ${r.rate.toStringAsFixed(2)}',
                    '₹ ${r.cost.toStringAsFixed(2)}',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _kpi(String a, String b) => pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(border: pw.Border.all()),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(a),
        pw.SizedBox(height: 4),
        pw.Text(b, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
  String _d(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  Future<void> printReport({
    required List<DieselReportRow> rows,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final bytes = await buildReport(
      rows: rows,
      fromDate: fromDate,
      toDate: toDate,
    );
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> shareReport({
    required List<DieselReportRow> rows,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final bytes = await buildReport(
      rows: rows,
      fromDate: fromDate,
      toDate: toDate,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'diesel_report.pdf');
  }
}
