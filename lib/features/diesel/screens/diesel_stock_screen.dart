import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import '../../../data/models/diesel_models.dart';
import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselStockScreen extends StatefulWidget {
  const DieselStockScreen({super.key});
  @override
  State<DieselStockScreen> createState() => _DieselStockScreenState();
}

class _DieselStockScreenState extends State<DieselStockScreen> {
  int page = 0, rowsPerPage = 10;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DieselProvider>().loadStock(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 20,
      child: Consumer<DieselProvider>(
        builder: (context, p, _) {
          final start = page * rowsPerPage;
          final end = (start + rowsPerPage).clamp(0, p.movements.length);
          final rows = p.movements.sublist(start, end);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DieselPageHeader(
                  title: AppLocalization.t('Diesel Stock'),
                  subtitle: AppLocalization.t(
                    'Track diesel received, used and current balance.',
                  ),
                  action: FilledButton.icon(
                    onPressed: () => _receiptForm(),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalization.t('Add Diesel Receipt')),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00652C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (_, c) {
                    final w = c.maxWidth < 800
                        ? c.maxWidth
                        : (c.maxWidth - 48) / 4;
                    final s = p.summary;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _k(
                          w,
                          'Opening Stock',
                          '${dieselQty(s.openingStock)} L',
                        ),
                        _k(w, 'Diesel Received', '${dieselQty(s.received)} L'),
                        _k(w, 'Diesel Used', '${dieselQty(s.used)} L'),
                        _k(
                          w,
                          'Current Stock',
                          '${dieselQty(s.currentStock)} L',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                DieselCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DieselSectionTitle(
                        title: AppLocalization.t('Diesel Receipts'),
                        icon: Icons.receipt_long_outlined,
                      ),
                      const SizedBox(height: 12),
                      if (p.receipts.isEmpty)
                        Text(
                          AppLocalization.t('No diesel receipts recorded yet.'),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Text(AppLocalization.t('Date')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Source')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Quantity')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Rate')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Total Cost')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('ACTION')),
                              ),
                            ],
                            rows: p.receipts
                                .map(
                                  (r) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(dieselDisplayDate(r.receiptDate)),
                                      ),
                                      DataCell(Text(r.sourceName)),
                                      DataCell(
                                        Text(
                                          '${dieselQty(r.quantityLitres)} L',
                                        ),
                                      ),
                                      DataCell(Text(dieselMoney(r.rate))),
                                      DataCell(Text(dieselMoney(r.totalCost))),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              tooltip: AppLocalization.t(
                                                'View',
                                              ),
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () => _viewReceipt(r),
                                            ),
                                            IconButton(
                                              tooltip: AppLocalization.t(
                                                'Edit',
                                              ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _receiptForm(existing: r),
                                            ),
                                            IconButton(
                                              tooltip: AppLocalization.t(
                                                'Delete',
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _deleteReceipt(r),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                DieselCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DieselSectionTitle(
                        title: AppLocalization.t('Stock Movement'),
                        icon: Icons.swap_vert_outlined,
                      ),
                      const SizedBox(height: 12),
                      if (rows.isEmpty)
                        Text(
                          AppLocalization.t('No stock movements recorded yet.'),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Text(AppLocalization.t('Date')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Transaction')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Quantity')),
                              ),
                              DataColumn(
                                label: Text(
                                  AppLocalization.t('Previous Stock'),
                                ),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Current Stock')),
                              ),
                              DataColumn(
                                label: Text(AppLocalization.t('Remarks')),
                              ),
                            ],
                            rows: rows
                                .map(
                                  (m) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          dieselDisplayDate(m.transactionDate),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          m.transactionType == 'RECEIPT'
                                              ? AppLocalization.t(
                                                  'Diesel Received',
                                                )
                                              : AppLocalization.t(
                                                  'Diesel Filled',
                                                ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${m.transactionType == 'FILLING' ? '-' : '+'}${dieselQty(m.quantity)} L',
                                        ),
                                      ),
                                      DataCell(
                                        Text('${dieselQty(m.previousStock)} L'),
                                      ),
                                      DataCell(
                                        Text('${dieselQty(m.currentStock)} L'),
                                      ),
                                      DataCell(Text(m.remarks ?? '-')),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      if (p.movements.isNotEmpty)
                        _Pager(
                          total: p.movements.length,
                          page: page,
                          rowsPerPage: rowsPerPage,
                          onPage: (v) => setState(() => page = v),
                          onRows: (v) => setState(() {
                            rowsPerPage = v;
                            page = 0;
                          }),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _k(double w, String t, String v) => SizedBox(
    width: w,
    child: DieselKpiCard(
      title: AppLocalization.t(t),
      value: v,
      subtitle: AppLocalization.t('Selected period'),
      icon: Icons.local_gas_station_outlined,
    ),
  );
  Future<void> _receiptForm({DieselReceiptRow? existing}) async {
    final p = context.read<DieselProvider>();
    await showDialog(
      context: context,
      builder: (_) => _ReceiptDialog(provider: p, existing: existing),
    );
    if (mounted) await p.loadStock();
  }

  Future<void> _deleteReceipt(DieselReceiptRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalization.t('Delete Diesel Receipt?')),
        content: Text(
          AppLocalization.t(
            'This diesel receipt record will be permanently deleted.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<DieselProvider>().deleteReceipt(r.id);
    }
  }

  void _viewReceipt(DieselReceiptRow r) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(AppLocalization.t('Diesel Receipt Details')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _d('Date', dieselDisplayDate(r.receiptDate)),
          _d('Source', r.sourceName),
          _d('Quantity', '${dieselQty(r.quantityLitres)} L'),
          _d('Rate', dieselMoney(r.rate)),
          _d('Total Cost', dieselMoney(r.totalCost)),
          _d('Supplier', r.supplierName ?? '-'),
          _d('Bill Number', r.billNumber ?? '-'),
          _d('Remarks', r.remarks ?? '-'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalization.t('Close')),
        ),
      ],
    ),
  );
  Widget _d(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            AppLocalization.t(k),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );
}

class _ReceiptDialog extends StatefulWidget {
  final DieselProvider provider;
  final DieselReceiptRow? existing;
  const _ReceiptDialog({required this.provider, this.existing});
  @override
  State<_ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<_ReceiptDialog> {
  final key = GlobalKey<FormState>();
  late DateTime date;
  late TextEditingController source, qty, rate, supplier, bill, remarks;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    date = e == null
        ? DateTime.now()
        : DateTime.tryParse(e.receiptDate) ?? DateTime.now();
    source = TextEditingController(text: e?.sourceName ?? '');
    qty = TextEditingController(
      text: e == null ? '' : e.quantityLitres.toString(),
    );
    rate = TextEditingController(text: e == null ? '' : e.rate.toString());
    supplier = TextEditingController(text: e?.supplierName ?? '');
    bill = TextEditingController(text: e?.billNumber ?? '');
    remarks = TextEditingController(text: e?.remarks ?? '');
  }

