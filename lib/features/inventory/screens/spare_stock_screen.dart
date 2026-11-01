import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../widgets/inventory_shell.dart';

FormFieldValidator<T>? _allowEmptyFieldValidator<T>(
  FormFieldValidator<T>? validator,
) {
  if (validator == null) return null;
  return (value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return null;
    }
    return validator(value);
  };
}


class SpareStockScreen extends StatefulWidget {
  const SpareStockScreen({super.key});
  @override
  State<SpareStockScreen> createState() => _SpareStockScreenState();
}

class _SpareStockScreenState extends State<SpareStockScreen> {
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<InventoryProvider>().loadStock(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _viewStock(dynamic row) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalization.t('Stock Item Details')),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detail(AppLocalization.t('Spare Item'), row.itemName),
              _detail(AppLocalization.t('Unit'), row.unit ?? '-'),
              _detail(AppLocalization.t('Purchased'), formatQty(row.purchased)),
              _detail(AppLocalization.t('Used'), formatQty(row.used)),
              _detail(AppLocalization.t('Remaining'), formatQty(row.remaining)),
              _detail(
                AppLocalization.t('Last Purchase'),
                formatDate(row.lastPurchaseDate),
              ),
              _detail(
                AppLocalization.t('Status'),
                row.remaining <= 0
                    ? AppLocalization.t('Out of Stock')
                    : (row.purchased > 0 && row.remaining / row.purchased <= .2
                          ? AppLocalization.t('Low Stock')
                          : AppLocalization.t('In Stock')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalization.t('Close')),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(color: Color(0xFF657166))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Future<void> _editStock(InventoryProvider provider, dynamic row) async {
    final name = TextEditingController(text: row.itemName);
    final unit = TextEditingController(text: row.unit ?? '');
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalization.t('Edit Spare Item')),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: AppLocalization.t('Spare Item'),
                  ),
                  validator: _allowEmptyFieldValidator(((v) => (v ?? '').trim().isEmpty
                      ? AppLocalization.t('Required')
                      : null)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unit,
                  decoration: InputDecoration(
                    labelText: AppLocalization.t('Unit (Optional)'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(AppLocalization.t('Update')),
          ),
        ],
      ),
    );
    if (saved == true) {
      await provider.updateStockItem(
        itemId: row.itemId,
        itemName: name.text,
        unit: unit.text,
      );
      if (provider.error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
      }
    }
    name.dispose();
    unit.dispose();
  }

  Future<void> _deleteStock(InventoryProvider provider, dynamic row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalization.t('Delete spare item?')),
        content: Text(
          AppLocalization.t(
            'Only items without purchase or usage history can be deleted. Existing stock history will be preserved.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.deleteStockItem(row.itemId);
    if (provider.error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InventoryShell(
      selectedIndex: 11,
      child: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InventoryPageHeader(
                      title: AppLocalization.t('Spare Stock'),
                      subtitle: AppLocalization.t(
                        'Track purchased, used and remaining quantities for each spare.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: InventoryKpiCard(
                            title: AppLocalization.t('Total Items'),
                            value: '${provider.summary.totalItems}',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InventoryKpiCard(
                            title: AppLocalization.t('Purchased Qty'),
                            value: formatQty(
                              provider.summary.purchasedQuantity,
                            ),
                            icon: Icons.add_shopping_cart_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InventoryKpiCard(
                            title: AppLocalization.t('Used Qty'),
                            value: formatQty(provider.summary.usedQuantity),
                            icon: Icons.remove_shopping_cart_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InventoryKpiCard(
                            title: AppLocalization.t('Remaining'),
                            value: formatQty(
                              provider.summary.remainingQuantity,
                            ),
                            icon: Icons.inventory_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InventorySectionCard(
                      title: AppLocalization.t('Current Stock'),
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _search,
                                  onChanged: (v) =>
                                      provider.loadStock(search: v),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: AppLocalization.t(
                                      'Search spare item...',
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  _search.clear();
                                  provider.loadStock();
                                },
                                child: Text(AppLocalization.t('Clear')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 28,
                              horizontalMargin: 16,
                              headingRowHeight: 48,
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 76,
                              columns: [
                                DataColumn(
                                  label: Text(AppLocalization.t('SPARE ITEM')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('UNIT')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('PURCHASED')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('USED')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('REMAINING')),
                                ),
                                DataColumn(
                                  label: Text(
                                    AppLocalization.t('LAST PURCHASE'),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('STATUS')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('ACTIONS')),
                                ),
                              ],
                              rows: provider.stock.map((row) {
                                final status = row.remaining <= 0
                                    ? 'Out of Stock'
                                    : (row.purchased > 0 &&
                                              row.remaining / row.purchased <=
                                                  .2
                                          ? 'Low Stock'
                                          : 'In Stock');
                                return DataRow(
                                  cells: [
                                    DataCell(Text(row.itemName)),
                                    DataCell(Text(row.unit ?? '-')),
                                    DataCell(Text(formatQty(row.purchased))),
                                    DataCell(Text(formatQty(row.used))),
                                    DataCell(
                                      Text(
                                        formatQty(row.remaining),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(formatDate(row.lastPurchaseDate)),
                                    ),
                                    DataCell(
                                      Text(
                                        status,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: status == 'In Stock'
                                              ? const Color(0xFF00652C)
                                              : const Color(0xFFBA1A1A),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: AppLocalization.t('View'),
                                            onPressed: () => _viewStock(row),
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: AppLocalization.t('Edit'),
                                            onPressed: () =>
                                                _editStock(provider, row),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: AppLocalization.t(
                                              'Delete',
                                            ),
                                            onPressed: () =>
                                                _deleteStock(provider, row),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFBA1A1A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          if (provider.stock.isEmpty)
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                AppLocalization.t(
                                  'No inventory stock records found.',
                                ),
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
        },
      ),
    );
  }
}
