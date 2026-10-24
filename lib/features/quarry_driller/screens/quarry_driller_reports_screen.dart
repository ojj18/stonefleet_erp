import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../quarry_driller_repository.dart';

class QuarryDrillerReportsScreen extends StatefulWidget {
  const QuarryDrillerReportsScreen({super.key});
  @override
  State<QuarryDrillerReportsScreen> createState() =>
      _QuarryDrillerReportsScreenState();
}

class _QuarryDrillerReportsScreenState
    extends State<QuarryDrillerReportsScreen> {
  final _repo = QuarryDrillerRepository();
  DateTime? _from, _to;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _display(String? d) => d == null
      ? ''
      : DateFormat('dd/MM/yyyy').format(DateTime.tryParse(d) ?? DateTime.now());
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _records = await _repo.getRecords(from: _from, to: _to);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick(bool from) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        if (from) {
          _from = d;
        } else {
          _to = d;
        }
      });
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feet = _records.fold<double>(
      0,
      (s, r) => s + ((r['feet'] as num?)?.toDouble() ?? 0),
    );
    final amount = _records.fold<double>(
      0,
      (s, r) => s + ((r['total_amount'] as num?)?.toDouble() ?? 0),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: 27,
            onMenuTap: (i) => handleMenuTap(i, context: context),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'MRA ERP',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Quarry Driller Reports',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text('Dashboard'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _pick(true),
                                        icon: const Icon(Icons.calendar_month),
                                        label: Text(
                                          'From: ${_from == null ? 'Any date' : DateFormat('dd/MM/yyyy').format(_from!)}',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _pick(false),
                                        icon: const Icon(Icons.calendar_month),
                                        label: Text(
                                          'To: ${_to == null ? 'Any date' : DateFormat('dd/MM/yyyy').format(_to!)}',
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          setState(() {
                                            _from = null;
                                            _to = null;
                                          });
                                          await _load();
                                        },
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Clear'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 14,
                                runSpacing: 14,
                                children: [
                                  _stat(
                                    'Records',
                                    '${_records.length}',
                                    Icons.receipt_long,
                                  ),
                                  _stat(
                                    'Total Feet',
                                    feet.toStringAsFixed(2),
                                    Icons.straighten,
                                  ),
                                  _stat(
                                    'Period Total',
                                    '₹${amount.toStringAsFixed(2)}',
                                    Icons.currency_rupee,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Period Summary',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Period: ${_from == null ? 'Beginning' : _display(_iso(_from!))} — ${_to == null ? 'Today' : _display(_iso(_to!))}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Total Feet: ${feet.toStringAsFixed(2)}',
                                      ),
                                      Text(
                                        'Total Amount: ₹${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Date')),
                                        DataColumn(label: Text('Driller Name')),
                                        DataColumn(label: Text('Feet')),
                                        DataColumn(label: Text('Rate / Foot')),
                                        DataColumn(label: Text('Total Amount')),
                                        DataColumn(label: Text('Remarks')),
                                      ],
                                      rows: _records
                                          .map(
                                            (r) => DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    _display(
                                                      '${r['record_date']}',
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text('${r['driller_name']}'),
                                                ),
                                                DataCell(Text('${r['feet']}')),
                                                DataCell(
                                                  Text(
                                                    '₹${((r['rate_per_foot'] as num?) ?? 0).toStringAsFixed(2)}',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '₹${((r['total_amount'] as num?) ?? 0).toStringAsFixed(2)}',
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    '${r['remarks'] ?? '-'}',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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

  Widget _stat(String label, String value, IconData icon) => SizedBox(
    width: 260,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00652C), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
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
}
