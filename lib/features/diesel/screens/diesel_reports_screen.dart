import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../data/services/diesel_excel_service.dart';
import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselReportsScreen extends StatefulWidget {
  const DieselReportsScreen({super.key});

  @override
  State<DieselReportsScreen> createState() => _DieselReportsScreenState();
}

class _DieselReportsScreenState extends State<DieselReportsScreen> {
  String period = 'Monthly';
  DateTimeRange range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );
  String type = 'All';
  int? vehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<DieselProvider>().loadVehicles();
      await _load();
    });
  }

  Future<void> _load() {
    return context.read<DieselProvider>().loadReport(
      fromDate: range.start,
      toDate: range.end,
      vehicleType: type == 'All' ? null : type,
      vehicleId: vehicleId,
    );
  }

  Future<void> _setPeriod(String value) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    if (value == 'Daily') {
      start = today;
    } else if (value == 'Weekly') {
      start = today.subtract(Duration(days: today.weekday - 1));
    } else {
      start = DateTime(today.year, today.month, 1);
    }
    setState(() {
      period = value;
      range = DateTimeRange(start: start, end: today);
    });
    await _load();
  }

  Future<void> _export() async {
    final p = context.read<DieselProvider>();
    if (p.reportRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('No records available for export.')),
        ),
      );
      return;
    }
    try {
      final path = await DieselExcelService().exportReport(
        rows: p.reportRows,
        fromDate: range.start,
        toDate: range.end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.t('Excel report saved: ') + path)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalization.t('Export failed: ') + e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 19,
      child: Consumer<DieselProvider>(
        builder: (context, p, _) {
          final litres = p.reportRows.fold<double>(0, (s, r) => s + r.litres);
          final cost = p.reportRows.fold<double>(0, (s, r) => s + r.cost);
          final averageRate = litres == 0 ? 0 : cost / litres;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DieselPageHeader(
                  title: AppLocalization.t('Diesel Reports'),
                  subtitle:
                      AppLocalization.t('Generate daily, weekly, monthly and custom diesel reports.'),
                  action: FilledButton.icon(
                    onPressed: p.isLoading ? null : _export,
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(AppLocalization.t('Export Excel')),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00652C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DieselCard(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      DropdownButton<String>(
                        value: period,
                        items: const ['Daily', 'Weekly', 'Monthly', 'Custom']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(AppLocalization.t(e))),
                            )
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          if (v == 'Custom') {
                            final d = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDateRange: range,
                            );
                            if (d != null) {
                              setState(() {
                                period = 'Custom';
                                range = d;
                              });
                              await _load();
                            }
                          } else {
                            await _setPeriod(v);
                          }
                        },
                      ),
                      DropdownButton<String>(
                        value: type,
                        items: const ['All', 'Excavator', 'Transport']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(AppLocalization.t(e))),
                            )
                            .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() {
                            type = v;
                            vehicleId = null;
                          });
                          await _load();
                        },
                      ),
                      if (type != 'All')
                        DropdownButton<int?>(
                          value: vehicleId,
                          hint: Text(AppLocalization.t('All Vehicles')),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(AppLocalization.t('All Vehicles')),
                            ),
                            ...p.vehicles
                                .where((v) => v.type == type)
                                .map(
                                  (v) => DropdownMenuItem<int?>(
                                    value: v.id,
                                    child: Text(v.registrationNumber),
                                  ),
                                ),
                          ],
                          onChanged: (v) async {
                            setState(() => vehicleId = v);
                            await _load();
                          },
                        ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange: range,
                          );
                          if (d != null) {
                            setState(() {
                              period = 'Custom';
                              range = d;
                            });
                            await _load();
                          }
                        },
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          '${dieselDisplayDate(dieselDate(range.start))} - ${dieselDisplayDate(dieselDate(range.end))}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (_, c) {
                    final w = (c.maxWidth - 48) / 4;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: AppLocalization.t('Diesel Received'),
                            value: '${dieselQty(p.summary.received)} L',
                            subtitle: period,
                            icon: Icons.south_west_outlined,
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: AppLocalization.t('Diesel Used'),
                            value: '${dieselQty(litres)} L',
                            subtitle: period,
                            icon: Icons.outbound_outlined,
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: AppLocalization.t('Total Cost'),
                            value: dieselMoney(cost),
                            subtitle: period,
                            icon: Icons.currency_rupee_outlined,
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: AppLocalization.t('Average Rate'),
                            value: dieselMoney(averageRate.toDouble()),
                            subtitle: AppLocalization.t('Per litre'),
                            icon: Icons.calculate_outlined,
                          ),
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
                        title: AppLocalization.t('Diesel Filling Report'),
                        icon: Icons.assessment_outlined,
                      ),
                      const SizedBox(height: 16),
                      if (p.reportRows.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              AppLocalization.t(
                                'No records found for the selected filters.',
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
                            rows: p.reportRows
                                .map(
                                  (r) => DataRow(
                                    cells: [
                                      DataCell(Text(dieselDisplayDate(r.date))),
                                      DataCell(Text(r.vehicleRegistration)),
                                      DataCell(Text(AppLocalization.t(r.vehicleType))),
                                      DataCell(
                                        Text('${dieselQty(r.litres)} L'),
                                      ),
                                      DataCell(Text(dieselMoney(r.rate))),
                                      DataCell(Text(dieselMoney(r.cost))),
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
          );
        },
      ),
    );
  }
}
