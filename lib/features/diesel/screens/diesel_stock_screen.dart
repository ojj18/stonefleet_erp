import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselStockScreen extends StatefulWidget {
  const DieselStockScreen({super.key});

  @override
  State<DieselStockScreen> createState() => _DieselStockScreenState();
}

class _DieselStockScreenState extends State<DieselStockScreen> {
  final _qty = TextEditingController();
  final _rate = TextEditingController();
  final _source = TextEditingController(text: 'Diesel Lorry');
  final _supplier = TextEditingController();
  final _bill = TextEditingController();
  final _remarks = TextEditingController();
  DateTime date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DieselProvider>().loadStock();
    });
  }

  @override
  void dispose() {
    for (final c in [_qty, _rate, _source, _supplier, _bill, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addReceipt() async {
    final qty = double.tryParse(_qty.text.trim());
    final rate = double.tryParse(_rate.text.trim());
    if (qty == null || qty <= 0 || rate == null || rate < 0 || _source.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid source, quantity and rate.')),
      );
      return;
    }

    final p = context.read<DieselProvider>();
    await p.addReceipt(
      receiptDate: dieselDate(date),
      sourceName: _source.text,
      quantityLitres: qty,
      rate: rate,
      supplierName: _supplier.text,
      billNumber: _bill.text,
      remarks: _remarks.text,
    );

    if (!mounted) return;
    if (p.error == null) {
      _qty.clear();
      _rate.clear();
      _supplier.clear();
      _bill.clear();
      _remarks.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diesel receipt added and stock updated.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 17,
      child: Consumer<DieselProvider>(
        builder: (context, p, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DieselPageHeader(
                title: 'Diesel Stock',
                subtitle: 'Track diesel received, used and current balance.',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (_, c) {
                  final w = (c.maxWidth - 48) / 4;
                  final s = p.summary;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(width: w, child: DieselKpiCard(title: 'Opening Stock', value: '${dieselQty(s.openingStock)} L', subtitle: 'Selected period', icon: Icons.inventory_2_outlined)),
                      SizedBox(width: w, child: DieselKpiCard(title: 'Diesel Received', value: '${dieselQty(s.received)} L', subtitle: 'Selected period', icon: Icons.south_west_outlined)),
                      SizedBox(width: w, child: DieselKpiCard(title: 'Diesel Used', value: '${dieselQty(s.used)} L', subtitle: 'Selected period', icon: Icons.outbound_outlined)),
                      SizedBox(width: w, child: DieselKpiCard(title: 'Current Stock', value: '${dieselQty(s.currentStock)} L', subtitle: 'Live balance', icon: Icons.local_gas_station_outlined)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              DieselCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DieselSectionTitle(title: 'Add Diesel Receipt', icon: Icons.add_circle_outline),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (_, c) {
                        final w = (c.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(width: w, child: _dateField()),
                            SizedBox(width: w, child: _text(_source, 'Diesel Lorry / Source')),
                            SizedBox(width: w, child: _text(_qty, 'Quantity (Litres)', decimal: true)),
                            SizedBox(width: w, child: _text(_rate, 'Diesel Rate', decimal: true)),
                            SizedBox(width: w, child: _text(_supplier, 'Supplier (Optional)')),
                            SizedBox(width: w, child: _text(_bill, 'Bill Number (Optional)')),
                            SizedBox(width: c.maxWidth, child: _text(_remarks, 'Remarks (Optional)', maxLines: 2)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.icon(
                          onPressed: p.isLoading ? null : _addReceipt,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Receipt'),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00652C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DieselCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DieselSectionTitle(title: 'Stock Movement', icon: Icons.swap_vert_outlined),
                    const SizedBox(height: 16),
                    if (p.movements.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No stock movements recorded yet.')))
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Transaction')),
                            DataColumn(label: Text('Quantity')),
                            DataColumn(label: Text('Previous Stock')),
                            DataColumn(label: Text('Current Stock')),
                            DataColumn(label: Text('Remarks')),
                          ],
                          rows: p.movements.map((m) => DataRow(cells: [
                            DataCell(Text(dieselDisplayDate(m.transactionDate))),
                            DataCell(Text(m.transactionType == 'RECEIPT' ? 'Diesel Received' : 'Diesel Filled')),
                            DataCell(Text('${m.transactionType == 'FILLING' ? '-' : '+'}${dieselQty(m.quantity)} L')),
                            DataCell(Text('${dieselQty(m.previousStock)} L')),
                            DataCell(Text('${dieselQty(m.currentStock)} L')),
                            DataCell(Text(m.remarks ?? '-')),
                          ])).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField() => InkWell(
    onTap: () async {
      final d = await pickDieselDate(context, date);
      if (d != null) setState(() => date = d);
    },
    child: InputDecorator(
      decoration: const InputDecoration(labelText: 'Receipt Date', prefixIcon: Icon(Icons.calendar_today_outlined)),
      child: Text(dieselDisplayDate(dieselDate(date))),
    ),
  );

  Widget _text(TextEditingController c, String label, {bool decimal = false, int maxLines = 1}) =>
      TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      );
}
