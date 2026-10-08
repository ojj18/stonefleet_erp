import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
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
  int page = 0;
  int rowsPerPage = 10;
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
    setState(() => page = 0);
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
      selectedIndex: 22,
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

          final start = page * rowsPerPage;
          final end = (start + rowsPerPage).clamp(0, p.consumption.length);
          final visibleRows = p.consumption.sublist(start, end);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DieselPageHeader(
                  title: AppLocalization.t('Vehicle Consumption'),
                  subtitle:
                      AppLocalization.t('Compare diesel consumption and cost vehicle by vehicle.'),
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
                            title: AppLocalization.t('Vehicles'),
                            value: '${p.consumption.length}',
                            subtitle: AppLocalization.t('Selected period'),
                            icon: Icons.directions_car_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: AppLocalization.t('Diesel Used'),
                            value: '${dieselQty(totalLitres)} L',
                            subtitle: AppLocalization.t('Selected period'),
                            icon: Icons.local_gas_station_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: w,
                          child: DieselKpiCard(
                            title: AppLocalization.t('Total Cost'),
                            value: dieselMoney(totalCost),
                            subtitle: AppLocalization.t('Selected period'),
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
                      DieselSectionTitle(
                        title: AppLocalization.t(
                          'Vehicle-wise Diesel Consumption',
                        ),
                        icon: Icons.bar_chart_outlined,
                      ),
                      const SizedBox(height: 18),
                      if (p.consumption.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              AppLocalization.t(
                                'No diesel consumption recorded for this period.',
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
                            rows: visibleRows
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
                                      DataCell(Text(dieselMoney(r.totalCost))),
                                      DataCell(Text('${r.fillingCount}')),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      if (p.consumption.isNotEmpty)
                        _Pager(total: p.consumption.length, page: page, rowsPerPage: rowsPerPage, onPage: (v) => setState(() => page = v), onRows: (v) => setState(() { rowsPerPage = v; page = 0; })),
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


class _Pager extends StatelessWidget {
  final int total, page, rowsPerPage; final ValueChanged<int> onPage; final ValueChanged<int> onRows;
  const _Pager({required this.total,required this.page,required this.rowsPerPage,required this.onPage,required this.onRows});
  @override Widget build(BuildContext context){final pages=(total/rowsPerPage).ceil();final from=page*rowsPerPage+1;final to=((page+1)*rowsPerPage>total)?total:(page+1)*rowsPerPage;return Padding(padding:const EdgeInsets.only(top:14),child:Row(children:[Text('${AppLocalization.t('Rows per page')}: '),DropdownButton<int>(value:rowsPerPage,items:const[10,25,50,100].map((e)=>DropdownMenuItem(value:e,child:Text('$e'))).toList(),onChanged:(v){if(v!=null)onRows(v);}),const Spacer(),Text('${AppLocalization.t('Showing')} $from-$to ${AppLocalization.t('of')} $total'),IconButton(onPressed:page>0?()=>onPage(page-1):null,icon:const Icon(Icons.chevron_left)),Text('${page+1} / ${pages==0?1:pages}'),IconButton(onPressed:page<pages-1?()=>onPage(page+1):null,icon:const Icon(Icons.chevron_right))]));}
}
