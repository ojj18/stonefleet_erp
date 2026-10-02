import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/diesel_provider.dart';
import '../widgets/diesel_shell.dart';

class DieselConsumptionScreen extends StatefulWidget {
  const DieselConsumptionScreen({super.key});

  @override
  State<DieselConsumptionScreen> createState() =>
      _DieselConsumptionScreenState();
}

class _DieselConsumptionScreenState extends State<DieselConsumptionScreen> {
  String type = 'All';
  int? vehicleId;
  DateTimeRange range = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<DieselProvider>();
      await p.loadVehicles();
      await _load();
    });
  }

  Future<void> _load() {
    return context.read<DieselProvider>().loadConsumption(
      fromDate: range.start,
      toDate: range.end,
      vehicleType: type == 'All' ? null : type,
      vehicleId: vehicleId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 18,
      child: Consumer<DieselProvider>(
        builder: (context, p, _) {
          final totalLitres = p.consumption.fold<double>(
            0,
            (s, x) => s + x.quantityLitres,
          );
          final totalCost = p.consumption.fold<double>(
            0,
            (s, x) => s + x.totalCost,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DieselPageHeader(
                  title: 'Vehicle Consumption',
                  subtitle:
                      'Compare diesel consumption and cost vehicle by vehicle.',
                ),
                const SizedBox(height: 24),
                DieselCard(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final d = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDateRange: range,
                          );
                          if (d != null) {
                            setState(() => range = d);
                            await _load();
                          }
                        },
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          '${dieselDisplayDate(dieselDate(range.start))} - ${dieselDisplayDate(dieselDate(range.end))}',
                        ),
                      ),
                      DropdownButton<String>(
                        value: type,
                        items: const ['All', 'Excavator', 'Transport']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
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
                          hint: const Text('All Vehicles'),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All Vehicles'),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (_, c) {
                    final w = (c.maxWidth - 32) / 3;
                    return Row(
                      children: [
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: 'Vehicles',
                            value: '${p.consumption.length}',
                            subtitle: 'Selected period',
                            icon: Icons.directions_car_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: 'Diesel Used',
                            value: '${dieselQty(totalLitres)} L',
                            subtitle: 'Selected period',
                            icon: Icons.local_gas_station_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: 'Total Cost',
                            value: dieselMoney(totalCost),
                            subtitle: 'Selected period',
                            icon: Icons.currency_rupee_outlined,
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
                      const DieselSectionTitle(
                        title: 'Vehicle-wise Diesel Consumption',
                        icon: Icons.bar_chart_outlined,
                      ),
                      const SizedBox(height: 18),
                      if (p.consumption.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No diesel consumption recorded for this period.',
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Vehicle')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Diesel Used')),
                              DataColumn(label: Text('Total Cost')),
                              DataColumn(label: Text('Fillings')),
                            ],
                            rows: p.consumption
                                .map(
                                  (r) => DataRow(
                                    cells: [
                                      DataCell(Text(r.vehicleRegistration)),
                                      DataCell(Text(r.vehicleType)),
                                      DataCell(
                                        Text(
                                          '${dieselQty(r.quantityLitres)} L',
                                        ),
                                      ),
                                      DataCell(Text(dieselMoney(r.totalCost))),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
