import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/quarry_blasting_purchase_model.dart';
import '../../auth/providers/auth_provider.dart';

import '../providers/quarry_blasting_provider.dart';
import '../widgets/quarry_blasting_shell.dart';
import 'quarry_blasting_new_purchase_screen.dart';

class QuarryBlastingPurchaseHistoryScreen extends StatefulWidget {
  const QuarryBlastingPurchaseHistoryScreen({super.key});

  @override
  State<QuarryBlastingPurchaseHistoryScreen> createState() => _QuarryBlastingPurchaseHistoryScreenState();
}

class _QuarryBlastingPurchaseHistoryScreenState extends State<QuarryBlastingPurchaseHistoryScreen> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    await context.read<QuarryBlastingProvider>().loadPurchases(
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
    await _load();
  }

  Future<void> _openNew() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuarryBlastingNewPurchaseScreen()),
    );
    if (mounted) _load();
  }

  Future<void> _openEdit(QuarryBlastingPurchase purchase) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuarryBlastingNewPurchaseScreen(purchase: purchase),
      ),
    );
    if (mounted) _load();
  }

  void _viewPurchase(QuarryBlastingPurchase purchase) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Purchase Details'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Purchase Date', formatDate(purchase.purchaseDate)),
              _detailRow('Bullet', '${formatQty(purchase.bulletQuantity)} × ${formatMoney(purchase.bulletPrice)}', total: purchase.bulletTotal),
              _detailRow('3m Wire', '${formatQty(purchase.wire3mQuantity)} × ${formatMoney(purchase.wire3mPrice)}', total: purchase.wire3mTotal),
              _detailRow('4m Wire', '${formatQty(purchase.wire4mQuantity)} × ${formatMoney(purchase.wire4mPrice)}', total: purchase.wire4mTotal),
              _detailRow('ED', '${formatQty(purchase.edQuantity)} × ${formatMoney(purchase.edPrice)}', total: purchase.edTotal),
              const Divider(height: 24),
              _detailRow('Grand Total', formatMoney(purchase.totalCost), bold: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {double? total, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          if (total != null) ...[
            const SizedBox(width: 18),
            Text(formatMoney(total), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(QuarryBlastingPurchase purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Purchase?'),
        content: const Text('This purchase record will be permanently deleted. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<QuarryBlastingProvider>();
    await provider.deletePurchase(purchase.id!);
    if (!mounted) return;
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase deleted successfully.')));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return QuarryBlastingShell(
      selectedIndex: 16,
      child: Consumer<QuarryBlastingProvider>(
        builder: (context, provider, _) {
          final summary = provider.summary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuarryPageHeader(
                      title: 'Purchase History',
                      subtitle: 'View and filter all quarry blasting material purchase records.',
                      action: FilledButton.icon(
                        onPressed: _openNew,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New Purchase'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00652C),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    QuarryCard(
                      title: 'Filters',
                      icon: Icons.filter_alt_outlined,
                      child: Row(
                        children: [

                          Expanded(child: _dateButton('From Date', _from, () => _pickDate(true))),
                          const SizedBox(width: 12),
                          Expanded(child: _dateButton('To Date', _to, () => _pickDate(false))),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _from = null;
                                _to = null;
                              });
                              _load();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: QuarryKpiCard(title: 'Bullet Qty', value: formatQty(summary.bulletQuantity), icon: Icons.inventory_2_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: '3m Wire Qty', value: formatQty(summary.wire3mQuantity), icon: Icons.cable_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: '4m Wire Qty', value: formatQty(summary.wire4mQuantity), icon: Icons.cable_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: 'ED Qty', value: formatQty(summary.edQuantity), icon: Icons.bolt_outlined)),
                        const SizedBox(width: 12),
                        Expanded(child: QuarryKpiCard(title: 'Total Cost', value: formatMoney(summary.totalCost), icon: Icons.currency_rupee_outlined)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    QuarryCard(
                      title: 'Purchase Records',
                      icon: Icons.table_rows_outlined,
                      child: provider.purchases.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 36),
                              child: Center(child: Text('No purchase records found for the selected filters.')),
                            )
                          : _buildTable(provider.purchases),
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Select date' : formatDate(value.toIso8601String())),
      ),
    );
  }

  Widget _buildTable(List purchases) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 22,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8F9FB)),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Bullet Qty')),
          DataColumn(label: Text('Bullet Price')),
          DataColumn(label: Text('3m Wire Qty')),
          DataColumn(label: Text('3m Wire Price')),
          DataColumn(label: Text('4m Wire Qty')),
          DataColumn(label: Text('4m Wire Price')),
          DataColumn(label: Text('ED Qty')),
          DataColumn(label: Text('ED Price')),
          DataColumn(label: Text('Total Cost')),
          DataColumn(label: Text('Actions')),
        ],
        rows: purchases.map<DataRow>((p) => DataRow(cells: [
          DataCell(Text(formatDate(p.purchaseDate))),
          DataCell(Text(formatQty(p.bulletQuantity))),
          DataCell(Text(formatMoney(p.bulletPrice))),
          DataCell(Text(formatQty(p.wire3mQuantity))),
          DataCell(Text(formatMoney(p.wire3mPrice))),
          DataCell(Text(formatQty(p.wire4mQuantity))),
          DataCell(Text(formatMoney(p.wire4mPrice))),
          DataCell(Text(formatQty(p.edQuantity))),
          DataCell(Text(formatMoney(p.edPrice))),
          DataCell(Text(formatMoney(p.totalCost), style: const TextStyle(fontWeight: FontWeight.w700))),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'View',
                onPressed: p.id == null ? null : () => _viewPurchase(p),
                icon: const Icon(Icons.visibility_outlined, size: 19),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: p.id == null ? null : () => _openEdit(p),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
              if (context.watch<AuthProvider>().isAdmin)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: p.id == null ? null : () => _confirmDelete(p),
                  icon: const Icon(Icons.delete_outline, size: 19, color: Color(0xFFBA1A1A)),
                ),
            ],
          )),
        ])).toList(),
      ),
    );
  }
}
