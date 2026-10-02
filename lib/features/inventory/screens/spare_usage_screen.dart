import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../widgets/inventory_shell.dart';

class SpareUsageScreen extends StatefulWidget {
  const SpareUsageScreen({super.key});
  @override
  State<SpareUsageScreen> createState() => _SpareUsageScreenState();
}

class _SpareUsageScreenState extends State<SpareUsageScreen> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<InventoryProvider>();
      await p.loadItems();
      await p.loadUsage();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addUsage(InventoryProvider provider) async {
    String? item;
    final qty = TextEditingController();
    final usedFor = TextEditingController();
    final remarks = TextEditingController();
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Spare Usage'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: item,
                    decoration: const InputDecoration(labelText: 'Spare Item'),
                    items: provider.items
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.itemName,
                            child: Text(e.itemName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => item = v),
                    validator: (v) => v == null ? 'Select a spare item' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity Used',
                    ),
                    validator: (v) => double.tryParse(v ?? '') == null
                        ? 'Enter quantity'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usedFor,
                    decoration: const InputDecoration(
                      labelText:
                          'Used For (e.g. Excavator / Transport / Service)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: remarks,
                    decoration: const InputDecoration(labelText: 'Remarks'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(formatDate(date.toIso8601String())),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: date,
                        );
                        if (picked != null) setState(() => date = picked);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => formKey.currentState?.validate() == true
                  ? Navigator.pop(context, true)
                  : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || item == null) return;
    try {
      await provider.saveUsage(
        itemName: item!,
        quantityUsed: double.parse(qty.text),
        usageDate: date.toIso8601String(),
        usedFor: usedFor.text.trim(),
        remarks: remarks.text.trim(),
      );
      if (provider.error != null) throw Exception(provider.error);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Spare usage recorded.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    qty.dispose();
    usedFor.dispose();
    remarks.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InventoryShell(
      selectedIndex: 13,
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
                    title: 'Spare Usage',
                    subtitle:
                        'Record spare parts consumed during maintenance and service.',
                    action: ElevatedButton.icon(
                      onPressed: () => _addUsage(provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Record Usage'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00652C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: InventoryKpiCard(
                          title: 'Total Used Quantity',
                          value: formatQty(provider.summary.usedQuantity),
                          icon: Icons.remove_shopping_cart_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InventoryKpiCard(
                          title: 'Remaining Stock',
                          value: formatQty(provider.summary.remainingQuantity),
                          icon: Icons.inventory_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  InventorySectionCard(
                    title: 'Usage History',
                    icon: Icons.history_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _search,
                                onChanged: (v) => provider.loadUsage(search: v),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.search),
                                  hintText:
                                      'Search spare item, used for, remarks...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                _search.clear();
                                provider.loadUsage();
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('SPARE ITEM')),
                              DataColumn(label: Text('USED QTY')),
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('USED FOR')),
                              DataColumn(label: Text('REMARKS')),
                            ],
                            rows: provider.usage
                                .map(
                                  (row) => DataRow(
                                    cells: [
                                      DataCell(Text(row.itemName)),
                                      DataCell(
                                        Text(formatQty(row.quantityUsed)),
                                      ),
                                      DataCell(Text(formatDate(row.usageDate))),
                                      DataCell(Text(row.usedFor ?? '-')),
                                      DataCell(Text(row.remarks ?? '-')),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        if (provider.usage.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No spare usage records found.'),
                          ),
                      ],
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
