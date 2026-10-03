import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../providers/inventory_provider.dart';
import '../widgets/inventory_shell.dart';

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
                      subtitle:
                          AppLocalization.t('Track purchased, used and remaining quantities for each spare.'),
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
                                    hintText: AppLocalization.t('Search spare item...'),
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
