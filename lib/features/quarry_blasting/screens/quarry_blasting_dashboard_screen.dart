import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quarry_blasting_provider.dart';
import '../widgets/quarry_blasting_shell.dart';
import 'quarry_blasting_new_purchase_screen.dart';
import 'quarry_blasting_purchase_history_screen.dart';

class QuarryBlastingDashboardScreen extends StatefulWidget {
  const QuarryBlastingDashboardScreen({super.key});

  @override
  State<QuarryBlastingDashboardScreen> createState() => _QuarryBlastingDashboardScreenState();
}

class _QuarryBlastingDashboardScreenState extends State<QuarryBlastingDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<QuarryBlastingProvider>().loadDashboard();
    });
  }

  Future<void> _openNewPurchase() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuarryBlastingNewPurchaseScreen()),
    );
    if (mounted) context.read<QuarryBlastingProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return QuarryBlastingShell(
      selectedIndex: 15,
      child: Consumer<QuarryBlastingProvider>(
        builder: (context, provider, _) {
          final summary = provider.summary;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuarryPageHeader(
                      title: 'Quarry Blasting Purchase',
                      subtitle: 'Track blasting material purchases and purchase costs.',
                      action: FilledButton.icon(
                        onPressed: _openNewPurchase,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('New Purchase'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00652C),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: QuarryKpiCard(title: 'Total Purchases', value: '${summary.purchaseCount}', icon: Icons.receipt_long_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: QuarryKpiCard(title: 'Bullet Quantity', value: formatQty(summary.bulletQuantity), icon: Icons.inventory_2_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: QuarryKpiCard(title: 'Total Wire Quantity', value: formatQty(summary.wire3mQuantity + summary.wire4mQuantity), icon: Icons.cable_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: QuarryKpiCard(title: 'Total Purchase Cost', value: formatMoney(summary.totalCost), icon: Icons.currency_rupee_outlined)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    QuarryCard(
                      title: 'Purchase Cost Summary',
                      icon: Icons.account_balance_wallet_outlined,
                      child: Row(
                        children: [
                          Expanded(child: _costTile('Bullet', summary.bulletCost)),
                          const SizedBox(width: 12),
                          Expanded(child: _costTile('3m Wire', summary.wire3mCost)),
                          const SizedBox(width: 12),
                          Expanded(child: _costTile('4m Wire', summary.wire4mCost)),
                          const SizedBox(width: 12),
                          Expanded(child: _costTile('ED', summary.edCost)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    QuarryCard(
                      title: 'Recent Purchase History',
                      icon: Icons.history_outlined,
                      child: provider.purchases.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Center(child: Text('No blasting material purchases recorded yet.')),
                            )
                          : Column(
                              children: [
                                _historyTable(provider.purchases.take(8).toList()),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const QuarryBlastingPurchaseHistoryScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_forward, size: 17),
                                    label: const Text('View Purchase History'),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (provider.error != null) ...[
                      const SizedBox(height: 12),
                      Text(provider.error!, style: const TextStyle(color: Color(0xFFB3261E))),
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

  Widget _costTile(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE1E5E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF68717D))),
          const SizedBox(height: 6),
          Text(formatMoney(value), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _historyTable(List purchases) {
    return SingleChildScrollView(
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
        rows: purchases.map<DataRow>((p) => DataRow(cells: [
          DataCell(Text(formatDate(p.purchaseDate))),
          DataCell(Text(formatQty(p.bulletQuantity))),
          DataCell(Text(formatQty(p.wire3mQuantity))),
          DataCell(Text(formatQty(p.wire4mQuantity))),
          DataCell(Text(formatQty(p.edQuantity))),
          DataCell(Text(formatMoney(p.totalCost), style: const TextStyle(fontWeight: FontWeight.w700))),
        ])).toList(),
      ),
    );
  }
}
