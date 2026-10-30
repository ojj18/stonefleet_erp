import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_sidebar.dart';

import '../quarry_driller_repository.dart';
import 'quarry_driller_reports_screen.dart';

class QuarryDrillerDashboardScreen extends StatefulWidget {
  const QuarryDrillerDashboardScreen({super.key});
  @override
  State<QuarryDrillerDashboardScreen> createState() =>
      _QuarryDrillerDashboardScreenState();
}

class _QuarryDrillerDashboardScreenState
    extends State<QuarryDrillerDashboardScreen> {
  final _repo = QuarryDrillerRepository();
  final _feet = TextEditingController();
  final _rate = TextEditingController();
  final _remarks = TextEditingController();
  DateTime _date = DateTime.now();
  String? _driller;
  List<String> _drillers = [];
  List<Map<String, dynamic>> _records = [];
  int? _editingId;
  bool _loading = true;

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  String _display(String? d) => d == null
      ? ''
      : DateFormat('dd/MM/yyyy').format(DateTime.tryParse(d) ?? DateTime.now());
  double get _total =>
      (double.tryParse(_feet.text) ?? 0) * (double.tryParse(_rate.text) ?? 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _feet.dispose();
    _rate.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _drillers = await _repo.getDrillers();
      if (_driller == null && _drillers.isNotEmpty) _driller = _drillers.first;
      _records = await _repo.getRecords();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final feet = double.tryParse(_feet.text.trim()) ?? 0;
    final rate = double.tryParse(_rate.text.trim()) ?? -1;
    final name = (_driller ?? '').trim();
    if (name.isEmpty || feet <= 0 || rate < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select driller and enter valid feet and rate.'),
        ),
      );
      return;
    }
    await _repo.ensureDriller(name);
    await _repo.save({
      'record_date': _iso(_date),
      'driller_name': name,
      'feet': feet,
      'rate_per_foot': rate,
      'total_amount': feet * rate,
      'remarks': _remarks.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    }, id: _editingId);
    _clear();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quarry driller record saved.')),
      );
    }
  }

  void _clear() {
    setState(() {
      _editingId = null;
      _date = DateTime.now();
      _feet.clear();
      _rate.clear();
      _remarks.clear();
    });
  }

  void _edit(Map<String, dynamic> r) {
    setState(() {
      _editingId = r['id'] as int;
      _date = DateTime.tryParse('${r['record_date']}') ?? DateTime.now();
      _driller = '${r['driller_name']}';
      if (!_drillers.contains(_driller)) _drillers.add(_driller!);
      _feet.text = '${r['feet']}';
      _rate.text = '${r['rate_per_foot']}';
      _remarks.text = '${r['remarks'] ?? ''}';
    });
  }

  Future<void> _addDriller() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Driller Name'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Driller name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Use Name'),
          ),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.isEmpty) return;
    await _repo.ensureDriller(name);
    await _load();
    setState(
      () => _driller = _drillers.firstWhere(
        (n) => n.toLowerCase() == name.toLowerCase(),
        orElse: () => name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFeet = _records.fold<double>(
      0,
      (s, r) => s + ((r['feet'] as num?)?.toDouble() ?? 0),
    );
    final totalAmount = _records.fold<double>(
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
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  alignment: Alignment.centerLeft,
                  color: Colors.white,
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
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1450),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Quarry Driller',
                                              style: TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              'Track drilling feet, rate per foot and total amount.',
                                            ),
                                          ],
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const QuarryDrillerReportsScreen(),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.assessment_outlined,
                                        ),
                                        label: const Text('Reports'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: [
                                      _stat(
                                        'Total Records',
                                        '${_records.length}',
                                        Icons.receipt_long,
                                      ),
                                      _stat(
                                        'Total Feet',
                                        totalFeet.toStringAsFixed(2),
                                        Icons.straighten,
                                      ),
                                      _stat(
                                        'Total Amount',
                                        '₹${totalAmount.toStringAsFixed(2)}',
                                        Icons.currency_rupee,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  Card(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _editingId == null
                                                ? 'Add Quarry Driller Entry'
                                                : 'Edit Quarry Driller Entry',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 16,
                                            children: [
                                              SizedBox(
                                                width: 260,
                                                child: OutlinedButton.icon(
                                                  onPressed: _pickDate,
                                                  icon: const Icon(
                                                    Icons.calendar_month,
                                                  ),
                                                  label: Text(
                                                    'Date: ${DateFormat('dd/MM/yyyy').format(_date)}',
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 320,
                                                child:
                                                    DropdownButtonFormField<
                                                      String
                                                    >(
                                                      initialValue:
                                                          _drillers.contains(
                                                            _driller,
                                                          )
                                                          ? _driller
                                                          : null,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                'Driller Name',
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                      items: [
                                                        ..._drillers.map(
                                                          (n) =>
                                                              DropdownMenuItem(
                                                                value: n,
                                                                child: Text(n),
                                                              ),
                                                        ),
                                                        const DropdownMenuItem(
                                                          value: '__add__',
                                                          child: Text(
                                                            '+ Add Driller Name',
                                                          ),
                                                        ),
                                                      ],
                                                      onChanged: (v) {
                                                        if (v == '__add__') {
                                                          _addDriller();
                                                        } else {
                                                          setState(
                                                            () => _driller = v,
                                                          );
                                                        }
                                                      },
                                                    ),
                                              ),
                                              SizedBox(
                                                width: 220,
                                                child: TextField(
                                                  controller: _feet,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  onChanged: (_) =>
                                                      setState(() {}),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Feet',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 220,
                                                child: TextField(
                                                  controller: _rate,
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  onChanged: (_) =>
                                                      setState(() {}),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Rate per Foot (₹)',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 300,
                                                child: TextField(
                                                  controller: _remarks,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Remarks (Optional)',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE5F4E9),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Expanded(
                                                  child: Text(
                                                    'Total Amount',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '₹${_total.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF00652C),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (_editingId != null)
                                                TextButton(
                                                  onPressed: _clear,
                                                  child: const Text(
                                                    'Cancel Edit',
                                                  ),
                                                ),
                                              FilledButton.icon(
                                                onPressed: _save,
                                                icon: const Icon(Icons.save),
                                                label: Text(
                                                  _editingId == null
                                                      ? 'Save Record'
                                                      : 'Update Record',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Card(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Recent Quarry Driller Records',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columns: const [
                                                DataColumn(label: Text('Date')),
                                                DataColumn(
                                                  label: Text('Driller'),
                                                ),
                                                DataColumn(label: Text('Feet')),
                                                DataColumn(
                                                  label: Text('Rate / Foot'),
                                                ),
                                                DataColumn(
                                                  label: Text('Total Amount'),
                                                ),
                                                DataColumn(
                                                  label: Text('Actions'),
                                                ),
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
                                                          Text(
                                                            '${r['driller_name']}',
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text('${r['feet']}'),
                                                        ),
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
                                                          Row(
                                                            children: [
                                                              IconButton(
                                                                tooltip: 'Edit',
                                                                onPressed: () =>
                                                                    _edit(r),
                                                                icon: const Icon(
                                                                  Icons
                                                                      .edit_outlined,
                                                                  size: 19,
                                                                ),
                                                              ),
                                                              IconButton(
                                                                tooltip:
                                                                    'Delete',
                                                                onPressed: () async {
                                                                  final ok = await showDialog<bool>(
                                                                    context:
                                                                        context,
                                                                    builder: (ctx) => AlertDialog(
                                                                      title: const Text(
                                                                        'Delete record?',
                                                                      ),
                                                                      content:
                                                                          const Text(
                                                                            'This record will be permanently deleted.',
                                                                          ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                            ctx,
                                                                            false,
                                                                          ),
                                                                          child: const Text(
                                                                            'Cancel',
                                                                          ),
                                                                        ),
                                                                        FilledButton(
                                                                          onPressed: () => Navigator.pop(
                                                                            ctx,
                                                                            true,
                                                                          ),
                                                                          child: const Text(
                                                                            'Delete',
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                  if (ok ==
                                                                      true) {
                                                                    await _repo
                                                                        .delete(
                                                                          r['id']
                                                                              as int,
                                                                        );
                                                                    await _load();
                                                                  }
                                                                },
                                                                icon: const Icon(
                                                                  Icons
                                                                      .delete_outline,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 19,
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
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    width: 280,
    child: Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00652C), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
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
