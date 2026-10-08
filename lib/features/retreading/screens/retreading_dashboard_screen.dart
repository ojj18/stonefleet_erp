import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../models/retreading_model.dart';
import '../providers/retreading_provider.dart';
import 'retreading_add_edit_screen.dart';
import 'retreading_reports_screen.dart';

class RetreadingDashboardScreen extends StatefulWidget {
  const RetreadingDashboardScreen({super.key});
  @override
  State<RetreadingDashboardScreen> createState() =>
      _RetreadingDashboardScreenState();
}

class _RetreadingDashboardScreenState extends State<RetreadingDashboardScreen> {
  String _status = '';
  String _serial = '';
  final _serialController = TextEditingController();
  int _page = 1;
  int _rows = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await context.read<RetreadingProvider>().load(
      status: _status.isEmpty ? null : _status,
      serial: _serial.isEmpty ? null : _serial,
    );
    if (mounted) setState(() => _page = 1);
  }

  String _date(String v) =>
      v.isEmpty ? '-' : DateFormat('dd/MM/yyyy').format(DateTime.parse(v));
  String _money(double v) => '₹${v.toStringAsFixed(2)}';

  Future<void> _returnRecord(RetreadingRecord r) async {
    final date = DateTime.now();
    final cost = TextEditingController();
    final bill = TextEditingController();
    final remarks = TextEditingController(text: r.remarks ?? '');
    String? guarantee;
    DateTime returnDate = date;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(AppLocalization.t('Record Tyre Return')),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogInfo(
                    AppLocalization.t('Tyre Serial Number'),
                    r.tyreSerialNumber,
                  ),
                  _dialogInfo(
                    AppLocalization.t('Lorry Registration No'),
                    r.registrationNumber,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: returnDate,
                      );
                      if (d != null) setDialog(() => returnDate = d);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Return Date',
                        prefixIcon: Icon(Icons.event_available_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(returnDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Retreading Cost'),
                      prefixIcon: const Icon(Icons.currency_rupee_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bill,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Bill Number'),
                      prefixIcon: const Icon(Icons.receipt_long_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: guarantee,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Guarantee'),
                      prefixIcon: const Icon(Icons.verified_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Guarantee',
                        child: Text(AppLocalization.t('Guarantee')),
                      ),
                      DropdownMenuItem(
                        value: 'No Guarantee',
                        child: Text(AppLocalization.t('No Guarantee')),
                      ),
                    ],
                    onChanged: (v) => setDialog(() => guarantee = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarks,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Remarks'),
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalization.t('Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if ((double.tryParse(cost.text.trim()) ?? -1) < 0) return;
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00652C),
              ),
              child: Text(AppLocalization.t('Save Return')),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    final p = context.read<RetreadingProvider>();
    final ok = await p.markReturned(
      id: r.id!,
      returnDate: DateFormat('yyyy-MM-dd').format(returnDate),
      cost: double.tryParse(cost.text.trim()) ?? 0,
      billNumber: bill.text,
      guarantee: guarantee,
      remarks: remarks.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalization.t(
            ok
                ? 'Tyre return recorded successfully.'
                : (p.error ?? 'Unable to record tyre return.'),
          ),
        ),
      ),
    );
    if (ok) _load();
  }

  Widget _dialogInfo(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF68717D))),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Future<void> _view(RetreadingRecord r) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalization.t('Retreading Details')),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _dialogInfo(
                  AppLocalization.t('Lorry Registration No'),
                  r.registrationNumber,
                ),
                _dialogInfo(
                  AppLocalization.t('Tyre Brand'),
                  r.tyreBrand.isEmpty ? '-' : r.tyreBrand,
                ),
                _dialogInfo(
                  AppLocalization.t('Tyre Serial Number'),
                  r.tyreSerialNumber,
                ),
                _dialogInfo(AppLocalization.t('Tyre Size'), r.tyreSize),
                _dialogInfo(
                  AppLocalization.t('Retreading Company'),
                  r.retreadingCompany,
                ),
                _dialogInfo(AppLocalization.t('Sent Date'), _date(r.sentDate)),
                _dialogInfo(
                  AppLocalization.t('Status'),
                  r.status == 'RETURNED'
                      ? AppLocalization.t('Returned')
                      : AppLocalization.t('At Retreading'),
                ),
                if (r.returnDate != null)
                  _dialogInfo(
                    AppLocalization.t('Return Date'),
                    _date(r.returnDate!),
                  ),
                if (r.status == 'RETURNED')
                  _dialogInfo(
                    AppLocalization.t('Retreading Cost'),
                    _money(r.retreadingCost),
                  ),
                if ((r.billNumber ?? '').isNotEmpty)
                  _dialogInfo(AppLocalization.t('Bill Number'), r.billNumber!),
                if ((r.guarantee ?? '').isNotEmpty)
                  _dialogInfo(AppLocalization.t('Guarantee'), r.guarantee!),
                if ((r.remarks ?? '').isNotEmpty)
                  _dialogInfo(AppLocalization.t('Remarks'), r.remarks!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalization.t('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(RetreadingRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalization.t('Delete Retreading Record?')),
        content: Text(
          AppLocalization.t(
            'This retreading record will be permanently deleted. This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final p = context.read<RetreadingProvider>();
    final done = await p.delete(r.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalization.t(
            done
                ? 'Retreading record deleted successfully.'
                : (p.error ?? 'Unable to delete record.'),
          ),
        ),
      ),
    );
    if (done) _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F9FB),
    body: Row(
      children: [
        AppSidebar(
          selectedIndex: 24,
          onMenuTap: (i) => handleMenuTap(i, context: context),
        ),
        Expanded(
          child: Column(
            children: [
              _top(),
              Expanded(
                child: Consumer<RetreadingProvider>(
                  builder: (_, p, _) {
                    final start = (_page - 1) * _rows;
                    final end = (start + _rows).clamp(0, p.records.length);
                    final items = start >= p.records.length
                        ? <RetreadingRecord>[]
                        : p.records.sublist(start, end);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(),
                              const SizedBox(height: 24),
                              _summary(p),
                              const SizedBox(height: 24),
                              _filters(),
                              const SizedBox(height: 20),
                              _table(items, p.records.length),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _top() => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFBECABC))),
    ),
    child: const Row(
      children: [
        Text(
          'StoneFleet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Spacer(),
        Icon(Icons.notifications_outlined),
      ],
    ),
  );

  Widget _header() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalization.t('Tyre Retreading Management'),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalization.t(
                'Track each tyre by serial number from retreading dispatch to return and cost.',
              ),
              style: const TextStyle(color: Color(0xFF4E5867)),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RetreadingAddEditScreen()),
          );
          if (mounted) _load();
        },
        icon: const Icon(Icons.add),
        label: Text(AppLocalization.t('Send Tyre for Retreading')),
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00652C)),
      ),
      const SizedBox(width: 10),
      OutlinedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RetreadingReportsScreen()),
          );
          if (mounted) _load();
        },
        icon: const Icon(Icons.assessment_outlined),
        label: Text(AppLocalization.t('Reports')),
      ),
    ],
  );

  Widget _summary(RetreadingProvider p) => Row(
    children: [
      _kpi(
        AppLocalization.t('Total Retreading Records'),
        '${p.summary.totalRecords}',
        Icons.tire_repair_outlined,
      ),
      const SizedBox(width: 16),
      _kpi(
        AppLocalization.t('At Retreading'),
        '${p.summary.atRetreading}',
        Icons.local_shipping_outlined,
      ),
      const SizedBox(width: 16),
      _kpi(
        AppLocalization.t('Returned'),
        '${p.summary.returned}',
        Icons.check_circle_outline,
      ),
      const SizedBox(width: 16),
      _kpi(
        AppLocalization.t('Total Retreading Cost'),
        _money(p.summary.totalCost),
        Icons.currency_rupee_outlined,
      ),
    ],
  );
  Widget _kpi(String title, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00652C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF68717D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filters() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBECABC)),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _serialController,
            decoration: InputDecoration(
              labelText: AppLocalization.t('Search Tyre Serial Number'),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (v) {
              _serial = v.trim();
              _load();
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(
              labelText: AppLocalization.t('Status'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(AppLocalization.t('All Status')),
              ),
              DropdownMenuItem(
                value: 'AT_RETREADING',
                child: Text(AppLocalization.t('At Retreading')),
              ),
              DropdownMenuItem(
                value: 'RETURNED',
                child: Text(AppLocalization.t('Returned')),
              ),
            ],
            onChanged: (v) {
              _status = v ?? '';
              _load();
            },
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () {
            _serialController.clear();
            _serial = '';
            _status = '';
            _load();
          },
          icon: const Icon(Icons.clear),
          label: Text(AppLocalization.t('Clear')),
        ),
      ],
    ),
  );

  Widget _table(List<RetreadingRecord> items, int total) {
    final pages = total == 0 ? 1 : (total / _rows).ceil();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBECABC)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F2)),
              columns: [
                DataColumn(label: Text(AppLocalization.t('Sent Date'))),
                DataColumn(
                  label: Text(AppLocalization.t('Lorry Registration No')),
                ),
                DataColumn(
                  label: Text(AppLocalization.t('Tyre Serial Number')),
                ),
                DataColumn(label: Text(AppLocalization.t('Tyre Size'))),
                DataColumn(
                  label: Text(AppLocalization.t('Retreading Company')),
                ),
                DataColumn(label: Text(AppLocalization.t('Return Date'))),
                DataColumn(label: Text(AppLocalization.t('Retreading Cost'))),
                DataColumn(label: Text(AppLocalization.t('Status'))),
                DataColumn(label: Text(AppLocalization.t('Action'))),
              ],
              rows: <DataRow>[
                for (final r in items)
                  DataRow(
                    cells: [
                      DataCell(Text(_date(r.sentDate))),
                      DataCell(Text(r.registrationNumber)),
                      DataCell(Text(r.tyreSerialNumber)),
                      DataCell(Text(r.tyreSize)),
                      DataCell(Text(r.retreadingCompany)),
                      DataCell(
                        Text(r.returnDate == null ? '-' : _date(r.returnDate!)),
                      ),
                      DataCell(
                        Text(
                          r.status == 'RETURNED'
                              ? _money(r.retreadingCost)
                              : '-',
                        ),
                      ),
                      DataCell(_statusChip(r.status)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: AppLocalization.t('View'),
                              onPressed: () => _view(r),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                              ),
                            ),
                            IconButton(
                              tooltip: AppLocalization.t('Edit'),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RetreadingAddEditScreen(record: r),
                                  ),
                                );
                                if (mounted) _load();
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                            ),
                            if (r.status == 'AT_RETREADING')
                              IconButton(
                                tooltip: AppLocalization.t('Record Return'),
                                onPressed: () => _returnRecord(r),
                                icon: const Icon(
                                  Icons.assignment_return_outlined,
                                  size: 18,
                                ),
                              ),
                            IconButton(
                              tooltip: AppLocalization.t('Delete'),
                              onPressed: () => _delete(r),
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${AppLocalization.t('Showing')} ${total == 0 ? 0 : ((_page - 1) * _rows + 1)}-${((_page - 1) * _rows + items.length)} ${AppLocalization.t('of')} $total',
              ),
              const Spacer(),
              DropdownButton<int>(
                value: _rows,
                items: const [10, 25, 50, 100]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) => setState(() {
                  _rows = v ?? 10;
                  _page = 1;
                }),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$_page / $pages'),
              IconButton(
                onPressed: _page < pages ? () => setState(() => _page++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: status == 'RETURNED'
          ? const Color(0xFFE8F5E9)
          : const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status == 'RETURNED'
          ? AppLocalization.t('Returned')
          : AppLocalization.t('At Retreading'),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
