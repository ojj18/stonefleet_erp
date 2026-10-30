import 'package:flutter/material.dart';
import 'package:stonefleet_erp/core/localization/app_localization.dart';
import 'package:stonefleet_erp/core/widgets/app_sidebar.dart';
import '../../../core/database/database_helper.dart';
import '../../../data/repositories/air_blower_oil_repository.dart';

class AirBlowerOilStockScreen extends StatefulWidget {
  const AirBlowerOilStockScreen({super.key});
  @override
  State<AirBlowerOilStockScreen> createState() =>
      _AirBlowerOilStockScreenState();
}

class _AirBlowerOilStockScreenState extends State<AirBlowerOilStockScreen> {
  final _repo = AirBlowerOilRepository();
  final _cans = TextEditingController(text: '1');
  final _litresPerCan = TextEditingController(text: '5');
  final _litres = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _note = TextEditingController();
  final _useCans = TextEditingController(text: '1');
  final _useLitresPerCan = TextEditingController(text: '5');
  final _useLitres = TextEditingController();
  final _meter = TextEditingController();
  String _useMode = 'litre';
  String _vehicleType = 'transport';
  int? _vehicleId;
  List<Map<String, dynamic>> _vehicles = [];
  String _mode = 'can';
  DateTime _date = DateTime.now();
  DateTime _usageDate = DateTime.now();
  DateTime? _historyFrom;
  DateTime? _historyTo;
  Map<String, dynamic> _stock = {
    'quantity_litres': 0.0,
    'average_cost_per_litre': 0.0,
  };
  List<Map<String, dynamic>> _history = [];
  bool _loading = true, _saving = false;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cans.dispose();
    _litresPerCan.dispose();
    _litres.dispose();
    _cost.dispose();
    _note.dispose();
    _useCans.dispose();
    _useLitresPerCan.dispose();
    _useLitres.dispose();
    _meter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stock = await _repo.getStock();
    final dbh = await DatabaseHelper.instance.database;
    final transports = await dbh.query(
      'transport_vehicles',
      columns: ['id', 'registration_number'],
      where: 'status = 1',
      orderBy: 'registration_number',
    );
    final excavators = await dbh.query(
      'excavators',
      columns: ['id', 'registration_number'],
      where: 'status = 1',
      orderBy: 'registration_number',
    );
    final movementDb = await DatabaseHelper.instance.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (_historyFrom != null) {
      conditions.add('m.movement_date >= ?');
      args.add(_dateString(_historyFrom!));
    }
    if (_historyTo != null) {
      conditions.add('m.movement_date <= ?');
      args.add(_dateString(_historyTo!));
    }
    final whereClause = conditions.isEmpty
        ? ''
        : 'WHERE ${conditions.join(' AND ')}';
    final db = await movementDb.rawQuery(
      """SELECT m.*, CASE WHEN m.service_type = 'transport' THEN (SELECT registration_number FROM transport_vehicles v WHERE v.id = m.vehicle_id) WHEN m.service_type = 'excavator' THEN (SELECT registration_number FROM excavators e WHERE e.id = m.vehicle_id) ELSE NULL END AS vehicle_registration FROM air_blower_oil_movements m $whereClause ORDER BY m.movement_date DESC, m.id DESC""",
      args,
    );
    if (!mounted) return;
    setState(() {
      _stock = stock;
      _history = db;
      final maxPage = (_history.length / _rowsPerPage)
          .ceil()
          .clamp(1, 999999)
          .toInt();
      if (_currentPage > maxPage) _currentPage = maxPage;
      _vehicles = [
        ...transports.map((v) => {...v, 'vehicle_type': 'transport'}),
        ...excavators.map((v) => {...v, 'vehicle_type': 'excavator'}),
      ];
      if (_vehicleId == null && _vehicles.isNotEmpty) {
        _vehicleId = _vehicles.first['id'] as int;
      }
      _loading = false;
    });
  }

  String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  double get _quantity => _mode == 'can'
      ? (double.tryParse(_cans.text) ?? 0) *
            (double.tryParse(_litresPerCan.text) ?? 0)
      : (double.tryParse(_litres.text) ?? 0);
  double get _usageQuantity => _useMode == 'can'
      ? (double.tryParse(_useCans.text) ?? 0) *
            (double.tryParse(_useLitresPerCan.text) ?? 0)
      : (double.tryParse(_useLitres.text) ?? 0);

  Future<void> _viewMovement(Map<String, dynamic> m) async {
    final type = m['movement_type'] == 'purchase'
        ? 'Stock Added'
        : 'AdBlue Used';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalization.t('Movement Details')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocalization.t('Type')}: ${AppLocalization.t(type)}'),
              Text('${AppLocalization.t('Date')}: ${m['movement_date'] ?? ''}'),
              Text(
                '${AppLocalization.t('Vehicle')}: ${m['vehicle_registration'] ?? '-'}',
              ),
              Text(
                '${AppLocalization.t('Quantity')}: ${(m['quantity_litres'] as num).toStringAsFixed(2)} L',
              ),
              Text(
                '${AppLocalization.t('Unit Cost')}: ₹${((m['unit_cost'] as num?) ?? 0).toStringAsFixed(2)}',
              ),
              Text(
                '${AppLocalization.t('Meter Reading')}: ${m['meter_reading'] ?? '-'}',
              ),
              Text('${AppLocalization.t('Remarks')}: ${m['note'] ?? '-'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalization.t('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _editMovement(Map<String, dynamic> m) async {
    final qty = TextEditingController(
      text: (m['quantity_litres'] as num).toString(),
    );
    final cost = TextEditingController(
      text: ((m['unit_cost'] as num?) ?? 0).toString(),
    );
    final note = TextEditingController(text: (m['note'] ?? '').toString());
    DateTime date =
        DateTime.tryParse('${m['movement_date']}') ?? DateTime.now();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalization.t('Edit Movement')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qty,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Quantity (L)'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Unit Cost'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => date = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dateString(date)),
                  ),
                  TextField(
                    controller: note,
                    decoration: InputDecoration(
                      labelText: AppLocalization.t('Remarks'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalization.t('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalization.t('Save')),
            ),
          ],
        ),
      ),
    );
    if (result != true) {
      qty.dispose();
      cost.dispose();
      note.dispose();
      return;
    }
    final newQty = double.tryParse(qty.text) ?? 0;
    final newCost = double.tryParse(cost.text) ?? -1;
    qty.dispose();
    cost.dispose();
    note.dispose();
    if (newQty <= 0 || newCost < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.t('Enter a valid quantity and cost.'),
            ),
          ),
        );
      }
      return;
    }
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        final movements = await txn.query(
          'air_blower_oil_movements',
          orderBy: 'id ASC',
        );
        double balance = 0, purchaseValue = 0, purchaseQty = 0;
        for (final row in movements) {
          final id = row['id'];
          final isTarget = id == m['id'];
          final movementType = row['movement_type'];
          final q = isTarget
              ? newQty
              : (row['quantity_litres'] as num).toDouble();
          final c = isTarget
              ? newCost
              : ((row['unit_cost'] as num?) ?? 0).toDouble();
          if (movementType == 'purchase') {
            balance += q;
            purchaseQty += q;
            purchaseValue += q * c;
          } else {
            balance -= q;
          }
        }
        if (balance < -0.000001) {
          throw StateError('This change would make AdBlue stock negative.');
        }
        await txn.update(
          'air_blower_oil_movements',
          {
            'quantity_litres': newQty,
            'unit_cost': newCost,
            'movement_date': _dateString(date),
            'note': note.text.trim(),
          },
          where: 'id = ?',
          whereArgs: [m['id']],
        );
        await txn.update('air_blower_oil_stock', {
          'quantity_litres': balance < 0 ? 0 : balance,
          'average_cost_per_litre': purchaseQty == 0
              ? 0
              : purchaseValue / purchaseQty,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = 1');
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteMovement(Map<String, dynamic> m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalization.t('Delete Movement?')),
        content: Text(
          AppLocalization.t(
            'This will update the AdBlue stock balance. Continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalization.t('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalization.t('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        final movements = await txn.query(
          'air_blower_oil_movements',
          orderBy: 'id ASC',
        );
        double balance = 0, purchaseValue = 0, purchaseQty = 0;
        for (final row in movements) {
          if (row['id'] == m['id']) continue;
          final q = (row['quantity_litres'] as num).toDouble();
          final c = ((row['unit_cost'] as num?) ?? 0).toDouble();
          if (row['movement_type'] == 'purchase') {
            balance += q;
            purchaseQty += q;
            purchaseValue += q * c;
          } else {
            balance -= q;
          }
        }
        if (balance < -0.000001) {
          throw StateError(
            'Cannot delete this movement because it would make stock negative.',
          );
        }
        await txn.delete(
          'air_blower_oil_movements',
          where: 'id = ?',
          whereArgs: [m['id']],
        );
        await txn.update('air_blower_oil_stock', {
          'quantity_litres': balance < 0 ? 0 : balance,
          'average_cost_per_litre': purchaseQty == 0
              ? 0
              : purchaseValue / purchaseQty,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = 1');
      });
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }

  Future<void> _saveUsage() async {
    if (_vehicleId == null ||
        _usageQuantity <= 0 ||
        (double.tryParse(_meter.text) ?? -1) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalization.t(
              'Enter a valid vehicle, oil quantity and meter reading.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        final row = (await txn.query(
          'air_blower_oil_stock',
          where: 'id = 1',
          limit: 1,
        )).first;
        final available = (row['quantity_litres'] as num).toDouble();
        if (available + 0.000001 < _usageQuantity) {
          throw StateError(
            'Insufficient AdBlue Oil stock. Available: ${available.toStringAsFixed(2)} L.',
          );
        }
        final vehicle = _vehicles.firstWhere((v) => v['id'] == _vehicleId);
        final type = vehicle['vehicle_type'] as String;
        final rate = (row['average_cost_per_litre'] as num).toDouble();
        final date = _dateString(_usageDate);
        await txn.update('air_blower_oil_stock', {
          'quantity_litres': available - _usageQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        }, where: 'id = 1');
        await txn.insert('air_blower_oil_movements', {
          'movement_type': 'usage',
          'quantity_litres': _usageQuantity,
          'unit_cost': rate,
          'service_type': type,
          'service_id': null,
          'vehicle_id': _vehicleId,
          'meter_reading': double.parse(_meter.text),
          'movement_date': date,
          'note':
              'Stock screen usage • ${_useMode == 'can' ? 'Can-wise' : 'Litre-wise'}',
        });
      });
      _meter.clear();
      _useLitres.clear();
      _useCans.text = '1';
      _useLitresPerCan.text = '5';
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.t('AdBlue Oil usage saved and stock reduced.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_quantity <= 0 || (double.tryParse(_cost.text) ?? -1) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.t('Enter a valid quantity and cost.')),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.addStock(
        litres: _quantity,
        costPerLitre: double.parse(_cost.text),
        canWise: _mode == 'can',
        date:
            '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
        note: _note.text,
      );
      _cans.text = '1';
      _litresPerCan.text = '5';
      _litres.clear();
      _note.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.t('AdBlue Oil stock added successfully.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Row(
        children: [
          SizedBox(
            width: 240,
            child: AppSidebar(
              selectedIndex: 26,
              onMenuTap: (index) => handleMenuTap(index, context: context),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalization.t('AdBlue Oil Stock'),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.opacity,
                                      color: Color(0xFF00652C),
                                      size: 36,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        AppLocalization.t(
                                          'Available AdBlue Stock',
                                        ),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    Text(
                                      '${((_stock['quantity_litres'] as num?) ?? 0).toStringAsFixed(2)} L',
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00652C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalization.t('Add AdBlue Oil Stock'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SegmentedButton<String>(
                                      segments: [
                                        ButtonSegment(
                                          value: 'can',
                                          label: Text(
                                            AppLocalization.t('Can-wise'),
                                          ),
                                        ),
                                        ButtonSegment(
                                          value: 'litre',
                                          label: Text(
                                            AppLocalization.t('Litre-wise'),
                                          ),
                                        ),
                                      ],
                                      selected: {_mode},
                                      onSelectionChanged: (v) =>
                                          setState(() => _mode = v.first),
                                    ),
                                    const SizedBox(height: 14),
                                    if (_mode == 'can')
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _field(
                                              AppLocalization.t(
                                                'Number of Cans',
                                              ),
                                              _cans,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _field(
                                              AppLocalization.t(
                                                'Litres per Can',
                                              ),
                                              _litresPerCan,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      _field(
                                        AppLocalization.t('Quantity in Litres'),
                                        _litres,
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _field(
                                            AppLocalization.t('Cost per Litre'),
                                            _cost,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: _date,
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null) {
                                                setState(() => _date = picked);
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.calendar_today,
                                            ),
                                            label: Text(
                                              '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _field(
                                      AppLocalization.t('Remarks (Optional)'),
                                      _note,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      '${AppLocalization.t('Quantity to add')}: ${_quantity.toStringAsFixed(2)} L  •  ${AppLocalization.t('Total Cost')}: ₹${(_quantity * (double.tryParse(_cost.text) ?? 0)).toStringAsFixed(2)}',
                                    ),
                                    const SizedBox(height: 14),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: _saving ? null : _save,
                                        icon: const Icon(Icons.save),
                                        label: Text(
                                          AppLocalization.t('Add Stock'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalization.t('AdBlue Oil Usage'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<String>(
                                      initialValue: _vehicleType,
                                      decoration: InputDecoration(
                                        labelText: AppLocalization.t(
                                          'Vehicle Type',
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'transport',
                                          child: Text(
                                            AppLocalization.t('Transport'),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'excavator',
                                          child: Text(
                                            AppLocalization.t('Excavator'),
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() {
                                            _vehicleType = v;
                                            final filtered = _vehicles
                                                .where(
                                                  (x) => x['vehicle_type'] == v,
                                                )
                                                .toList();
                                            _vehicleId = filtered.isEmpty
                                                ? null
                                                : filtered.first['id'] as int;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue:
                                          _vehicles.any(
                                            (v) =>
                                                v['id'] == _vehicleId &&
                                                v['vehicle_type'] ==
                                                    _vehicleType,
                                          )
                                          ? _vehicleId
                                          : null,
                                      decoration: InputDecoration(
                                        labelText: AppLocalization.t(
                                          'Registration Number',
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: _vehicles
                                          .where(
                                            (v) =>
                                                v['vehicle_type'] ==
                                                _vehicleType,
                                          )
                                          .map(
                                            (v) => DropdownMenuItem<int>(
                                              value: v['id'] as int,
                                              child: Text(
                                                v['registration_number']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _vehicleId = v),
                                    ),
                                    const SizedBox(height: 12),
                                    _field(
                                      AppLocalization.t(
                                        _vehicleType == 'excavator'
                                            ? 'Hour Meter Reading'
                                            : 'Current KM Reading',
                                      ),
                                      _meter,
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _saving
                                          ? null
                                          : () async {
                                              final picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate: _usageDate,
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null) {
                                                setState(
                                                  () => _usageDate = picked,
                                                );
                                              }
                                            },
                                      icon: const Icon(Icons.calendar_month),
                                      label: Text(
                                        'Usage Date: ${_usageDate.day.toString().padLeft(2, '0')}/${_usageDate.month.toString().padLeft(2, '0')}/${_usageDate.year}',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SegmentedButton<String>(
                                      segments: [
                                        ButtonSegment(
                                          value: 'can',
                                          label: Text(
                                            AppLocalization.t('Can-wise'),
                                          ),
                                        ),
                                        ButtonSegment(
                                          value: 'litre',
                                          label: Text(
                                            AppLocalization.t('Litre-wise'),
                                          ),
                                        ),
                                      ],
                                      selected: {_useMode},
                                      onSelectionChanged: (v) =>
                                          setState(() => _useMode = v.first),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_useMode == 'can')
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _field(
                                              AppLocalization.t(
                                                'Number of Cans',
                                              ),
                                              _useCans,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _field(
                                              AppLocalization.t(
                                                'Litres per Can',
                                              ),
                                              _useLitresPerCan,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      _field(
                                        AppLocalization.t('Litres Used'),
                                        _useLitres,
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${AppLocalization.t('AdBlue to deduct')}: ${_usageQuantity.toStringAsFixed(2)} L • ${AppLocalization.t('Available')}: ${((_stock['quantity_litres'] as num?) ?? 0).toStringAsFixed(2)} L',
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed: _saving ? null : _saveUsage,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        label: Text(
                                          AppLocalization.t('Record Oil Usage'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppLocalization.t('Recent AdBlue Oil Movements'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _historyFrom ??
                                              _historyTo ??
                                              DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() => _historyFrom = picked);
                                          await _load();
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_today),
                                      label: Text(
                                        'From: ${_historyFrom == null ? 'Any date' : '${_historyFrom!.day.toString().padLeft(2, '0')}/${_historyFrom!.month.toString().padLeft(2, '0')}/${_historyFrom!.year}'}',
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _historyTo ??
                                              _historyFrom ??
                                              DateTime.now(),
                                          firstDate:
                                              _historyFrom ?? DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() => _historyTo = picked);
                                          await _load();
                                        }
                                      },
                                      icon: const Icon(Icons.event),
                                      label: Text(
                                        'To: ${_historyTo == null ? 'Any date' : '${_historyTo!.day.toString().padLeft(2, '0')}/${_historyTo!.month.toString().padLeft(2, '0')}/${_historyTo!.year}'}',
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          _historyFrom == null &&
                                              _historyTo == null
                                          ? null
                                          : () async {
                                              setState(() {
                                                _historyFrom = null;
                                                _historyTo = null;
                                              });
                                              await _load();
                                            },
                                      icon: const Icon(Icons.clear),
                                      label: const Text('Clear dates'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Card(
                              color: Colors.white,
                              child: Column(
                                children: [
                                  if (_history.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        AppLocalization.t(
                                          'No stock movements yet.',
                                        ),
                                      ),
                                    )
                                  else ...[
                                    ..._history
                                        .skip((_currentPage - 1) * _rowsPerPage)
                                        .take(_rowsPerPage)
                                        .map(
                                          (m) => ListTile(
                                            leading: Icon(
                                              m['movement_type'] == 'purchase'
                                                  ? Icons.add_circle_outline
                                                  : Icons.remove_circle_outline,
                                            ),
                                            title: Text(
                                              '${m['movement_type'] == 'purchase' ? AppLocalization.t('Stock Added') : AppLocalization.t('AdBlue Used')} • ${(m['quantity_litres'] as num).toStringAsFixed(2)} L',
                                            ),
                                            subtitle: Text(
                                              '${m['movement_date'] ?? ''}  ${m['vehicle_registration'] ?? ''}  ${m['meter_reading'] == null ? '' : (m['service_type'] == 'excavator' ? 'HM ' : 'KM ') + m['meter_reading'].toString()}  ${m['note'] ?? ''}',
                                            ),
                                            trailing: SizedBox(
                                              width: 150,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    tooltip: AppLocalization.t(
                                                      'View',
                                                    ),
                                                    onPressed: () =>
                                                        _viewMovement(m),
                                                    icon: const Icon(
                                                      Icons.visibility_outlined,
                                                      size: 19,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: AppLocalization.t(
                                                      'Edit',
                                                    ),
                                                    onPressed: () =>
                                                        _editMovement(m),
                                                    icon: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 19,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: AppLocalization.t(
                                                      'Delete',
                                                    ),
                                                    onPressed: () =>
                                                        _deleteMovement(m),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                      size: 19,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            '${AppLocalization.t('Showing')} ${_history.isEmpty ? 0 : (_currentPage - 1) * _rowsPerPage + 1}-${((_currentPage - 1) * _rowsPerPage + _rowsPerPage).clamp(0, _history.length)} ${AppLocalization.t('of')} ${_history.length}',
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(AppLocalization.t('Rows')),
                                              const SizedBox(width: 8),
                                              DropdownButton<int>(
                                                value: _rowsPerPage,
                                                items: const [10, 20, 50]
                                                    .map(
                                                      (n) => DropdownMenuItem(
                                                        value: n,
                                                        child: Text('$n'),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (v) {
                                                  if (v != null) {
                                                    setState(() {
                                                      _rowsPerPage = v;
                                                      _currentPage = 1;
                                                    });
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                tooltip: AppLocalization.t(
                                                  'Previous',
                                                ),
                                                onPressed: _currentPage > 1
                                                    ? () => setState(
                                                        () => _currentPage--,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_left,
                                                ),
                                              ),
                                              Text(
                                                '$_currentPage / ${(_history.length / _rowsPerPage).ceil().clamp(1, 999999)}',
                                              ),
                                              IconButton(
                                                tooltip: AppLocalization.t(
                                                  'Next',
                                                ),
                                                onPressed:
                                                    _currentPage <
                                                        (_history.length /
                                                                _rowsPerPage)
                                                            .ceil()
                                                    ? () => setState(
                                                        () => _currentPage++,
                                                      )
                                                    : null,
                                                icon: const Icon(
                                                  Icons.chevron_right,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
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
    );
  }

  Widget _field(String label, TextEditingController c) => TextField(
    controller: c,
    keyboardType: label.toLowerCase().contains('remark')
        ? TextInputType.text
        : const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) {
      if (mounted) setState(() {});
    },
  );
}
