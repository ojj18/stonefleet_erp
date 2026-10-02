import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../data/services/report_excel_service.dart';
import '../../../data/services/pdf_report_service.dart';
import '../providers/quarry_blasting_provider.dart';
import '../widgets/quarry_blasting_shell.dart';

class QuarryBlastingPurchaseReportsScreen extends StatefulWidget {
  const QuarryBlastingPurchaseReportsScreen({super.key});

  @override
  State<QuarryBlastingPurchaseReportsScreen> createState() => _QuarryBlastingPurchaseReportsScreenState();
}

class _QuarryBlastingPurchaseReportsScreenState extends State<QuarryBlastingPurchaseReportsScreen> {
  String _period = 'Monthly';
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    await context.read<QuarryBlastingProvider>().loadReport(
      period: _period,
      fromDate: _from,
      toDate: _to,
    );
  }

  Future<void> _pickDate(bool from) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (from ? _from : _to) ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _export(QuarryBlastingProvider provider) async {
    try {
      final path = await ReportExcelService().exportQuarryBlastingReport(
        records: provider.purchases,
        period: _period,
        summary: provider.summary,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel exported: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<Uint8List> _buildBlastingPdf(QuarryBlastingProvider provider) {
    final s = provider.summary;
    return PdfReportService().buildQuarryBlastingReport(
      records: provider.purchases
          .map(
            (p) => {
              'purchaseDate': p.purchaseDate,
              'bulletQuantity': p.bulletQuantity,
              'bulletPrice': p.bulletPrice,
              'bulletTotal': p.bulletTotal,
              'wire3mQuantity': p.wire3mQuantity,
              'wire3mPrice': p.wire3mPrice,
              'wire3mTotal': p.wire3mTotal,
              'wire4mQuantity': p.wire4mQuantity,
              'wire4mPrice': p.wire4mPrice,
              'wire4mTotal': p.wire4mTotal,
              'edQuantity': p.edQuantity,
              'edPrice': p.edPrice,
              'edTotal': p.edTotal,
              'totalCost': p.totalCost,
            },
          )
          .toList(),
      period: _period,
      fromDate: _from,
      toDate: _to,
      summary: {
        'purchaseCount': s.purchaseCount,
        'bulletQuantity': s.bulletQuantity,
        'wire3mQuantity': s.wire3mQuantity,
        'wire4mQuantity': s.wire4mQuantity,
        'edQuantity': s.edQuantity,
        'bulletCost': s.bulletCost,
        'wire3mCost': s.wire3mCost,
        'wire4mCost': s.wire4mCost,
        'edCost': s.edCost,
        'totalCost': s.totalCost,
      },
    );
  }

  Future<void> _exportPdf(QuarryBlastingProvider provider) async {
    try {
      final bytes = await _buildBlastingPdf(provider);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'stonefleet_quarry_blasting_${_period.toLowerCase().replaceAll(' ', '_')}_report.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _printReport(QuarryBlastingProvider provider) async {
    try {
      final bytes = await _buildBlastingPdf(provider);
      await Printing.layoutPdf(
        name: 'StoneFleet Quarry Blasting Purchase Report',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return QuarryBlastingShell(
      selectedIndex: 17,
      child: Consumer<QuarryBlastingProvider>(
        builder: (context, provider, _) {
          final s = provider.summary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuarryPageHeader(
                      title: 'Purchase Reports',
                      subtitle: 'Generate daily, weekly, monthly and yearly blasting material reports.',
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: provider.purchases.isEmpty ? null : () => _export(provider),
                            icon: const Icon(Icons.file_download_outlined, size: 19),
                            label: const Text('Export Excel'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(140, 48)),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: provider.purchases.isEmpty ? null : () => _exportPdf(provider),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
                            label: const Text('Export PDF'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(130, 48)),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: provider.purchases.isEmpty ? null : () => _printReport(provider),
                            icon: const Icon(Icons.print_outlined, size: 19),
                            label: const Text('Print'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(100, 48)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    QuarryCard(
                      title: 'Report Filters',
                      icon: Icons.filter_alt_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _period,
                              decoration: const InputDecoration(labelText: 'Report Period', border: OutlineInputBorder()),
                              items: const ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom Range']
                                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _period = value);
                              },
                            ),
                          ),
                          if (_period == 'Custom Range') ...[
                            const SizedBox(width: 12),
                            Expanded(child: _dateButton('From Date', _from, () => _pickDate(true))),
                            const SizedBox(width: 12),
                            Expanded(child: _dateButton('To Date', _to, () => _pickDate(false))),
                          ],
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _generate,
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Generate'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00652C),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: QuarryKpiCard(title: 'Bullet Qty', value: formatQty(s.bulletQuantity), icon: Icons.inventory_2_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: '3m Wire Qty', value: formatQty(s.wire3mQuantity), icon: Icons.cable_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: '4m Wire Qty', value: formatQty(s.wire4mQuantity), icon: Icons.cable_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: 'ED Qty', value: formatQty(s.edQuantity), icon: Icons.bolt_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: 'Total Cost', value: formatMoney(s.totalCost), icon: Icons.currency_rupee_outlined)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    QuarryCard(
                      title: 'Period Summary',
                      icon: Icons.summarize_outlined,
                      child: Column(
                        children: [
                          _summaryRow('Bullet', s.bulletQuantity, s.bulletCost),
                          const Divider(height: 22),
                          _summaryRow('3m Wire', s.wire3mQuantity, s.wire3mCost),
                          const Divider(height: 22),
                          _summaryRow('4m Wire', s.wire4mQuantity, s.wire4mCost),
                          const Divider(height: 22),
                          _summaryRow('ED', s.edQuantity, s.edCost),
                          const Divider(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total Cost', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                              Text(formatMoney(s.totalCost), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF00652C))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    QuarryCard(
                      title: 'Purchase Records in Selected Period',
                      icon: Icons.table_rows_outlined,
                      child: provider.purchases.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(child: Text('No purchase records found for the selected period.')),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8F9FB)),
                                columns: const [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Bullet Qty')),
                                  DataColumn(label: Text('3m Wire Qty')),
                                  DataColumn(label: Text('4m Wire Qty')),
                                  DataColumn(label: Text('ED Qty')),
                                  DataColumn(label: Text('Total Cost')),
                                ],
                                rows: provider.purchases.map((p) => DataRow(cells: [
                                  DataCell(Text(formatDate(p.purchaseDate))),
                                  DataCell(Text(formatQty(p.bulletQuantity))),
                                  DataCell(Text(formatQty(p.wire3mQuantity))),
                                  DataCell(Text(formatQty(p.wire4mQuantity))),
                                  DataCell(Text(formatQty(p.edQuantity))),
                                  DataCell(Text(formatMoney(p.totalCost))),
                                ])).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dateButton(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today_outlined)),
        child: Text(value == null ? 'Select date' : formatDate(value.toIso8601String())),
      ),
    );
  }

  Widget _summaryRow(String item, double quantity, double cost) {
    return Row(
      children: [
        Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w700))),
        SizedBox(width: 160, child: Text('Qty: ${formatQty(quantity)}', textAlign: TextAlign.right)),
        SizedBox(width: 190, child: Text('Cost: ${formatMoney(cost)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}
