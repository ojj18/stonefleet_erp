import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_sidebar.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_shell.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<InventoryProvider>().loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InventoryShell(
      selectedIndex: 10,
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
                      title: 'Spare Inventory',
                      subtitle:
                          'Manage spare purchases, stock usage and inventory reports.',
                      action: ElevatedButton.icon(
                        onPressed: () => handleMenuTap(12, context: context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Upload Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00652C),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(145, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: InventoryKpiCard(
                            title: 'Total Spare Items',
                            value: '${provider.summary.totalItems}',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InventoryKpiCard(
                            title: 'Purchased Quantity',
                            value: formatQty(
                              provider.summary.purchasedQuantity,
                            ),
                            icon: Icons.add_shopping_cart_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InventoryKpiCard(
                            title: 'Used Quantity',
                            value: formatQty(provider.summary.usedQuantity),
                            icon: Icons.remove_shopping_cart_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InventoryKpiCard(
                            title: 'Remaining Stock',
                            value: formatQty(
                              provider.summary.remainingQuantity,
                            ),
                            icon: Icons.inventory_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InventoryKpiCard(
                            title: 'Total Purchase Cost',
                            value: formatMoney(provider.summary.purchaseCost),
                            icon: Icons.currency_rupee_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InventorySectionCard(
                      title: 'Recent Purchases',
                      icon: Icons.receipt_long_outlined,
                      child: provider.purchases.isEmpty
                          ? const _EmptyText(
                              text: 'No spare purchases recorded yet.',
                            )
                          : _PurchasePreview(
                              rows: provider.purchases.take(5).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),
                    InventorySectionCard(
                      title: 'Recent Spare Usage',
                      icon: Icons.build_circle_outlined,
                      child: provider.usage.isEmpty
                          ? const _EmptyText(
                              text: 'No spare usage recorded yet.',
                            )
                          : _UsagePreview(
                              rows: provider.usage.take(5).toList(),
                            ),
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        style: const TextStyle(color: Color(0xFFBA1A1A)),
                      ),
                    ],
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

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(text, style: const TextStyle(color: Color(0xFF8A9199))),
    ),
  );
}

class _PurchasePreview extends StatelessWidget {
  final List<dynamic> rows;
  const _PurchasePreview({required this.rows});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('DATE')),
        DataColumn(label: Text('BILL NUMBER')),
        DataColumn(label: Text('SUPPLIER')),
        DataColumn(label: Text('SPARE ITEM')),
        DataColumn(label: Text('QTY')),
        DataColumn(label: Text('TOTAL COST')),
      ],
      rows: rows
          .map(
            (row) => DataRow(
              cells: [
                DataCell(Text(formatDate(row.purchaseDate))),
                DataCell(Text(row.billNumber ?? '-')),
                DataCell(Text(row.supplierName ?? '-')),
                DataCell(Text(row.itemName)),
                DataCell(Text(formatQty(row.quantity))),
                DataCell(Text(formatMoney(row.totalCost))),
              ],
            ),
          )
          .toList(),
    ),
  );
}

class _UsagePreview extends StatelessWidget {
  final List<dynamic> rows;
  const _UsagePreview({required this.rows});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const [
        DataColumn(label: Text('DATE')),
        DataColumn(label: Text('SPARE ITEM')),
        DataColumn(label: Text('USED QTY')),
        DataColumn(label: Text('USED FOR')),
      ],
      rows: rows
          .map(
            (row) => DataRow(
              cells: [
                DataCell(Text(formatDate(row.usageDate))),
                DataCell(Text(row.itemName)),
                DataCell(Text(formatQty(row.quantityUsed))),
                DataCell(Text(row.usedFor ?? '-')),
              ],
            ),
          )
          .toList(),
    ),
  );
}
