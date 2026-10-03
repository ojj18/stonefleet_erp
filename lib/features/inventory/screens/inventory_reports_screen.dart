import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../data/services/report_excel_service.dart';
import '../../../data/services/pdf_report_service.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_shell.dart';

class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});
  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen> {
  String _period = 'Monthly';
  DateTime? _from;
  DateTime? _to;
  String? _item;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<InventoryProvider>();
      await p.loadItems();
      await p.loadReport(period: _period);
    });
  }

  Future<void> _pickDate(bool from) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (from ? _from : _to) ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() => from ? _from = picked : _to = picked);
  }

  Future<void> _generate() async =>
      context.read<InventoryProvider>().loadReport(
        period: _period,
        fromDate: _from,
        toDate: _to,
        itemName: _item,
      );

  Future<void> _export(InventoryProvider provider) async {
    try {
      final path = await ReportExcelService().exportInventoryReport(
        records: provider.reportRows,
        period: _period,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalization.t('Excel exported: ') + path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<Uint8List> _buildInventoryPdf(InventoryProvider provider) {
    return PdfReportService().buildInventoryReport(
      records: provider.reportRows,
      period: _period,
      itemName: _item,
      fromDate: _from,
      toDate: _to,
    );
  }

  Future<void> _exportPdf(InventoryProvider provider) async {
    try {
      final bytes = await _buildInventoryPdf(provider);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'stonefleet_inventory_${_period.toLowerCase()}_report.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _printReport(InventoryProvider provider) async {
    try {
      final bytes = await _buildInventoryPdf(provider);
      await Printing.layoutPdf(
        name: 'StoneFleet Inventory Report',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InventoryShell(
      selectedIndex: 14,
      child: Consumer<InventoryProvider>(
        builder: (context, provider, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InventoryPageHeader(
                    title: AppLocalization.t('Inventory Reports'),
                    subtitle:
                        AppLocalization.t('Generate daily, weekly, monthly and yearly spare inventory reports.'),
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: provider.reportRows.isEmpty
                              ? null
                              : () => _export(provider),
                          icon: const Icon(
                            Icons.file_download_outlined,
                            size: 20,
                          ),
                          label: Text(AppLocalization.t('Export Excel')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(145, 48),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: provider.reportRows.isEmpty
                              ? null
                              : () => _exportPdf(provider),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 20,
                          ),
                          label: Text(AppLocalization.t('Export PDF')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(135, 48),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: provider.reportRows.isEmpty
                              ? null
                              : () => _printReport(provider),
                          icon: const Icon(Icons.print_outlined, size: 20),
                          label: Text(AppLocalization.t('Print')),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(105, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InventoryKpiCard(
                          title: AppLocalization.t('Purchase Records'),
                          value: '${provider.reportRows.length}',
                          icon: Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InventoryKpiCard(
                          title: AppLocalization.t('Purchased Qty'),
                          value: formatQty(
                            provider.reportRows.fold<double>(
                              0,
                              (s, r) =>
                                  s +
                                  ((r['purchased_qty'] as num?)?.toDouble() ??
                                      0),
                            ),
                          ),
                          icon: Icons.add_shopping_cart_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InventoryKpiCard(
                          title: AppLocalization.t('Used Qty'),
                          value: formatQty(
                            provider.reportRows.fold<double>(
                              0,
                              (s, r) =>
                                  s +
                                  ((r['used_qty'] as num?)?.toDouble() ?? 0),
                            ),
                          ),
                          icon: Icons.remove_shopping_cart_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InventoryKpiCard(
                          title: AppLocalization.t('Purchase Cost'),
                          value: formatMoney(
                            provider.reportRows.fold<double>(
                              0,
                              (s, r) =>
                                  s +
                                  ((r['purchase_cost'] as num?)?.toDouble() ??
                                      0),
                            ),
                          ),
                          icon: Icons.currency_rupee_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  InventorySectionCard(
                    title: AppLocalization.t('Report Filters'),
                    icon: Icons.filter_alt_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _period,
                                decoration: InputDecoration(
                                  labelText: AppLocalization.t('Report Period'),
                                  border: OutlineInputBorder(),
                                ),
                                items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(AppLocalization.t(e)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _period = v ?? 'Monthly'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _item,
                                decoration: InputDecoration(
                                  labelText: AppLocalization.t('Spare Item'),
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(AppLocalization.t('All Items')),
                                  ),
                                  ...provider.items.map(
                                    (e) => DropdownMenuItem(
                                      value: e.itemName,
                                      child: Text(e.itemName),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _item = v),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDate(true),
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(
                                  _from == null
                                      ? AppLocalization.t('From Date')
                                      : formatDate(_from!.toIso8601String()),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDate(false),
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(
                                  _to == null
                                      ? AppLocalization.t('To Date')
                                      : formatDate(_to!.toIso8601String()),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _period = 'Monthly';
                                  _from = null;
                                  _to = null;
                                  _item = null;
                                });
                                _generate();
                              },
                              child: Text(AppLocalization.t('Clear')),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _generate,
                              icon: const Icon(Icons.search),
                              label: Text(AppLocalization.t('Generate')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00652C),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  InventorySectionCard(
                    title: AppLocalization.t('Inventory Report'),
                    icon: Icons.assessment_outlined,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(
                            label: Text(AppLocalization.t('SPARE ITEM')),
                          ),
                          DataColumn(
                            label: Text(AppLocalization.t('PURCHASED QTY')),
                          ),
                          DataColumn(
                            label: Text(AppLocalization.t('USED QTY')),
                          ),
                          DataColumn(
                            label: Text(AppLocalization.t('REMAINING QTY')),
                          ),
                          DataColumn(
                            label: Text(AppLocalization.t('PURCHASE COST')),
                          ),
                        ],
                        rows: provider.reportRows
                            .map(
                              (row) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(row['item_name']?.toString() ?? ''),
                                  ),
                                  DataCell(
                                    Text(
                                      formatQty(
                                        (row['purchased_qty'] as num?)
                                                ?.toDouble() ??
                                            0,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      formatQty(
                                        (row['used_qty'] as num?)?.toDouble() ??
                                            0,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      formatQty(
                                        (row['remaining_qty'] as num?)
                                                ?.toDouble() ??
                                            0,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      formatMoney(
                                        (row['purchase_cost'] as num?)
                                                ?.toDouble() ??
                                            0,
                                      ),
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
        ),
      ),
    );
  }
}
