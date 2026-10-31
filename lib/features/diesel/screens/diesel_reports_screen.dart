import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:provider/provider.dart';

import '../../../data/models/diesel_models.dart';
import '../../../data/services/diesel_excel_service.dart';
import '../../../data/services/diesel_pdf_service.dart';
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
  String externalDriver = 'All';
  int page = 0;
  int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final provider = context.read<DieselProvider>();
      await provider.loadVehicles();
      if (!mounted) return;

      await provider.loadExternalDrivers();
      if (!mounted) return;

      await _load();
    });
  }

  List<DieselReportRow> _filteredRows(List<DieselReportRow> rows) {
    if (type != 'External Lorry' || externalDriver == 'All') return rows;
    final expected = externalDriver.toLowerCase().trim();
    return rows.where((row) {
      final registration = row.vehicleRegistration.toString().toLowerCase();
      // External-lorry names are stored in the registration field as
      // "External Lorry - <name>" by the filling form.
      return registration.contains(expected);
    }).toList();
  }

  Future<void> _pickDate(bool from) async {
    final initial = from ? range.start : range.end;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked == null) return;

    DateTime startDate = from ? picked : range.start;
    DateTime endDate = from ? range.end : picked;
    if (startDate.isAfter(endDate)) {
      if (from) {
        endDate = picked;
      } else {
        startDate = picked;
      }
    }

    setState(() {
      period = 'Custom';
      range = DateTimeRange(start: startDate, end: endDate);
      page = 0;
    });
    await _load();
  }

  Future<void> _load() {
    setState(() => page = 0);
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
    } else if (value == 'Yearly') {
      start = DateTime(today.year, 1, 1);
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
    final rows = _filteredRows(p.reportRows);
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('No records available for export.')),
        ),
      );
      return;
    }
    try {
      final path = await DieselExcelService().exportReport(
        rows: rows,
        fromDate: range.start,
        toDate: range.end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('Excel report saved: ') + path),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('Export failed: ') + e.toString()),
        ),
      );
    }
  }

  Future<void> _pdf({required bool print}) async {
    final p = context.read<DieselProvider>();
    final rows = _filteredRows(p.reportRows);
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('No records available for export.')),
        ),
      );
      return;
    }
    final service = DieselPdfService();
    if (print) {
      await service.printReport(
        rows: rows,
        fromDate: range.start,
        toDate: range.end,
      );
    } else {
      await service.shareReport(
        rows: rows,
        fromDate: range.start,
        toDate: range.end,
      );
    }
  }

  Widget _dateFilterButton(String label, DateTime date, VoidCallback onTap) {
    return SizedBox(
      width: 160,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00652C),
          side: const BorderSide(color: Color(0xFFBECABC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: Color(0xFF00652C),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF59665D),
                    ),
                  ),
                  Text(
                    dieselDisplayDate(dieselDate(date)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DieselShell(
      selectedIndex: 23,
      child: Consumer<DieselProvider>(
        builder: (context, p, _) {
          final filteredRows = _filteredRows(p.reportRows);
          final litres = filteredRows.fold<double>(0, (s, r) => s + r.litres);
          final cost = filteredRows.fold<double>(0, (s, r) => s + r.cost);
          final averageRate = litres == 0 ? 0 : cost / litres;
          final start = page * rowsPerPage;
          final end = (start + rowsPerPage).clamp(0, filteredRows.length);
          final safeStart = start.clamp(0, filteredRows.length);
          final visibleRows = filteredRows.sublist(safeStart, end);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DieselPageHeader(
                  title: AppLocalization.t('Diesel Reports'),
                  subtitle: AppLocalization.t(
                    'Generate daily, weekly, monthly and custom diesel reports.',
                  ),
                  action: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: p.isLoading
                            ? null
                            : () => _pdf(print: false),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(AppLocalization.t('Export PDF')),
                      ),
                      OutlinedButton.icon(
                        onPressed: p.isLoading ? null : () => _pdf(print: true),
                        icon: const Icon(Icons.print_outlined),
                        label: Text(AppLocalization.t('Print')),
                      ),
                      FilledButton.icon(
                        onPressed: p.isLoading ? null : _export,
                        icon: const Icon(Icons.file_download_outlined),
                        label: Text(AppLocalization.t('Export Excel')),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF00652C),
                        ),
                      ),
                    ],
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
                        items:
                            const [
                                  'Daily',
                                  'Weekly',
                                  'Monthly',
                                  'Yearly',
                                  'Custom',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(AppLocalization.t(e)),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          if (v == 'Custom') {
                            setState(() {
                              period = 'Custom';
                              page = 0;
                            });
                          } else {
                            await _setPeriod(v);
                          }
                        },
                      ),
                      DropdownButton<String>(
                        value: type,
                        items:
                            const [
                                  'All',
                                  'Excavator',
                                  'Transport',
                                  'External Lorry',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(AppLocalization.t(e)),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() {
                            type = v;
                            vehicleId = null;
                            externalDriver = 'All';
                          });
                          if (v == 'External Lorry') {
                            await context
                                .read<DieselProvider>()
                                .loadExternalDrivers();
                          }
                          await _load();
                        },
                      ),
                      if (type == 'External Lorry')
                        DropdownButton<String>(
                          value: externalDriver,
                          items:
                              <String>{'All', ...p.externalDrivers, 'Company'}
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(
                                        name == 'All'
                                            ? AppLocalization.t(
                                                'All External Drivers',
                                              )
                                            : name,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              externalDriver = value;
                              page = 0;
                            });
                          },
                        ),
                      if (type == 'Excavator' || type == 'Transport')
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
                      _dateFilterButton(
                        AppLocalization.t('From Date'),
                        range.start,
                        () => _pickDate(true),
                      ),
                      _dateFilterButton(
                        AppLocalization.t('To Date'),
                        range.end,
                        () => _pickDate(false),
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
                      if (filteredRows.isEmpty)
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
                            rows: visibleRows
                                .map(
                                  (r) => DataRow(
                                    cells: [
                                      DataCell(Text(dieselDisplayDate(r.date))),
                                      DataCell(Text(r.vehicleRegistration)),
                                      DataCell(
                                        Text(AppLocalization.t(r.vehicleType)),
                                      ),
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
                      if (filteredRows.isNotEmpty)
                        _Pager(
                          total: filteredRows.length,
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