  @override
  void dispose() {
    for (final c in [source, qty, rate, supplier, bill, remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    try {
      if (widget.existing == null) {
        await widget.provider.addReceipt(
          receiptDate: dieselDate(date),
          sourceName: source.text,
          quantityLitres: double.parse(qty.text),
          rate: double.parse(rate.text),
          supplierName: supplier.text,
          billNumber: bill.text,
          remarks: remarks.text,
        );
      } else {
        await widget.provider.updateReceipt(
          id: widget.existing!.id,
          receiptDate: dieselDate(date),
          sourceName: source.text,
          quantityLitres: double.parse(qty.text),
          rate: double.parse(rate.text),
          supplierName: supplier.text,
          billNumber: bill.text,
          remarks: remarks.text,
        );
      }
      if (widget.provider.error != null) throw Exception(widget.provider.error);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.t(e.toString().replaceFirst('Exception: ', '')),
            ),
          ),
        );
      }
    }
  }

  Widget _f(
    TextEditingController controller,
    String label, [
    bool isNumeric = false,
    int maxLines = 1,
  ]) {
    final isOptional = label.toLowerCase().contains('optional');
    return SizedBox(
      width: maxLines > 1 ? 600 : 292,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: AppLocalization.t(label)),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (isOptional || text.isNotEmpty) {
            if (isNumeric && text.isNotEmpty && double.tryParse(text) == null) {
              return AppLocalization.t('Enter a valid number');
            }
            return null;
          }
          return AppLocalization.t('This field is required');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      AppLocalization.t(
        widget.existing == null ? 'Add Diesel Receipt' : 'Edit Diesel Receipt',
      ),
    ),
    content: SizedBox(
      width: 620,
      child: Form(
        key: key,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 292,
              child: InkWell(
                onTap: () async {
                  final d = await pickDieselDate(context, date);
                  if (d != null) setState(() => date = d);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalization.t('Receipt Date'),
                  ),
                  child: Text(dieselDisplayDate(dieselDate(date))),
                ),
              ),
            ),
            _f(source, 'Diesel Lorry / Source'),
            _f(qty, 'Quantity (Litres)', true),
            _f(rate, 'Diesel Rate', true),
            _f(supplier, 'Supplier (Optional)'),
            _f(bill, 'Bill Number (Optional)'),
            SizedBox(
              width: 600,
              child: _f(remarks, 'Remarks (Optional)', false, 2),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalization.t('Cancel')),
      ),
      FilledButton.icon(
        onPressed: save,
        icon: const Icon(Icons.save_outlined),
        label: Text(
          AppLocalization.t(
            widget.existing == null ? 'Add Receipt' : 'Update Receipt',
          ),
        ),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00652C)),
      ),
    ],
  );
}

class _Pager extends StatelessWidget {
  final int total, page, rowsPerPage;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onRows;
  const _Pager({
    required this.total,
    required this.page,
    required this.rowsPerPage,
    required this.onPage,
    required this.onRows,
  });
  @override
  Widget build(BuildContext context) {
    final pages = (total / rowsPerPage).ceil();
    final from = page * rowsPerPage + 1;
    final to = ((page + 1) * rowsPerPage > total)
        ? total
        : (page + 1) * rowsPerPage;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Text('${AppLocalization.t('Rows per page')}: '),
          DropdownButton<int>(
            value: rowsPerPage,
            items: const [10, 25, 50, 100]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                .toList(),
            onChanged: (v) {
              if (v != null) onRows(v);
            },
          ),
          const Spacer(),
          Text(
            '${AppLocalization.t('Showing')} $from-$to ${AppLocalization.t('of')} $total',
          ),
          IconButton(
            onPressed: page > 0 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${page + 1} / ${pages == 0 ? 1 : pages}'),
          IconButton(
            onPressed: page < pages - 1 ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
