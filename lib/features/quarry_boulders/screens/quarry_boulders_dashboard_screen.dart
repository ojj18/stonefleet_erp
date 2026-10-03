import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../service_notification/providers/service_notification_provider.dart';
import '../models/quarry_boulder_trip_model.dart';
import '../providers/quarry_boulder_provider.dart';
import 'quarry_boulders_reports_screen.dart';
import 'quarry_boulders_trip_add_edit_screen.dart';

class QuarryBouldersDashboardScreen extends StatefulWidget {
  const QuarryBouldersDashboardScreen({super.key});
  @override
  State<QuarryBouldersDashboardScreen> createState() =>
      _QuarryBouldersDashboardScreenState();
}

class _QuarryBouldersDashboardScreenState
    extends State<QuarryBouldersDashboardScreen> {
  DateTime? _from;
  DateTime? _to;
  final _search = TextEditingController();
  String _driver = '';
  int _page = 1;
  int _rows = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() => context.read<QuarryBoulderProvider>().loadTrips(
    fromDate: _from,
    toDate: _to,
    registrationNumber: _search.text,
    driverName: _driver,
  );

  Future<void> _pick(bool from) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: (from ? _from : _to) ?? DateTime.now(),
    );
    if (date == null) return;
    setState(() {
      if (from) {
        _from = date;
      } else {
        _to = date;
      }
      _page = 1;
    });
    await _load();
  }

  Future<void> _openAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuarryBouldersTripAddEditScreen(),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openEdit(QuarryBoulderTrip trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuarryBouldersTripAddEditScreen(trip: trip),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _view(QuarryBoulderTrip trip) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalization.t('Quarry Boulders Trip Details')),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detail(AppLocalization.t('Date'), _date(trip.tripDate)),
              _detail(
                AppLocalization.t('Lorry Registration No'),
                trip.registrationNumber,
              ),
              _detail(AppLocalization.t('Driver Name'), trip.driverName),
              _detail(AppLocalization.t('Unit'), _num(trip.unit)),
              _detail(AppLocalization.t('Trip'), '${trip.trips}'),
              _detail(
                AppLocalization.t('Total Load'),
                _num(trip.totalLoad),
                bold: true,
              ),
            ],
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

  Widget _detail(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Future<void> _delete(QuarryBoulderTrip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalization.t('Delete Trip?')),
        content: Text(
          AppLocalization.t(
            'This trip record will be permanently deleted. This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final p = context.read<QuarryBoulderProvider>();
    await p.deleteTrip(trip.id!);
    if (!mounted) return;
    if (p.error != null) {
      _snack(p.error!);
    } else {
      _snack(AppLocalization.t('Trip deleted successfully.'));
      await _load();
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(AppLocalization.t(text))));

  String _date(String value) =>
      DateFormat('dd/MM/yyyy').format(DateTime.parse(value));
  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 18,
            onMenuTap: (i) => handleMenuTap(i, context: context),
          ),
          Expanded(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: Consumer<QuarryBoulderProvider>(
                    builder: (_, p, _) {
                      final start = (_page - 1) * _rows;
                      final end = (start + _rows).clamp(0, p.trips.length);
                      final items = start >= p.trips.length
                          ? <QuarryBoulderTrip>[]
                          : p.trips.sublist(start, end);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1450),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _header(),
                                const SizedBox(height: 24),
                                _summary(p),
                                const SizedBox(height: 24),
                                _filters(),
                                const SizedBox(height: 20),
                                _table(items, p.trips.length),
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
  }

  Widget _topBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFBECABC))),
      ),
      child: Row(
        children: [
          const Text(
            'StoneFleet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Consumer<ServiceNotificationProvider>(
            builder: (_, p, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: AppLocalization.t('Service Notifications'),
                  onPressed: () => handleMenuTap(7, context: context),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                if (p.alertCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD93025),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '•',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalization.t('Quarry Boulders'),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalization.t(
                'Record quarry-to-crusher lorry trips and calculate total load from trip × unit.',
              ),
              style: const TextStyle(color: Color(0xFF4E5867)),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: Text(AppLocalization.t('Add Trip')),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF00652C),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      const SizedBox(width: 10),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const QuarryBouldersReportsScreen(),
          ),
        ),
        icon: const Icon(Icons.assessment_outlined),
        label: Text(AppLocalization.t('Reports')),
      ),
    ],
  );

  Widget _summary(QuarryBoulderProvider p) => Row(
    children: [
      _kpi(
        AppLocalization.t('Total Records'),
        '${p.summary.records}',
        Icons.receipt_long_outlined,
      ),
      const SizedBox(width: 16),
      _kpi(
        AppLocalization.t('Total Trips'),
        '${p.summary.trips}',
        Icons.local_shipping_outlined,
      ),
      const SizedBox(width: 16),
      _kpi(
        AppLocalization.t('Total Load'),
        _num(p.summary.load),
        Icons.scale_outlined,
      ),
      const SizedBox(width: 16),
      _kpi(
        AppLocalization.t('Drivers'),
        '${p.summary.drivers}',
        Icons.person_outline,
      ),
    ],
  );

  Widget _kpi(String title, String value, IconData icon) {
    return Expanded(
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
                      fontSize: 21,
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
  }

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
            controller: _search,
            onChanged: (_) {
              setState(() {
                _page = 1;
              });
              _load();
            },
            decoration: InputDecoration(
              labelText: AppLocalization.t('Lorry Registration No'),
              hintText: AppLocalization.t('Search registration number...'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            onChanged: (v) {
              _driver = v;
              setState(() {
                _page = 1;
              });
              _load();
            },
            decoration: InputDecoration(
              labelText: AppLocalization.t('Driver Name'),
              hintText: AppLocalization.t('Search driver name...'),
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _dateButton(AppLocalization.t('From Date'), _from, () => _pick(true)),
        const SizedBox(width: 12),
        _dateButton(AppLocalization.t('To Date'), _to, () => _pick(false)),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () {
            _from = null;
            _to = null;
            _search.clear();
            _driver = '';
            setState(() {
              _page = 1;
            });
            _load();
          },
          child: Text(AppLocalization.t('Clear')),
        ),
      ],
    ),
  );

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) =>
      SizedBox(
        width: 150,
        height: 56,
        child: OutlinedButton(
          onPressed: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11)),
              Text(
                date == null
                    ? AppLocalization.t('Select Date')
                    : DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _table(List<QuarryBoulderTrip> items, int total) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBECABC)),
    ),
    child: Column(
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(50),
            child: Text(
              AppLocalization.t('No quarry boulder trip records found.'),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1150,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF3F4F6),
                ),
                columns: [
                  DataColumn(label: Text(AppLocalization.t('Date'))),
                  DataColumn(
                    label: Text(AppLocalization.t('Lorry Registration No')),
                  ),
                  DataColumn(label: Text(AppLocalization.t('Driver Name'))),
                  DataColumn(label: Text(AppLocalization.t('Unit'))),
                  DataColumn(label: Text(AppLocalization.t('Trip'))),
                  DataColumn(label: Text(AppLocalization.t('Total Load'))),
                  DataColumn(label: Text(AppLocalization.t('Actions'))),
                ],
                rows: items
                    .map(
                      (t) => DataRow(
                        cells: [
                          DataCell(Text(_date(t.tripDate))),
                          DataCell(
                            Text(
                              t.registrationNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(t.driverName)),
                          DataCell(Text(_num(t.unit))),
                          DataCell(Text('${t.trips}')),
                          DataCell(
                            Text(
                              _num(t.totalLoad),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: AppLocalization.t('View'),
                                  onPressed: () => _view(t),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 18,
                                  ),
                                ),
                                IconButton(
                                  tooltip: AppLocalization.t('Edit'),
                                  onPressed: () => _openEdit(t),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                ),
                                if (context.watch<AuthProvider>().isAdmin)
                                  IconButton(
                                    tooltip: AppLocalization.t('Delete'),
                                    onPressed: () => _delete(t),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Color(0xFFBA1A1A),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        _pagination(total),
      ],
    ),
  );

  Widget _pagination(int total) {
    final pages = total == 0 ? 1 : (total / _rows).ceil();
    if (_page > pages) _page = pages;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(
            '${AppLocalization.t('Showing')} ${total == 0 ? 0 : ((_page - 1) * _rows + 1)}-${(_page * _rows > total ? total : _page * _rows)} ${AppLocalization.t('of')} $total',
          ),
          const Spacer(),
          DropdownButton<int>(
            value: _rows,
            items: [10, 25, 50, 100]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _rows = v;
                _page = 1;
              });
            },
          ),
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
    );
  }
}
