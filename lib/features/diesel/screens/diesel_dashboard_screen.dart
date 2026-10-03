import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselDashboardScreen extends StatefulWidget {
  const DieselDashboardScreen({super.key});

  @override
  State<DieselDashboardScreen> createState() => _DieselDashboardScreenState();
}

class _DieselDashboardScreenState extends State<DieselDashboardScreen> {
  String period = 'Today';

  DateTimeRange _rangeFor(String value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (value == 'This Week') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(start: start, end: today);
    }
    if (value == 'This Month') {
      return DateTimeRange(
        start: DateTime(today.year, today.month, 1),
        end: today,
      );
    }
    return DateTimeRange(start: today, end: today);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final range = _rangeFor(period);
    await context.read<DieselProvider>().loadDashboard(
      fromDate: range.start,
      toDate: range.end,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 15,
      child: Consumer<DieselProvider>(
        builder: (context, provider, _) {
          final s = provider.summary;
          return RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DieselPageHeader(
                    title: AppLocalization.t('Diesel Management'),
                    subtitle:
                        AppLocalization.t('Track diesel stock, vehicle consumption and fuel expenses.'),
                    action: DropdownButton<String>(
                      value: period,
                      items: const ['Today', 'This Week', 'This Month']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(AppLocalization.t(e))),
                          )
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => period = v);
                        await _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (provider.error != null)
                    _ErrorBanner(message: AppLocalization.t(provider.error!)),
                  LayoutBuilder(
                    builder: (_, c) {
                      final cols = c.maxWidth >= 1100
                          ? 4
                          : c.maxWidth >= 700
                          ? 2
                          : 1;
                      final gap = 16.0;
                      final w = (c.maxWidth - gap * (cols - 1)) / cols;
                      final cards = [
                        DieselKpiCard(
                          title: AppLocalization.t('Available Diesel'),
                          value: '${dieselQty(s.currentStock)} L',
                          subtitle: AppLocalization.t('Current stock'),
                          icon: Icons.local_gas_station_outlined,
                        ),
                        DieselKpiCard(
                          title: AppLocalization.t('Diesel Used'),
                          value: '${dieselQty(s.used)} L',
                          subtitle: period,
                          icon: Icons.outbound_outlined,
                        ),
                        DieselKpiCard(
                          title: AppLocalization.t('Diesel Received'),
                          value: '${dieselQty(s.received)} L',
                          subtitle: period,
                          icon: Icons.south_west_outlined,
                        ),
                        DieselKpiCard(
                          title: AppLocalization.t('Total Diesel Cost'),
                          value: dieselMoney(s.totalCost),
                          subtitle: period,
                          icon: Icons.currency_rupee_outlined,
                        ),
                      ];
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: cards
                            .map((x) => SizedBox(width: w, child: x))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  DieselCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DieselSectionTitle(
                          title: AppLocalization.t('Diesel Stock Summary'),
                          icon: Icons.storage_outlined,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _StockValue(
                                'Opening Stock',
                                '${dieselQty(s.openingStock)} L',
                              ),
                            ),
                            const Icon(Icons.add, color: Color(0xFF68717D)),
                            Expanded(
                              child: _StockValue(
                                'Received',
                                '+ ${dieselQty(s.received)} L',
                              ),
                            ),
                            const Icon(Icons.remove, color: Color(0xFF68717D)),
                            Expanded(
                              child: _StockValue(
                                'Used',
                                '- ${dieselQty(s.used)} L',
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF68717D),
                            ),
                            Expanded(
                              child: _StockValue(
                                'Current Stock',
                                '${dieselQty(s.currentStock)} L',
                                strong: true,
                              ),
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
                        DieselSectionTitle(
                          title: AppLocalization.t(
                            'Vehicle-wise Diesel Consumption',
                          ),
                          icon: Icons.bar_chart_outlined,
                        ),
                        const SizedBox(height: 18),
                        if (provider.consumption.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                AppLocalization.t(
                                  'No vehicle consumption recorded for this period.',
                                ),
                              ),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(
                                  label: Text(AppLocalization.t('Vehicle')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Type')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Diesel Used')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Total Cost')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Fillings')),
                                ),
                              ],
                              rows: provider.consumption
                                  .take(10)
                                  .map(
                                    (r) => DataRow(
                                      cells: [
                                        DataCell(Text(r.vehicleRegistration)),
                                        DataCell(Text(AppLocalization.t(r.vehicleType))),
                                        DataCell(
                                          Text(
                                            '${dieselQty(r.quantityLitres)} L',
                                          ),
                                        ),
                                        DataCell(
                                          Text(dieselMoney(r.totalCost)),
                                        ),
                                        DataCell(Text('${r.fillingCount}')),
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
                          title: AppLocalization.t('Recent Diesel Filling'),
                          icon: Icons.receipt_long_outlined,
                        ),
                        const SizedBox(height: 18),
                        if (provider.fillings.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                AppLocalization.t(
                                  'No diesel filling recorded for this period.',
                                ),
                              ),
                            ),
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
                                  label: Text(AppLocalization.t('Vehicle')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Type')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Diesel')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Rate')),
                                ),
                                DataColumn(
                                  label: Text(AppLocalization.t('Cost')),
                                ),
                              ],
                              rows: provider.fillings
                                  .take(10)
                                  .map(
                                    (r) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            dieselDisplayDate(r.fillingDate),
                                          ),
                                        ),
                                        DataCell(Text(r.vehicleRegistration)),
                                        DataCell(Text(AppLocalization.t(r.vehicleType))),
                                        DataCell(
                                          Text(
                                            '${dieselQty(r.quantityLitres)} L',
                                          ),
                                        ),
                                        DataCell(Text(dieselMoney(r.rate))),
                                        DataCell(
                                          Text(dieselMoney(r.totalCost)),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StockValue extends StatelessWidget {
  final String title;
  final String value;
  final bool strong;
  const _StockValue(this.title, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 12, color: Color(0xFF68717D)),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 20 : 17,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEEE),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFF2C4C4)),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFFBA1A1A))),
  );
}
